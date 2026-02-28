// lib/pages/chat/widgets/voice_sheet.dart
//
// Real Speech-to-Text voice input.
// - Start/stop listening
// - Live transcript
// - Returns transcript to ChatPage

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceSheet extends StatefulWidget {
  const VoiceSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const VoiceSheet(),
    );
  }

  @override
  State<VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<VoiceSheet> {
  final SpeechToText _stt = SpeechToText();

  bool _available = false;
  bool _listening = false;

  String _words = '';
  double _confidence = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = await _stt.initialize(
      onStatus: (s) {
        // statuses: listening, notListening, done
        if (!mounted) return;
        setState(() {
          _listening = (s == 'listening');
        });
      },
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Speech error: ${e.errorMsg}')));
      },
    );

    if (!mounted) return;
    setState(() => _available = ok);
  }

  Future<void> _start() async {
    if (!_available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    setState(() {
      _words = '';
      _confidence = 0;
      _listening = true;
    });

    await _stt.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() {
          _words = r.recognizedWords;
          if (r.hasConfidenceRating) {
            _confidence = r.confidence;
          }
        });
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _stop() async {
    await _stt.stop();
    if (!mounted) return;
    setState(() => _listening = false);
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Voice Input',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_available)
                    Icon(_listening ? Icons.hearing : Icons.hearing_disabled),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  _words.isEmpty ? 'Tap Start and speak…' : _words,
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              const SizedBox(height: 8),
              if (_confidence > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Confidence: ${(_confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _listening ? _stop : _start,
                    icon: Icon(_listening ? Icons.stop : Icons.play_arrow),
                    label: Text(_listening ? 'Stop' : 'Start'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _words.trim().isEmpty
                        ? null
                        : () => Navigator.pop(context, _words.trim()),
                    icon: const Icon(Icons.check),
                    label: const Text('Use'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
