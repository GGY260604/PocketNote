// lib/pages/settings/pages/ai_status_page.dart
//
// AI Setup Status page
// - Test Gemini via Firebase AI Logic
// - Shows model name
// - Helps debug fallback behavior

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/ai/gemini_service.dart';
import '../../../state/ai_settings_provider.dart';

class AiStatusPage extends StatefulWidget {
  const AiStatusPage({super.key});

  @override
  State<AiStatusPage> createState() => _AiStatusPageState();
}

class _AiStatusPageState extends State<AiStatusPage> {
  bool _testing = false;
  bool? _ok;
  String? _note;

  Future<void> _runTest() async {
    setState(() {
      _testing = true;
      _ok = null;
      _note = null;
    });

    final aiSettings = context.read<AiSettingsProvider>();

    final gemini = GeminiService(
      modelName: aiSettings.modelName,
      strictMode: aiSettings.strictMode,
    );

    try {
      final ok = await gemini.testGemini();

      setState(() {
        _ok = ok;
        _note = ok
            ? 'Gemini is responding ✅'
            : 'Gemini test failed ❌\n'
              'Common causes:\n'
              '- Firebase AI Logic not enabled\n'
              '- Wrong Firebase project\n'
              '- No internet\n'
              '- App Check blocking\n'
              '- Invalid model name';
      });
    } catch (e) {
      setState(() {
        _ok = false;
        _note = 'Exception: $e';
      });
    } finally {
      setState(() {
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiSettings = context.watch<AiSettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('AI Setup Status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Gemini (Firebase AI Logic)',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text('Model: ${aiSettings.modelName}'),
                  Text('Strict mode: ${aiSettings.strictMode ? "ON" : "OFF"}'),
                  const SizedBox(height: 12),

                  FilledButton.icon(
                    onPressed: _testing ? null : _runTest,
                    icon: const Icon(Icons.bolt),
                    label: Text(_testing ? 'Testing...' : 'Test Gemini'),
                  ),

                  const SizedBox(height: 12),

                  if (_ok == null)
                    const Text('Not tested yet')
                  else if (_ok == true)
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Gemini OK'),
                      ],
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Gemini NOT working'),
                      ],
                    ),

                  if (_note != null) ...[
                    const SizedBox(height: 8),
                    Text(_note!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}