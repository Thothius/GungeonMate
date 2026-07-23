import 'package:flutter/material.dart';
import '../../services/goop_talk_engine.dart';

class DestroyBanner extends StatelessWidget {
  final VoidCallback onDestroy;
  const DestroyBanner({super.key, required this.onDestroy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Card(
        elevation: 0,
        color: Colors.red.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const GoopText(
                    'DESTROYED ON USE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              GoopText(
                'This active item is consumed when used. Tap Destroy to remove it from the run; the item detail will close automatically.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: onDestroy,
                  icon: const Icon(Icons.whatshot, size: 20),
                  label: const GoopText(
                    'Destroy',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
