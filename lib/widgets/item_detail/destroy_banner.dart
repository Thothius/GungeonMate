import 'package:flutter/material.dart';
import '../../services/goop_talk_engine.dart';
import '../skeuo/skeuo_tokens.dart';

class DestroyBanner extends StatelessWidget {
  final VoidCallback onDestroy;
  const DestroyBanner({super.key, required this.onDestroy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Card(
        elevation: 0,
        color: Skeuo.inkIf(Colors.red).withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Skeuo.inkIf(Colors.redAccent).withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Skeuo.inkIf(Colors.redAccent),
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  GoopText(
                    'DESTROYED ON USE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Skeuo.inkIf(Colors.redAccent),
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
                  color: Skeuo.collapse(Colors.white).withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: 12),
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
                    backgroundColor: Skeuo.inkIf(Colors.redAccent),
                    foregroundColor: Skeuo.collapse(Colors.white),
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
