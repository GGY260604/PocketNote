// lib/data/sync/sync_gate.dart
//
// Wraps your app UI and triggers sync once when:
// - user is signed in and Google linked (not anonymous)
// - and uid changes (new user)
//
// Updated to use SyncProvider (state/) instead of SyncController.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../state/sync_provider.dart';

import '../../state/app_session_provider.dart';
import '../../state/accounts_provider.dart';
import '../../state/categories_provider.dart';
import '../../state/budgets_provider.dart';
import '../../state/records_provider.dart';

class SyncGate extends StatefulWidget {
  final Widget child;
  const SyncGate({super.key, required this.child});

  @override
  State<SyncGate> createState() => _SyncGateState();
}

class _SyncGateState extends State<SyncGate> {
  String? _lastSyncedUid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Keep read() here to avoid rebuild loops on sync state changes
    final sync = context.read<SyncProvider>();

    // capture providers BEFORE await
    final session = context.read<AppSessionProvider>();
    final accountsP = context.read<AccountsProvider>();
    final categoriesP = context.read<CategoriesProvider>();
    final budgetsP = context.read<BudgetsProvider>();
    final recordsP = context.read<RecordsProvider>();

    final uid = auth.uid;
    final canSync = uid != null && auth.isGoogleLinked && !auth.isAnonymous;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!canSync) return;

      // Only sync once per uid unless you manually call it elsewhere
      if (_lastSyncedUid == uid) return;

      _lastSyncedUid = uid;

      // 1) sync remote <-> local
      await sync.syncNow(auth);

      if (!mounted) return;

      // 2) reload providers from Hive so UI updates immediately
      //    (This fixes: "sync completed but records not visible until month change")
      await Future.wait([
        accountsP.refresh(),
        categoriesP.refresh(),
        budgetsP.load(),
      ]);

      // Records need the current month
      await recordsP.loadMonth(session.homeMonth);
    });

    return widget.child;
  }
}
