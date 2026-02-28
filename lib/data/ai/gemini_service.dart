// lib/data/ai/gemini_service.dart
//
// Gemini parsing service using Firebase AI Logic (firebase_ai).
// - Takes user text
// - Asks Gemini to return STRICT JSON
// - Maps returned names -> IDs using current accounts + categories
// - Returns DraftRecord for ConfirmSheet
//
// If Gemini fails (offline, quota, config), returns null so UI can fallback.

import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/chat/draft_record.dart';
import '../../models/record.dart';

class GeminiService {
  GeminiService({required this.modelName, required this.strictMode});

  final String modelName;
  final bool strictMode;

  GenerativeModel get _model =>
      FirebaseAI.googleAI().generativeModel(model: modelName);

  Future<DraftRecord?> parseTextToDraft({
    required String userText,
    required List<Account> accounts,
    required List<Category> spendingCategories,
    required List<Category> incomeCategories,
  }) async {
    final prompt = _buildPrompt(
      userText: userText,
      accounts: accounts,
      spendingCategories: spendingCategories,
      incomeCategories: incomeCategories,
    );

    try {
      // Official docs: prompt as List<Content>, e.g. [Content.text("...")]
      final resp = await _model.generateContent([Content.text(prompt)]);
      final raw = (resp.text ?? '').trim();
      if (raw.isEmpty) return null;

      final jsonText = _extractJson(raw);
      final map = json.decode(jsonText);

      if (map is! Map<String, dynamic>) return null;

      return _mapJsonToDraft(
        map,
        accounts: accounts,
        spendingCategories: spendingCategories,
        incomeCategories: incomeCategories,
      );
    } catch (_) {
      // Any failure: offline, misconfigured Firebase AI Logic, quota, etc.
      return null;
    }
  }

