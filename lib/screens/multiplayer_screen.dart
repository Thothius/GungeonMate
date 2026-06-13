import 'package:flutter/material.dart';

/// Bluetooth-paired multiplayer entry point. Implementation is staged
/// across multiple sessions — this screen currently surfaces the
/// concept, the feature roadmap, and a "back to main menu" affordance.
///
/// See `docs/MULTIPLAYER_PLAN.md` for the full architecture brief
/// (transport, payloads, sync cadence, conflict resolution).
class MultiplayerScreen extends StatelessWidget {
  const MultiplayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bluetooth_searching,
                    size: 32,
                    color: Colors.lightBlueAccent.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pair two phones over Bluetooth',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Two players, one run. Each device tracks its own '
                'inventory locally and bounces every change (item '
                'pickup, transfer, coolness/curse adjustment, shrine '
                'use) to the paired device. No internet, no servers.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 22),
              const _StatusPill(
                icon: Icons.construction,
                label: 'Coming soon',
                color: Colors.amber,
              ),
              const SizedBox(height: 22),
              Text(
                'WHAT WORKS WHEN IT SHIPS',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 10),
              const _Bullet('Host or Join from this screen'),
              const _Bullet('Each player sees their own inventory by default'),
              const _Bullet(
                  'Swipe to view the other player\'s loadout in real time'),
              const _Bullet(
                  'Item / gun transfers, shrine effects, and stat tweaks '
                  'sync within ~3 seconds'),
              const _Bullet(
                  'Pause and resume runs — both phones write a shared run '
                  'snapshot whenever something changes'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to main menu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
