// lib/pages/chat/chat_page.dart
//
// Chat page (content-only):
// - text input to simulate "AI parse"
// - always show confirm sheet before saving
// - save to RecordsProvider + update balances like RecordHub
//
// Later we plug in Gemini + speech + receipt OCR.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../core/utils/id_utils.dart';
import '../../core/utils/money_utils.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/draft_record.dart';
import '../../models/record.dart';
import '../../data/ai/gemini_service.dart';
import '../../state/categories_provider.dart';
import '../../state/accounts_provider.dart';
import '../../state/app_session_provider.dart';
import '../../state/records_provider.dart';
import '../../state/ai_settings_provider.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/confirm_sheet.dart';
import 'widgets/voice_sheet.dart';
import 'widgets/receipt_sheet.dart';
import 'widgets/candidate_sheet.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();

  final List<ChatMessage> _messages = [];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  GeminiService _geminiFromSettings(BuildContext context) {
    final ai = context.read<AiSettingsProvider>();
    return GeminiService(modelName: ai.modelName, strictMode: ai.strictMode);
  }

  void _addMsg(bool isUser, String text) {
    setState(() {
      _messages.add(
        ChatMessage(
          id: IdUtils.newId(),
          isUser: isUser,
          text: text,
          time: DateTime.now(),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _addAssistantPlaceholder(String text) {
    final id = IdUtils.newId();
    setState(() {
      _messages.add(
        ChatMessage(id: id, isUser: false, text: text, time: DateTime.now()),
      );
    });
    return id;
  }

  void _updateMessage(String id, String newText) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx < 0) return;
    setState(() {
      _messages[idx] = ChatMessage(
        id: _messages[idx].id,
        isUser: _messages[idx].isUser,
        text: newText,
        time: _messages[idx].time,
      );
    });
  }

  Future<void> _receiptFlow() async {
    final source = await ReceiptSheet.show(context);
    if (!mounted) return;

    if (source == null) {
      _addMsg(false, 'Receipt cancelled.');
      return;
    }

    _addMsg(true, '[receipt] selecting image...');

    final picked = await _picker.pickImage(
      source: source == ReceiptSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted) return;

    if (picked == null) {
      _addMsg(false, 'No image selected.');
      return;
    }

    final statusId = _addAssistantPlaceholder('Analyzing receipt with AI...');

    final Uint8List bytes = await picked.readAsBytes();
    if (!mounted) return;

    final mimeType = _guessImageMimeType(picked.name);

    final accP = context.read<AccountsProvider>();
    final catP = context.read<CategoriesProvider>();

    final gemini = _geminiFromSettings(context);

    final candidates = await gemini.parseReceiptImageToDraftCandidates(
      imageBytes: bytes,
      mimeType: mimeType,
      accounts: accP.accounts,
      spendingCategories: catP.spending,
      incomeCategories: catP.income,
      maxCandidates: 3,
    );
    if (!mounted) return;

    DraftRecord draft;

    if (candidates.isEmpty) {
      _updateMessage(
        statusId,
        'AI unavailable/unclear. Using fallback draft. Please confirm.',
      );
      draft = DraftRecord(
        type: RecordType.spending,
        amountCents: MoneyUtils.toCents(12.50),
        date: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ),
        title: 'Receipt purchase (fallback)',
        includeInStats: true,
        includeInBudget: true,
      );
    } else if (candidates.length == 1) {
      _updateMessage(statusId, 'AI extracted a draft. Please confirm.');
      draft = candidates.first;
    } else {
      _updateMessage(statusId, 'AI found multiple options. Pick one.');

      final pickedCandidate = await CandidateSheet.show(
        context,
        candidates: candidates,
      );
      if (!mounted) return;

      if (pickedCandidate == null) {
        _updateMessage(statusId, 'Cancelled. No record saved.');
        return;
      }
      draft = pickedCandidate;
    }

    final confirmed = await ConfirmSheet.show(context, draft);
    if (!mounted) return;

    if (confirmed == null) {
      _updateMessage(statusId, 'Cancelled. No record saved.');
      return;
    }

    await _saveDraft(confirmed);
    if (!mounted) return;

    _updateMessage(statusId, 'Saved ✅');
  }

  String _guessImageMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    // default for jpg/jpeg/unknown
    return 'image/jpeg';
  }

  // Simple non-AI parser:
  // Examples:
  // "spend 12.5" -> spending 12.50 today
  // "income 300 salary" -> income 300, title=salary
  // "transfer 50 fee 1.2" -> transfer 50 with fee 1.2
  DraftRecord _parseToDraft(String text) {
    final t = text.trim();
    final lower = t.toLowerCase();

    RecordType type = RecordType.spending;
    if (lower.startsWith('income')) type = RecordType.income;
    if (lower.startsWith('transfer')) type = RecordType.transfer;
    if (lower.startsWith('spend')) type = RecordType.spending;

    // find first number as amount
    final numMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(t);
    final amount = numMatch == null
        ? 0
        : double.tryParse(numMatch.group(1)!) ?? 0;
    final amountCents = MoneyUtils.toCents(amount);

    int feeCents = 0;
    if (type == RecordType.transfer) {
      final feeMatch = RegExp(
        r'fee\s*(\d+(\.\d+)?)',
        caseSensitive: false,
      ).firstMatch(t);
      if (feeMatch != null) {
        final fee = double.tryParse(feeMatch.group(1)!) ?? 0;
        feeCents = MoneyUtils.toCents(fee);
      }
    }

    // title = remaining text after amount keywords (very simple)
    String? title;
    final parts = t.split(' ');
    if (parts.length >= 3) {
      title = parts.skip(2).join(' ').trim();
      if (title.isEmpty) title = null;
    }

    return DraftRecord(
      type: type,
      amountCents: amountCents,
      serviceChargeCents: feeCents,
      date: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ),
      title: title,
      includeInStats: true,
      includeInBudget: true,
    );
  }

  Future<void> _saveDraft(DraftRecord d) async {
    final accP = context.read<AccountsProvider>();
    final recP = context.read<RecordsProvider>();
    final session = context.read<AppSessionProvider>();

    final now = DateTime.now();

    final record = Record(
      id: IdUtils.newId(),
      type: d.type,
      amountCents: d.amountCents,
      date: d.date,
      title: d.title,
      tag: d.tag,
      includeInStats: d.includeInStats,
      includeInBudget: d.includeInBudget,
      categoryId: d.categoryId,
      accountId: d.accountId,
      fromAccountId: d.fromAccountId,
      toAccountId: d.toAccountId,
      serviceChargeCents: d.serviceChargeCents,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );

    // Unified balance handling (same rule as RecordHub)
    await accP.applyRecordEffect(record, sign: 1);

    // Save record
    await recP.upsertRecord(record);

    // After saving, switch Home month and reload (no extra context reads)
    final month = DateTime(record.date.year, record.date.month);
    session.setHomeMonth(month);
    await recP.loadMonth(month);
  }

  Future<void> _sendText() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    _input.clear();
    _addMsg(true, text);

    // capture providers before any await
    final accP = context.read<AccountsProvider>();
    final catP = context.read<CategoriesProvider>();

    final statusId = _addAssistantPlaceholder('AI is thinking…');

    final gemini = _geminiFromSettings(context);

    final candidates = await gemini.parseTextToDraftCandidates(
      userText: text,
      accounts: accP.accounts,
      spendingCategories: catP.spending,
      incomeCategories: catP.income,
      maxCandidates: 3,
    );
    if (!mounted) return;

    DraftRecord draft;

    if (candidates.isEmpty) {
      _updateMessage(
        statusId,
        'AI unavailable/unclear (or timed out). Using offline parser.',
      );
      draft = _parseToDraft(text);
    } else if (candidates.length == 1) {
      _updateMessage(statusId, 'AI parsed a draft. Please confirm.');
      draft = candidates.first;
    } else {
      _updateMessage(statusId, 'AI found multiple options. Pick one.');

      final picked = await CandidateSheet.show(context, candidates: candidates);
      if (!mounted) return;

      if (picked == null) {
        _updateMessage(statusId, 'Cancelled. No record saved.');
        return;
      }
      draft = picked;
    }

    final confirmed = await ConfirmSheet.show(context, draft);
    if (!mounted) return;

    if (confirmed == null) {
      _updateMessage(statusId, 'Cancelled. No record saved.');
      return;
    }

    if (confirmed.amountCents <= 0) {
      _updateMessage(statusId, 'Invalid amount. No record saved.');
      return;
    }

    await _saveDraft(confirmed);
    if (!mounted) return;

    _updateMessage(statusId, 'Saved ✅');
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionProvider>();

    if (session.requestChatVoiceMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;

        // capture provider BEFORE awaits (no context.read after awaits)
        final appSession = context.read<AppSessionProvider>();

        // consume immediately so it triggers once even if rebuild happens
        appSession.consumeChatVoiceMode();

        // open voice sheet
        final transcript = await VoiceSheet.show(context);
        if (!context.mounted) return;

        if (transcript == null || transcript.trim().isEmpty) {
          _addMsg(false, 'Voice cancelled.');
          return;
        }

        _addMsg(true, '[voice] $transcript');

        // capture providers BEFORE awaits
        final accP = context.read<AccountsProvider>();
        final catP = context.read<CategoriesProvider>();

        final statusId = _addAssistantPlaceholder('Parsing voice with AI...');

        final gemini = _geminiFromSettings(context);

        final candidates = await gemini.parseTextToDraftCandidates(
          userText: transcript,
          accounts: accP.accounts,
          spendingCategories: catP.spending,
          incomeCategories: catP.income,
          maxCandidates: 3,
        );
        if (!context.mounted) return;

        DraftRecord draft;

        if (candidates.isEmpty) {
          _updateMessage(
            statusId,
            'AI unavailable/unclear (or timed out). Using offline parser.',
          );
          draft = _parseToDraft(transcript);
        } else if (candidates.length == 1) {
          _updateMessage(statusId, 'AI parsed a draft. Please confirm.');
          draft = candidates.first;
        } else {
          _updateMessage(statusId, 'AI found multiple options. Pick one.');

          final picked = await CandidateSheet.show(
            context,
            candidates: candidates,
          );
          if (!context.mounted) return;

          if (picked == null) {
            _updateMessage(statusId, 'Cancelled. No record saved.');
            return;
          }
          draft = picked;
        }

        final confirmed = await ConfirmSheet.show(context, draft);
        if (!context.mounted) return;

        if (confirmed == null) {
          _updateMessage(statusId, 'Cancelled. No record saved.');
          return;
        }

        await _saveDraft(confirmed);
        if (!context.mounted) return;

        _updateMessage(statusId, 'Saved ✅');
      });
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              return ChatBubble(isUser: m.isUser, text: m.text);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _receiptFlow,
                  icon: const Icon(Icons.image_outlined),
                  tooltip: 'Upload receipt',
                ),

                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                    decoration: const InputDecoration(
                      hintText:
                          'Type e.g. "spend 12.5 lunch" / "income 300 salary"',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Mic button (triggers existing voice flow)
                IconButton(
                  onPressed: () {
                    context.read<AppSessionProvider>().triggerChatVoiceMode();
                  },
                  icon: const Icon(Icons.mic_none),
                  tooltip: 'Voice input',
                ),

                const SizedBox(width: 4),

                // Send icon-only button
                FilledButton(
                  onPressed: _sendText,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(44, 44),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
