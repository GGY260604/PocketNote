import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/sync_provider.dart';

import '../../widgets/confirm_dialog.dart';

import 'pages/accounts_page.dart';
import 'pages/spending_categories_page.dart';
import 'pages/income_categories_page.dart';
import 'pages/budgets_page.dart';
import 'pages/ai_status_page.dart';
import 'pages/ai_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();

    if (auth.isAnonymous) {
      final ok = await ConfirmDialog.show(
        context,
        title: 'Sign out (Anonymous)',
        message:
            'You are using an anonymous account. If you sign out without linking, '
            'you may lose access to your cloud identity. Your local (offline) data stays on this phone, '
            'but it will not be synced to your Google account.\n\nContinue?',
        confirmText: 'Sign out',
        danger: true,
      );
      if (!ok) return;
    }

    await auth.signOut();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out (auto anonymous again).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AccountStatusCard(onSignOut: () => _signOut(context)),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Assets (Accounts)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountsPage()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Spending Categories'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SpendingCategoriesPage(),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.savings_outlined),
                title: const Text('Income Categories'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncomeCategoriesPage(),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.pie_chart_outline),
                title: const Text('Budgets'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BudgetsPage()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: const Text('AI Setup Status'),
                subtitle: const Text('Test Gemini + debug AI features'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiStatusPage()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('AI Settings'),
                subtitle: const Text('Model + strict mode'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiSettingsPage()),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (mode) {
              if (mode == null) return;
              settings.setThemeMode(mode);
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text('Theme: System'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text('Theme: Light'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text('Theme: Dark'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountStatusCard extends StatelessWidget {
  final VoidCallback onSignOut;
  const _AccountStatusCard({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<SyncProvider>(); // ✅ reactive sync state

    final user = auth.user;
    final isAnon = auth.isAnonymous;
    final email = user?.email;
    final uid = user?.uid ?? '-';
    final cs = Theme.of(context).colorScheme;

    final isGoogleLinked = auth.isGoogleLinked;

    final canSync =
        auth.uid != null && auth.isGoogleLinked && !auth.isAnonymous;

    final lastAtIso = sync.lastSyncAtIso;
    final lastError = sync.lastSyncError;

    String lastAtText = 'Never';
    if (lastAtIso != null && lastAtIso.trim().isNotEmpty) {
      final dt = DateTime.tryParse(lastAtIso);
      if (dt != null) lastAtText = dt.toLocal().toString();
    }

    final hasError = lastError != null && lastError.trim().isNotEmpty;

    Future<void> runWithSnack({
      required String okMsg,
      required Future<void> Function() action,
    }) async {
      final ap = context.read<AuthProvider>();
      final messenger = ScaffoldMessenger.of(context);

      try {
        await action();
        messenger.showSnackBar(SnackBar(content: Text(okMsg)));
      } catch (_) {
        final msg = ap.error ?? 'Action failed';
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Account Status',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (auth.loading || sync.isRunning)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            _InfoRow(
              label: 'Status',
              value: isAnon ? 'Anonymous' : 'Google Linked',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Email',
              value: email ?? (isAnon ? '-' : '(No email)'),
            ),
            const SizedBox(height: 6),
            _InfoRow(label: 'UID', value: uid),

            if (auth.error != null) ...[
              const SizedBox(height: 10),
              Text('Error: ${auth.error}', style: TextStyle(color: cs.error)),
            ],

            const SizedBox(height: 12),

            Card(
              color: cs.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  isAnon
                      ? 'Tip: Link Google to enable safe online sync across devices.'
                      : 'Your account is linked. Online sync can be private per user.',
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (isAnon) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link),
                title: const Text('Link with Google'),
                subtitle: const Text(
                  'Recommended: protect your cloud sync (keeps UID)',
                ),
                enabled: !auth.loading,
                onTap: () => runWithSnack(
                  okMsg: 'Linked with Google successfully ✅',
                  action: () =>
                      context.read<AuthProvider>().linkAnonymousToGoogle(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.login),
                title: const Text('Login with Google'),
                subtitle: const Text('Sign in directly (UID may change)'),
                enabled: !auth.loading,
                onTap: () => runWithSnack(
                  okMsg: 'Signed in with Google ✅',
                  action: () => context.read<AuthProvider>().signInWithGoogle(),
                ),
              ),
            ] else if (isGoogleLinked) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Switch Google account'),
                subtitle: const Text('Relink to another Google (keeps UID)'),
                enabled: !auth.loading,
                onTap: () => runWithSnack(
                  okMsg: 'Switched Google account ✅',
                  action: () =>
                      context.read<AuthProvider>().switchLinkedGoogle(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_off),
                title: const Text('Unlink Google'),
                subtitle: const Text('Remove Google link from this account'),
                enabled: !auth.loading,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Unlink Google?'),
                      content: const Text(
                        'This removes your Google link. You may lose cloud identity on other devices.\n\nContinue?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => navigator.pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => navigator.pop(true),
                          child: const Text('Unlink'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;

                  await runWithSnack(
                    okMsg: 'Google unlinked ✅',
                    action: () => context.read<AuthProvider>().unlinkGoogle(),
                  );
                },
              ),
            ],

            const Divider(height: 1),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                hasError ? Icons.sync_problem : Icons.sync,
                color: hasError ? cs.error : null,
              ),
              title: const Text('Sync Now'),
              subtitle: Text(
                hasError ? 'Last error: $lastError' : 'Last sync: $lastAtText',
              ),
              enabled: canSync && !auth.loading && !sync.isRunning,
              onTap: () async {
                final ap = context.read<AuthProvider>();
                final messenger = ScaffoldMessenger.of(context);

                try {
                  await sync.syncNow(ap);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Sync completed')),
                  );
                } catch (_) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        sync.lastSyncError ?? ap.error ?? 'Sync failed',
                      ),
                    ),
                  );
                }
              },
            ),

            const Divider(height: 1),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              subtitle: Text(
                isAnon
                    ? 'Warning: anonymous sign-out may lose cloud identity'
                    : 'You can sign back in anytime',
              ),
              enabled: !auth.loading,
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
