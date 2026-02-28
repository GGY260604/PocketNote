// lib/pages/settings/pages/accounts_page.dart
//
// Manage asset accounts:
// - add account (name + icon + bg color + initial balance)
// - edit account (name + icon + bg color + balance)
// - delete (soft delete via provider)
//
// - Top summary card: Net Assets, Total Assets, Owe Assets
// - Colored group box wrapping tiles
// - Overflow-safe: ellipsis + constraints

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/icon_choices.dart';
import '../../../core/utils/money_utils.dart';
import '../../../models/account.dart';
import '../../../state/accounts_provider.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AccountsProvider>();
    final cs = Theme.of(context).colorScheme;

    // Requested colors
    final groupBg = cs.primaryContainer.withValues(alpha: 0.12);
    final summaryBg = cs.primaryContainer.withValues(alpha: 0.50);

    return Scaffold(
      appBar: AppBar(title: const Text('Assets (Accounts)')),
      body: Builder(
        builder: (_) {
          if (p.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (p.error != null) {
            return Center(child: Text('Error: ${p.error}'));
          }

          final accounts = p.accounts.where((a) => !a.isDeleted).toList();

          // ---- Summary numbers ----
          final totalAssetsCents = accounts
              .where((a) => a.balanceCents > 0)
              .fold<int>(0, (sum, a) => sum + a.balanceCents);

          final oweAssetsCentsAbs = accounts
              .where((a) => a.balanceCents < 0)
              .fold<int>(0, (sum, a) => sum + a.balanceCents.abs());

          final netAssetsCents = totalAssetsCents - oweAssetsCentsAbs;

          Widget summaryCard() {
            return Card(
              elevation: 0,
              color: summaryBg,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(
                      label: 'Net Assets',
                      value: MoneyUtils.formatRM(netAssetsCents),
                      large: true,
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'Total Assets',
                      value: MoneyUtils.formatRM(totalAssetsCents),
                    ),
                    const SizedBox(height: 6),
                    _SummaryRow(
                      label: 'Owe Assets',
                      value: MoneyUtils.formatRM(oweAssetsCentsAbs),
                    ),
                  ],
                ),
              ),
            );
          }

          if (accounts.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                summaryCard(),
                const SizedBox(height: 12),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text('No accounts yet. Tap + to add one.'),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              summaryCard(),
              const SizedBox(height: 12),

              // Group box around tiles
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: groupBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final a = accounts[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(a.iconBgColorValue),
                          child: Icon(
                            IconData(
                              a.iconCodePoint,
                              fontFamily: a.iconFontFamily,
                            ),
                            color: Colors.black87,
                          ),
                        ),
                        title: Text(
                          a.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: Text(
                          'Balance: ${MoneyUtils.formatRM(a.balanceCents)}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _AccountEditor.open(context, existing: a),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _AccountEditor.open(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// A row: left label + right amount (overflow-safe).
/// If large=true, both label and value are slightly bigger.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool large;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final labelStyle = TextStyle(
      fontSize: large ? 14 : 12,
      fontWeight: large ? FontWeight.w900 : FontWeight.w700,
      color: cs.onPrimaryContainer,
    );

    final valueStyle = TextStyle(
      fontSize: large ? 16 : 13,
      fontWeight: large ? FontWeight.w900 : FontWeight.w800,
      color: cs.onPrimaryContainer,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            value,
            style: valueStyle,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}

class _AccountEditor extends StatefulWidget {
  final Account? existing;
  const _AccountEditor({this.existing});

  static Future<void> open(BuildContext context, {Account? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AccountEditor(existing: existing),
    );
  }

  @override
  State<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<_AccountEditor> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;

  IconData _icon = IconChoices.icons.first;
  Color _bg = IconChoices.colors.first;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: widget.existing == null
          ? '0.00'
          : MoneyUtils.toDouble(
              widget.existing!.balanceCents,
            ).toStringAsFixed(2),
    );

    if (widget.existing != null) {
      final e = widget.existing!;
      _icon = IconData(e.iconCodePoint, fontFamily: e.iconFontFamily);
      _bg = Color(e.iconBgColorValue);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final p = context.read<AccountsProvider>();
    final name = _nameCtrl.text.trim();
    final balance = double.parse(_balanceCtrl.text.trim());
    final balanceCents = MoneyUtils.toCents(balance);

    final fontFamily = _icon.fontFamily ?? 'MaterialIcons';

    if (widget.existing == null) {
      await p.addAccount(
        name: name,
        iconCodePoint: _icon.codePoint,
        iconFontFamily: fontFamily,
        iconBgColorValue: _bg.toARGB32(),
        initialBalanceCents: balanceCents,
      );
    } else {
      final e = widget.existing!;
      await p.updateAccount(
        e.copyWith(
          name: name,
          iconCodePoint: _icon.codePoint,
          iconFontFamily: fontFamily,
          iconBgColorValue: _bg.toARGB32(),
          balanceCents: balanceCents,
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;

    final navigator = Navigator.of(context);
    final accounts = context.read<AccountsProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This account will be removed (soft delete).'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => navigator.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await accounts.deleteAccount(e.id);

    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _bg,
                  child: Icon(_icon, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.existing == null ? 'Add Account' : 'Edit Account',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (widget.existing != null)
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline, color: cs.error),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Account name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name required' : null,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _balanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Balance (RM)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final d = double.tryParse((v ?? '').trim());
                if (d == null) return 'Enter a valid number';
                return null;
              },
            ),

            const SizedBox(height: 12),

            _PickerSection(
              title: 'Pick icon',
              child: _IconGrid(
                selected: _icon,
                onPick: (v) => setState(() => _icon = v),
              ),
            ),

            const SizedBox(height: 12),

            _PickerSection(
              title: 'Pick color',
              child: _ColorGrid(
                selected: _bg,
                onPick: (v) => setState(() => _bg = v),
              ),
            ),

            const SizedBox(height: 14),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _PickerSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  final IconData selected;
  final ValueChanged<IconData> onPick;
  const _IconGrid({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: IconChoices.icons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (_, i) {
        final icon = IconChoices.icons[i];
        final isSel =
            icon.codePoint == selected.codePoint &&
            icon.fontFamily == selected.fontFamily;

        return InkWell(
          onTap: () => onPick(icon),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? cs.primary : cs.outlineVariant,
                width: isSel ? 2 : 1,
              ),
              color: cs.surface,
            ),
            child: Icon(icon),
          ),
        );
      },
    );
  }
}

class _ColorGrid extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onPick;
  const _ColorGrid({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: IconChoices.colors.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (_, i) {
        final c = IconChoices.colors[i];
        final isSel = c.toARGB32() == selected.toARGB32();

        return InkWell(
          onTap: () => onPick(c),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c,
              border: Border.all(
                color: isSel ? cs.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        );
      },
    );
  }
}
