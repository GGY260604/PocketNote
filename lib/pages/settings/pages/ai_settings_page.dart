// lib/pages/settings/pages/ai_settings_page.dart
//
// Option A (safe):
// - model name from dropdown allowlist
// - strict mode toggle

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/ai_settings_provider.dart';

class AiSettingsPage extends StatelessWidget {
  const AiSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiSettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('AI Settings')),
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
                    'Gemini Model',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue:
                        AiSettingsProvider.allowedModels.contains(ai.modelName)
                        ? ai.modelName
                        : AiSettingsProvider.allowedModels.first,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      border: OutlineInputBorder(),
                    ),
                    items: AiSettingsProvider.allowedModels
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      await context.read<AiSettingsProvider>().setModelName(v);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Model set to: $v')),
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'Choose from the approved list to control cost.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: SwitchListTile(
              value: ai.strictMode,
              onChanged: (v) =>
                  context.read<AiSettingsProvider>().setStrictMode(v),
              title: const Text('Strict mode'),
              subtitle: const Text(
                'Strict mode forces exact category/account matching.\n'
                'If AI is unsure, it leaves fields empty and you choose in Confirm.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
