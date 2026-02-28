// lib/pages/chat/widgets/candidate_sheet.dart
//
// Shows multiple DraftRecord candidates from Gemini.
// User picks one → ConfirmSheet edits it → save.

import 'package:flutter/material.dart';

import '../../../core/utils/money_utils.dart';
import '../../../models/chat/draft_record.dart';
import '../../../models/record.dart';

class CandidateSheet extends StatelessWidget {
  final List<DraftRecord> candidates;

  const CandidateSheet({super.key, required this.candidates});

  static Future<DraftRecord?> show(
    BuildContext context, {
    required List<DraftRecord> candidates,
  }) {
    return showModalBottomSheet<DraftRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CandidateSheet(candidates: candidates),
    );
  }

  String _typeLabel(RecordType t) {
    switch (t) {
      case RecordType.spending:
        return 'Spending';
      case RecordType.income:
        return 'Income';
      case RecordType.transfer:
        return 'Transfer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Choose the best match',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'AI found multiple interpretations. Pick one to confirm.',
              style: TextStyle(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: candidates.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final d = candidates[i];
                  final amount = MoneyUtils.formatRM(d.amountCents);
                  final type = _typeLabel(d.type);
                  final title = (d.title ?? '').trim();

                  return InkWell(
                    onTap: () => Navigator.pop(context, d),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            foregroundColor: cs.onPrimaryContainer,
                            child: Text(type.characters.first),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$type • $amount',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (title.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
