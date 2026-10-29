import 'package:flutter/material.dart';
import '../../services/goop_talk_engine.dart';

// =============================================================================
// TransferSheet — relocated from player_page.dart so it can be shared
// without a circular import.
// =============================================================================

class TransferSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onConfirm;
  const TransferSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.amber),
            const SizedBox(height: 10),
            GoopText(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            GoopText(subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const GoopText('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const GoopText('Transfer'),
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
