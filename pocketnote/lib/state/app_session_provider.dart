// lib/state/app_session_provider.dart
//
// AppSessionProvider
// - bottom nav tab index
// - homeMonth selection
// - chat voice mode trigger (requested by FAB)

import 'package:flutter/foundation.dart';

class AppSessionProvider extends ChangeNotifier {
  int _tabIndex = 0;
  DateTime _homeMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _requestChatVoiceMode = false;

  int get tabIndex => _tabIndex;
  DateTime get homeMonth => _homeMonth;

  bool get requestChatVoiceMode => _requestChatVoiceMode;

  void setTab(int i) {
    if (i == _tabIndex) return;
    _tabIndex = i;
    notifyListeners();
  }

  void setHomeMonth(DateTime m) {
    final normalized = DateTime(m.year, m.month);
    if (normalized.year == _homeMonth.year &&
        normalized.month == _homeMonth.month) {
      return;
    }
    _homeMonth = normalized;
    notifyListeners();
  }

  /// Called by FAB: switch to Chat and start voice mode.
  void triggerChatVoiceMode() {
    _requestChatVoiceMode = true;
    notifyListeners();
  }

  /// Called by ChatPage after it starts voice flow.
  void consumeChatVoiceMode() {
    if (!_requestChatVoiceMode) return;
    _requestChatVoiceMode = false;
    notifyListeners();
  }
}