  Future<List<DraftRecord>> parseTextToDraftCandidates({
    required String userText,
    required List<Account> accounts,
    required List<Category> spendingCategories,
    required List<Category> incomeCategories,
    int maxCandidates = 3,
  }) async {
    final prompt = _buildCandidatesPrompt(
      userText: userText,
      accounts: accounts,
      spendingCategories: spendingCategories,
      incomeCategories: incomeCategories,
      maxCandidates: maxCandidates,
    );

    try {
      final resp = await _withTimeout(
        () => _model.generateContent([Content.text(prompt)]),
      );
      if (resp == null) return const [];
      final raw = (resp.text ?? '').trim();
      if (raw.isEmpty) return const [];

      final jsonText = _extractJson(raw);
      final decoded = json.decode(jsonText);

      if (decoded is! List) return const [];

      final out = <DraftRecord>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final d = _mapJsonToDraft(
          item,
          accounts: accounts,
          spendingCategories: spendingCategories,
          incomeCategories: incomeCategories,
        );
        if (d != null) out.add(d);
        if (out.length >= maxCandidates) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  String _buildCandidatesPrompt({
    required String userText,
    required List<Account> accounts,
    required List<Category> spendingCategories,
    required List<Category> incomeCategories,
    required int maxCandidates,
  }) {
    final accountNames = accounts.map((a) => a.name).toList();
    final spendNames = spendingCategories.map((c) => c.name).toList();
    final incomeNames = incomeCategories.map((c) => c.name).toList();

    return '''
You are PocketNote, a personal finance assistant.

Task:
Convert the user's message into up to $maxCandidates plausible transaction drafts.

Return ONLY valid JSON ARRAY (no markdown, no explanations, no code fences).

STRICT SELECTION RULES:
- Any name field MUST match EXACTLY one of the provided strings.
- If unsure, output null (do NOT invent names).

Rules:
- type: "spending" OR "income" OR "transfer"
- amount: positive number (RM)
- date: "YYYY-MM-DD" if mentioned, else omit
- includeInStats/includeInBudget default true
- For spending/income: categoryName and accountName
- For transfer: fromAccountName and toAccountName + optional serviceCharge

ALLOWED accounts (exact strings):
${json.encode(accountNames)}

ALLOWED spending categories (exact strings):
${json.encode(spendNames)}

ALLOWED income categories (exact strings):
${json.encode(incomeNames)}

User message:
${json.encode(userText)}

Schema (each array item; use null if unknown):
{
  "type": "spending|income|transfer",
  "amount": 0,
  "serviceCharge": 0,
  "date": "YYYY-MM-DD",
  "title": null,
  "tag": null,
  "includeInStats": true,
  "includeInBudget": true,
  "categoryName": null,
  "accountName": null,
  "fromAccountName": null,
  "toAccountName": null
}

Now output a JSON array with 1-$maxCandidates items.
''';
  }

  Future<List<DraftRecord>> parseReceiptImageToDraftCandidates({
    required Uint8List imageBytes,
    required String mimeType,
    required List<Account> accounts,
    required List<Category> spendingCategories,
    required List<Category> incomeCategories,
    int maxCandidates = 3,
  }) async {
    final prompt = _buildReceiptCandidatesPrompt(
      accounts: accounts,
      spendingCategories: spendingCategories,
      incomeCategories: incomeCategories,
      maxCandidates: maxCandidates,
    );

    try {
      final resp = await _withTimeout(
        () => _model.generateContent([
          Content.multi([
            TextPart(prompt),
            InlineDataPart(mimeType, imageBytes),
          ]),
        ]),
      );
      if (resp == null) return const [];

      final raw = (resp.text ?? '').trim();
      if (raw.isEmpty) return const [];

      final jsonText = _extractJson(raw);
      final decoded = json.decode(jsonText);

      if (decoded is! List) return const [];

      final out = <DraftRecord>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final d = _mapJsonToDraft(
          item,
          accounts: accounts,
          spendingCategories: spendingCategories,
          incomeCategories: incomeCategories,
        );
        if (d != null) out.add(d);
        if (out.length >= maxCandidates) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  String _buildReceiptCandidatesPrompt({
    required List<Account> accounts,
    required List<Category> spendingCategories,
    required List<Category> incomeCategories,
    required int maxCandidates,
  }) {
    final accountNames = accounts.map((a) => a.name).toList();
    final spendNames = spendingCategories.map((c) => c.name).toList();
    final incomeNames = incomeCategories.map((c) => c.name).toList();

    return '''
You are PocketNote, a personal finance assistant.

Task:
Analyze the RECEIPT IMAGE and produce up to $maxCandidates plausible transaction drafts.

Return ONLY valid JSON ARRAY (no markdown, no explanations, no code fences).

STRICT SELECTION RULES:
- If you output accountName/categoryName/fromAccountName/toAccountName, it MUST be EXACTLY one of the provided strings.
- If you are unsure, output null for that field (do NOT invent new names).

Guidance:
- Most receipts are purchases → type="spending".
- Use type="income" only if clearly money received.
- Use type="transfer" only if clearly a transfer between accounts (rare).

Rules:
- amount must be the TOTAL amount paid/received (RM)
- date must be "YYYY-MM-DD" if visible, else omit it
- title: merchant name if visible, else null/omit
- includeInStats/includeInBudget default true if unknown
- Choose categoryName/accountName from the lists exactly or output null

ALLOWED accounts (exact strings):
${json.encode(accountNames)}

ALLOWED spending categories (exact strings):
${json.encode(spendNames)}

ALLOWED income categories (exact strings):
${json.encode(incomeNames)}

Schema (each array item; use null if unknown):
{
  "type": "spending|income|transfer",
  "amount": 0,
  "serviceCharge": 0,
  "date": "YYYY-MM-DD",
  "title": null,
  "tag": null,
  "includeInStats": true,
  "includeInBudget": true,
  "categoryName": null,
  "accountName": null,
  "fromAccountName": null,
  "toAccountName": null
}

Now output a JSON array with 1-$maxCandidates items.
''';
  }

  Future<bool> testGemini() async {
    try {
      final resp = await _model.generateContent([
        Content.text('Reply with exactly: OK'),
      ]);
      final t = (resp.text ?? '').trim().toUpperCase();
      return t.contains('OK');
    } catch (_) {
      return false;
    }
  }

  Future<T?> _withTimeout<T>(
    Future<T> Function() work, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      return await work().timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  Future<DraftRecord?> parseReceiptImageToDraft({
    required Uint8List imageBytes,
    required String mimeType, // e.g. image/jpeg, image/png
    required List<Account> accounts,
    required List<Category> spendingCategories,
    required List<Category> incomeCategories,
  }) async {
    final prompt = _buildReceiptPrompt(
      accounts: accounts,
      spendingCategories: spendingCategories,
      incomeCategories: incomeCategories,
    );

    try {
      // Multimodal: text + inline image bytes
      final resp = await _model.generateContent([
        Content.multi([TextPart(prompt), InlineDataPart(mimeType, imageBytes)]),
      ]);

      final raw = (resp.text ?? '').trim();
      if (raw.isEmpty) return null;

      final jsonText = _extractJson(raw);
      final map = json.decode(jsonText);
      if (map is! Map<String, dynamic>) return null;

      return _mapJsonToDraft(
        map,
        accounts: accounts,
        spendingCategories: spendingCategories,
        incomeCategories: incomeCategories,
      );
    } catch (_) {
      return null;
    }
  }

  String _buildReceiptPrompt({
    required List<Account> accounts,
    required List<Category> spendingCategories,
    required List<Category> incomeCategories,
  }) {
    final accountNames = accounts.map((a) => a.name).toList();
    final spendNames = spendingCategories.map((c) => c.name).toList();
    final incomeNames = incomeCategories.map((c) => c.name).toList();

    return '''
You are PocketNote, a personal finance assistant.

Task:
Analyze the RECEIPT IMAGE and produce ONE transaction draft.

Return ONLY valid JSON (no markdown, no explanations, no code fences).

STRICT SELECTION RULES:
- If you output accountName/categoryName/fromAccountName/toAccountName, it MUST be EXACTLY one of the provided strings.
- If you are unsure, output null for that field (do NOT invent new names).

Guidance:
- Most receipts are purchases → type="spending".
- Use type="income" only if clearly money received (salary/transfer-in).
- Use type="transfer" only if clearly a transfer between accounts (rare).

Rules:
- amount must be the TOTAL amount paid/received (RM, decimals allowed)
- date must be "YYYY-MM-DD" if visible, else omit it
- title: merchant name if visible, else null/omit
- tag optional (null/omit if unknown)
- includeInStats and includeInBudget default true if unknown
- For spending/income: provide categoryName and accountName (exact match or null)
- For transfer: provide fromAccountName and toAccountName (exact match or null), optional serviceCharge (RM, default 0)

ALLOWED accounts (exact strings):
${json.encode(accountNames)}

ALLOWED spending categories (exact strings):
${json.encode(spendNames)}

ALLOWED income categories (exact strings):
${json.encode(incomeNames)}

Return JSON with these fields (use null if unknown):
{
  "type": "spending|income|transfer",
  "amount": 0,
  "serviceCharge": 0,
  "date": "YYYY-MM-DD",
  "title": null,
  "tag": null,
  "includeInStats": true,
  "includeInBudget": true,
  "categoryName": null,
  "accountName": null,
  "fromAccountName": null,
  "toAccountName": null
}
''';
  }

  String _buildPrompt({
    required String userText,
    required List<Account> accounts,
    required List<Category> spendingCategories,
    required List<Category> incomeCategories,
  }) {
    final accountNames = accounts.map((a) => a.name).toList();
    final spendNames = spendingCategories.map((c) => c.name).toList();
    final incomeNames = incomeCategories.map((c) => c.name).toList();

    return '''
You are PocketNote, a personal finance assistant.

Task:
Convert the user's message into ONE transaction draft.

Return ONLY valid JSON (no markdown, no explanations, no code fences).

STRICT SELECTION RULES:
- If you output accountName/categoryName/fromAccountName/toAccountName, it MUST be EXACTLY one of the provided strings.
- If you are unsure, output null for that field (do NOT invent new names).

Rules:
- type must be "spending" OR "income" OR "transfer"
- amount must be a positive number (RM, decimals allowed)
- date must be "YYYY-MM-DD" if mentioned, else omit it
- title and tag optional (omit or null if unknown)
- includeInStats and includeInBudget must be true/false (default true if unknown)
- For spending/income: categoryName and accountName
- For transfer: fromAccountName and toAccountName, and optional serviceCharge (RM, default 0)

ALLOWED accounts (exact strings):
${json.encode(accountNames)}

ALLOWED spending categories (exact strings):
${json.encode(spendNames)}

ALLOWED income categories (exact strings):
${json.encode(incomeNames)}

User message:
${json.encode(userText)}

Return JSON with these fields (use null if unknown):
{
  "type": "spending|income|transfer",
  "amount": 0,
  "serviceCharge": 0,
  "date": "YYYY-MM-DD",
  "title": null,
  "tag": null,
  "includeInStats": true,
  "includeInBudget": true,
  "categoryName": null,
  "accountName": null,
  "fromAccountName": null,
  "toAccountName": null
}
''';
  }

  DraftRecord? _mapJsonToDraft(
    Map<String, dynamic> m, {
    required List<Account> accounts,
    required List<Category> spendingCategories,
    required List<Category> incomeCategories,
  }) {
    final typeStr = (m['type'] ?? '').toString().toLowerCase().trim();
    final type = switch (typeStr) {
      'income' => RecordType.income,
      'transfer' => RecordType.transfer,
      _ => RecordType.spending,
    };

    final amount = _toDouble(m['amount']);
    if (amount <= 0) return null;

    final serviceCharge = _toDouble(m['serviceCharge']); // can be 0
    final date = _parseDate(m['date']?.toString());

    final includeInStats = _toBool(m['includeInStats'], defaultValue: true);
    final includeInBudget = _toBool(m['includeInBudget'], defaultValue: true);

    final title = _cleanNullable(m['title']);
    final tag = _cleanNullable(m['tag']);

    String? categoryId;
    String? accountId;
    String? fromAccountId;
    String? toAccountId;

    if (type == RecordType.spending || type == RecordType.income) {
      final categoryName = _cleanNullable(m['categoryName']);
      final accountName = _cleanNullable(m['accountName']);

      final cats = (type == RecordType.spending)
          ? spendingCategories
          : incomeCategories;

      categoryId = _findCategoryIdByName(cats, categoryName);
      accountId = _findAccountIdByName(accounts, accountName);
    } else {
      final fromName = _cleanNullable(m['fromAccountName']);
      final toName = _cleanNullable(m['toAccountName']);

      fromAccountId = _findAccountIdByName(accounts, fromName);
      toAccountId = _findAccountIdByName(accounts, toName);

      // Avoid same-from-to if Gemini messed up
      if (fromAccountId != null && fromAccountId == toAccountId) {
        toAccountId = null;
      }
    }

    return DraftRecord(
      type: type,
      amountCents: (amount * 100).round(),
      serviceChargeCents: (serviceCharge * 100).round(),
      date:
          date ??
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
      title: title,
      tag: tag,
      includeInStats: includeInStats,
      includeInBudget: includeInBudget,
      categoryId: categoryId,
      accountId: accountId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
    );
  }

  // --- helpers ---

  String _extractJson(String raw) {
    var t = raw.trim();

    // Remove common markdown code fences
    // Example:
    // ```json
    // [...]
    // ```
    if (t.startsWith('```')) {
      // remove first fence line
      final firstNewline = t.indexOf('\n');
      if (firstNewline != -1) {
        t = t.substring(firstNewline + 1);
      }
      // remove last fence
      final lastFence = t.lastIndexOf('```');
      if (lastFence != -1) {
        t = t.substring(0, lastFence);
      }
      t = t.trim();
    }

    // Prefer JSON array extraction if present
    final aStart = t.indexOf('[');
    final aEnd = t.lastIndexOf(']');
    if (aStart >= 0 && aEnd > aStart) {
      return t.substring(aStart, aEnd + 1);
    }

    // Fallback: JSON object extraction
    final oStart = t.indexOf('{');
    final oEnd = t.lastIndexOf('}');
    if (oStart >= 0 && oEnd > oStart) {
      return t.substring(oStart, oEnd + 1);
    }

    // As-is (may still fail, but caller will handle)
    return t;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    return double.tryParse(s) ?? 0;
  }

  bool _toBool(dynamic v, {required bool defaultValue}) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true') return true;
    if (s == 'false') return false;
    return defaultValue;
  }

  DateTime? _parseDate(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.isEmpty) return null;
    // Expect YYYY-MM-DD
    final parts = t.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  String? _cleanNullable(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return s;
  }

  String? _findAccountIdByName(List<Account> accounts, String? name) {
    if (name == null) return null;
    final target = name.trim();
    if (target.isEmpty) return null;

    // strict: exact only
    for (final a in accounts) {
      if (a.name.trim() == target) return a.id;
    }

    if (strictMode) return null;

    // relaxed fallback: contains
    final lower = target.toLowerCase();
    for (final a in accounts) {
      final n = a.name.toLowerCase();
      if (n.contains(lower) || lower.contains(n)) return a.id;
    }
    return null;
  }

  String? _findCategoryIdByName(List<Category> cats, String? name) {
    if (name == null) return null;
    final target = name.trim();
    if (target.isEmpty) return null;

    for (final c in cats) {
      if (c.name.trim() == target) return c.id;
    }

    if (strictMode) return null;

    final lower = target.toLowerCase();
    for (final c in cats) {
      final n = c.name.toLowerCase();
      if (n.contains(lower) || lower.contains(n)) return c.id;
    }
    return null;
  }
}
