import 'package:flutter/material.dart';
import '../../models/gun.dart';
import '../../services/elemental_tagger.dart';
import '../../services/goop_talk_engine.dart';
import '../../theme/tokens.dart';

/// NOTES tab for gun detail — curated, compact lore+effect text.
/// Effect notes first, Ammonomicon entry merged below, elemental
/// status icons, quote as an italic footer.
class GunNotesTab extends StatelessWidget {
  final Gun gun;
  final Set<ElementKind> elements;
  const GunNotesTab({super.key, required this.gun, required this.elements});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gun.notes.isNotEmpty) ...[
            _BlockLabel(text: 'EFFECT'),
            const SizedBox(height: 6),
            // Formatted bullets — the raw notes string repeats in the
            // header effect line; here it reads as scannable entries.
            for (final line in gun.notes
                .split(RegExp(r'\.(?:\s+|$)'))
                .where((l) => l.trim().isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: GoopText(
                        line.trim(),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (elements.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final e in elements) _ElementChip(kind: e)],
            ),
          ],
        ],
      ),
    );
  }
}

class _BlockLabel extends StatelessWidget {
  final String text;
  const _BlockLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return GoopText(
      text,
      style: TextStyle(
        fontSize: FontSizes.labelSmall,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.6,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }
}

/// Elemental chip for the notes tab — icon + label so the status
/// icons are self-describing here (header shows dots only).
class _ElementChip extends StatelessWidget {
  final ElementKind kind;
  const _ElementChip({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kind.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.all(Radii.sm),
        border: Border.all(
          color: kind.color.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kind.icon, size: 14, color: kind.color),
          const SizedBox(width: 5),
          GoopText(
            kind.label,
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w800,
              color: kind.color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
