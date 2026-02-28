// lib/pages/settings/pages/account_status_page.dart
//
// AccountStatusPage:
// - Shows current auth status (Anonymous / Google)
// - Allows linking anonymous -> Google
// - Allows sign out with anonymous warning
//
// Uses AuthProvider (already in your app root)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/auth_provider.dart';

class AccountStatusPage extends StatelessWidget {
  const AccountStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final user = auth.user;
    final isAnon = auth.isAnonymous;
    final email = user?.email;
    final uid = user?.uid ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Account Status')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Account',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
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
                    Text(
                      'Error: ${auth.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Link with Google'),
                  subtitle: Text(
                    isAnon
                        ? 'Recommended: protect your cloud sync'
                        : 'Already linked (or not anonymous)',
                  ),
                  enabled: isAnon && !auth.loading,
                  onTap: () async {
                    try {
                      await context
                          .read<AuthProvider>()
                          .linkAnonymousToGoogle();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Linked with Google successfully'),
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      final msg =
                          context.read<AuthProvider>().error ??
                          'Failed to link Google';
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  subtitle: Text(
                    isAnon
                        ? 'Warning: sign out while anonymous may lose cloud identity'
                        : 'You can sign back in anytime',
                  ),
                  onTap: () async {
                    // Capture BEFORE any await
                    final auth = context.read<AuthProvider>();
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final isAnon = auth.isAnonymous;

                    if (isAnon) {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Sign out?'),
                          content: const Text(
                            'You are using an anonymous account.\n\n'
                            'If you sign out without linking Google, you may lose access to cloud sync on other devices.\n\n'
                            'Local offline data stays on this phone.',
                          ),
                          actions: [
                            TextButton(
                              // ✅ use captured navigator, not context
                              onPressed: () => navigator.pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => navigator.pop(true),
                              child: const Text('Sign out'),
                            ),
                          ],
                        ),
                      );

                      if (ok != true) return;
                    }

                    try {
                      await auth.signOut();

                      // ✅ no context usage after await
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Signed out')),
                      );
                      navigator.pop(); // go back to Settings
                    } catch (_) {
                      final msg = auth.error ?? 'Failed to sign out';
                      messenger.showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                isAnon
                    ? 'Tip: Link Google to enable safe online sync across devices.'
                    : 'Your account is linked. Online sync can be private per user.',
              ),
            ),
          ),
        ],
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
