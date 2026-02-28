// lib/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_session_provider.dart';
import '../pages/home/home_page.dart';
import '../pages/chart/chart_page.dart';
import '../pages/record/record_hub_page.dart';
import '../pages/chat/chat_page.dart';
import '../pages/settings/settings_page.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("RUNNING AppScaffold (final scaffold)");

    final session = context.watch<AppSessionProvider>();
    final titles = const ['Home', 'Chart', 'Record', 'Chat', 'Setting'];

    final pages = const [
      HomePage(),
      ChartPage(),
      RecordHubPage(),
      ChatPage(),
      SettingsPage(),
    ];

    final isChatTab = session.tabIndex == 3;

    return Scaffold(
      appBar: AppBar(title: Text(titles[session.tabIndex])),
      body: SafeArea(
        child: IndexedStack(index: session.tabIndex, children: pages),
      ),
      floatingActionButton: isChatTab
          ? null
          : FloatingActionButton(
              onPressed: () {
                // ✅ capture provider once (cleaner)
                final s = context.read<AppSessionProvider>();
                s.triggerChatVoiceMode();
                s.setTab(3); // Chat tab index
              },
              child: const Icon(Icons.mic),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: session.tabIndex,
        onDestinationSelected: (i) =>
            context.read<AppSessionProvider>().setTab(i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Chart'),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline, size: 50),
            label: 'Record',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}
