// lib/state/ai_settings_provider.dart
//
// - Users can ONLY choose from an allowlist of models
// - Persist with SharedPreferences

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiSettingsProvider extends ChangeNotifier {
  static const _kModelName = 'ai.modelName';
  static const _kStrictMode = 'ai.strictMode';

  // ✅ Option A allowlist (edit this list to control cost/risk)
  static const List<String> allowedModels = [
    'gemini-3-flash-preview',
    // Uncomment only if you truly want to allow it:
    // 'gemini-3.1-pro-preview',
  ];

  String _modelName = allowedModels.first;
  bool _strictMode = true;
  bool _ready = false;

  bool get ready => _ready;
  String get modelName => _modelName;
  bool get strictMode => _strictMode;

  AiSettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();

    final savedModel = sp.getString(_kModelName);
    final savedStrict = sp.getBool(_kStrictMode);

    // ✅ validate saved model (might be old free-text value)
    if (savedModel != null && allowedModels.contains(savedModel)) {
      _modelName = savedModel;
    } else {
      _modelName = allowedModels.first;
      // Optional: clean bad saved value
      await sp.setString(_kModelName, _modelName);
    }

    _strictMode = savedStrict ?? _strictMode;

    _ready = true;
    notifyListeners();
  }

  Future<void> setModelName(String v) async {
    final name = v.trim();
    if (!allowedModels.contains(name)) return; // ✅ reject unknown models
    if (name == _modelName) return;

    _modelName = name;
    notifyListeners();

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kModelName, _modelName);
  }

  Future<void> setStrictMode(bool v) async {
    if (v == _strictMode) return;

    _strictMode = v;
    notifyListeners();

    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kStrictMode, _strictMode);
  }
}
