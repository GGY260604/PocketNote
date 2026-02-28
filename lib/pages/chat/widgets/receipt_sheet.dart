// lib/pages/chat/widgets/receipt_sheet.dart
//
// Stub receipt flow:
// - pick source (camera/gallery)
// - returns a bool indicating "picked"
// Actual analysis will be added later with Gemini Vision.

import 'package:flutter/material.dart';

enum ReceiptSource { camera, gallery }

class ReceiptSheet extends StatelessWidget {
  const ReceiptSheet({super.key});

  static Future<ReceiptSource?> show(BuildContext context) {
    return showModalBottomSheet<ReceiptSource>(
      context: context,
      builder: (_) => const ReceiptSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: const [
                Icon(Icons.receipt_long),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Upload receipt',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Later this will run AI receipt analysis.\nFor now we just simulate a parsed record.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ReceiptSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ReceiptSource.gallery),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
