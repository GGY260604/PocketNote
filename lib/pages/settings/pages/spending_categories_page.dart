// lib/pages/settings/pages/spending_categories_page.dart
//
// Manage spending categories (custom/add/edit/delete)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/icon_choices.dart';
import '../../../models/category.dart';
import '../../../state/categories_provider.dart';

class SpendingCategoriesPage extends StatelessWidget {
  const SpendingCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoriesBasePage(
      type: CategoryType.spending,
      title: 'Spending Categories',
    );
  }
}

class CategoriesBasePage extends StatelessWidget {
  final CategoryType type;
  final String title;

  const CategoriesBasePage({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CategoriesProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Builder(
        builder: (_) {
          if (p.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (p.error != null) return Center(child: Text('Error: ${p.error}'));

          final list = (type == CategoryType.spending ? p.spending : p.income)
              .where((c) => !c.isDeleted)
              .toList();

          if (list.isEmpty) {
            return const Center(
              child: Text('No categories yet. Tap + to add one.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = list[i];
              final icon = IconData(
                c.iconCodePoint,
                fontFamily: c.iconFontFamily,
              );

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(c.iconBgColorValue),
                    child: Icon(icon, color: Colors.black87),
                  ),
                  title: Text(c.name, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _CategoryEditor.open(context, type: type, existing: c),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _CategoryEditor.open(context, type: type),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryEditor extends StatefulWidget {
  final CategoryType type;
  final Category? existing;
  const _CategoryEditor({required this.type, this.existing});

  static Future<void> open(
    BuildContext context, {
    required CategoryType type,
    Category? existing,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CategoryEditor(type: type, existing: existing),
    );
  }

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;

  IconData _icon = IconChoices.icons.first;
  Color _bg = IconChoices.colors.first;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');

    if (widget.existing != null) {
      final e = widget.existing!;
      _icon = IconData(e.iconCodePoint, fontFamily: e.iconFontFamily);
      _bg = Color(e.iconBgColorValue);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final p = context.read<CategoriesProvider>();
    final name = _nameCtrl.text.trim();
    final fontFamily = _icon.fontFamily ?? 'MaterialIcons';

    if (widget.existing == null) {
      await p.addCategory(
        type: widget.type,
        name: name,
        iconCodePoint: _icon.codePoint,
        iconFontFamily: fontFamily,
        iconBgColorValue: _bg.toARGB32(),
      );
    } else {
      final e = widget.existing!;
      await p.updateCategory(
        e.copyWith(
          name: name,
          iconCodePoint: _icon.codePoint,
          iconFontFamily: fontFamily,
          iconBgColorValue: _bg.toARGB32(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;

    // ✅ Capture BEFORE async gap
    final navigator = Navigator.of(context);
    final categories = context.read<CategoriesProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: const Text('This category will be removed (soft delete).'),
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

    await categories.deleteCategory(e.id);

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
                    widget.existing == null ? 'Add Category' : 'Edit Category',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
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
                labelText: 'Category name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name required' : null,
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

// Shared widgets (same as AccountsPage)
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
