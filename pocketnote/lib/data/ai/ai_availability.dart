// lib/data/ai/ai_availability.dart
//
// Lightweight helper so UI can know whether Gemini is reachable.
// Uses GeminiService.testGemini() with caching.

import 'gemini_service.dart';

class AiAvailability {
  AiAvailability(this._gemini);

  final GeminiService _gemini;

  bool? _cachedOk;
  DateTime? _cachedAt;

  Future<bool> isGeminiOk({
    Duration cacheFor = const Duration(minutes: 2),
  }) async {
    final now = DateTime.now();
    if (_cachedOk != null && _cachedAt != null) {
      if (now.difference(_cachedAt!) <= cacheFor) return _cachedOk!;
    }
    final ok = await _gemini.testGemini();
    _cachedOk = ok;
    _cachedAt = now;
    return ok;
  }
}
