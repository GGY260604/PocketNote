// lib/app.dart
//
// Registers all app-wide providers:
// - SettingsProvider (theme)
// - AuthProvider (anonymous + google)
// - AppSessionProvider (tab, month, voice flags)
// - SyncProvider (sync status + last sync time)
// - AiSettingsProvider (for AI features, e.g. auto-categorization)
//
// Data providers:
// - AccountsProvider
// - CategoriesProvider
// - RecordsProvider
// - BudgetsProvider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/auth_provider.dart';
import 'state/settings_provider.dart';
import 'state/app_session_provider.dart';
import 'state/sync_provider.dart';
import 'state/ai_settings_provider.dart';

import 'state/accounts_provider.dart';
import 'state/categories_provider.dart';
import 'state/records_provider.dart';
import 'state/budgets_provider.dart';

import 'widgets/app_scaffold.dart';
import 'data/sync/sync_gate.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // App settings/auth/session
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => AppSessionProvider()),
        ChangeNotifierProvider(create: (_) => AiSettingsProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),

        // Data providers (offline-first)
        ChangeNotifierProvider(create: (_) => AccountsProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => RecordsProvider()),
        ChangeNotifierProvider(create: (_) => BudgetsProvider()),
      ],
      child: Builder(
        builder: (context) {
          final settings = context.read<SettingsProvider>();

          return FutureBuilder(
            future: settings.ready,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const MaterialApp(
                  debugShowCheckedModeBanner: false,
                  home: Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              return Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'PocketNote',
                    theme: ThemeData(
                      useMaterial3: true,
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: Colors.green,
                      ),
                    ),
                    darkTheme: ThemeData(
                      useMaterial3: true,
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: Colors.green,
                        brightness: Brightness.dark,
                      ),
                    ),
                    themeMode: settings.themeMode,
                    home: const SyncGate(child: AppScaffold()),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
