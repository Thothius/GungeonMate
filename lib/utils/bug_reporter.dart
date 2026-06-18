import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/haptics.dart';

class BugReporter {
  static void show(BuildContext context, String sourceContext) {
    final TextEditingController controller = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false, // Non-dismissable
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.bug_report_rounded, color: Colors.redAccent, size: 24),
              SizedBox(width: 10),
              Text(
                'REPORT A BUG',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location: $sourceContext',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Describe what went wrong or suggest an improvement:',
                style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 5,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your bug report or feedback here...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.white30),
                  filled: true,
                  fillColor: Colors.black26,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white12, width: 1.0),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Haptics.heavy();
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Haptics.heavy();
                final String bugText = controller.text.trim();
                if (bugText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter some text before submitting!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                // Construct full email message body with source context info!
                final String emailBody = 'Bug/Feedback Content:\n'
                    '--------------------------------------------------\n'
                    '$bugText\n\n'
                    '--------------------------------------------------\n'
                    'Diagnostic Telemetry Metadata:\n'
                    '• App Version: v0.9.1\n'
                    '• Source Location: $sourceContext\n'
                    '• Device Platform: Android Sideloaded Build';

                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'gungeonmate@gmail.com',
                  queryParameters: {
                    'subject': 'GungeonMate Bug Report (v0.9.1) - $sourceContext',
                    'body': emailBody,
                  },
                );

                try {
                  await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open email client: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'SUBMIT',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.5),
              ),
            ),
          ],
        );
      },
    );
  }
}
