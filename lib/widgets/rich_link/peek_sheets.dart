part of '../rich_link_text.dart';

class _RefChipText extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle baseStyle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RefChipText({
    required this.label,
    required this.color,
    required this.baseStyle,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: GoopText(
        label,
        style: baseStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: color.withValues(alpha: 0.45),
          decorationThickness: 1.2,
        ),
      ),
    );
  }
}

class _PeekSheet extends StatelessWidget {
  final Gun? gun;
  final Item? item;
  const _PeekSheet({this.gun, this.item}) : assert(gun != null || item != null);

  @override
  Widget build(BuildContext context) {
    final name = gun?.name ?? item!.name;
    final quality = gun?.quality ?? item!.quality;
    final subtitle = gun != null ? gun!.type : item!.type;
    final quote = gun?.quote ?? item!.quote;
    final iconPath = gun?.icon ?? item!.icon;
    final body = gun != null ? gun!.notes : item!.effect;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Skeuo.collapse(Colors.white).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GameIcon(
                  assetPath: iconPath,
                  fallback:
                      gun != null
                          ? Icons.gps_fixed
                          : Icons.inventory_2_outlined,
                  quality: quality,
                  size: 56,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        name,
                        style: const TextStyle(
                          fontSize: FontSizes.titleMedium,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          if (quality.isNotEmpty) ...[
                            QualityBadge(quality: quality, size: 14),
                            SizedBox(width: 6),
                          ],
                          Flexible(
                            child: GoopText(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Skeuo.collapse(
                                  Colors.white,
                                ).withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (quote.isNotEmpty) ...[
              SizedBox(height: 10),
              GoopText(
                '"$quote"',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Skeuo.collapse(Colors.white).withValues(alpha: 0.65),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (body.isNotEmpty) ...[
              const SizedBox(height: 10),
              GoopText(
                body,
                style: const TextStyle(fontSize: 13.5, height: 1.35),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const GoopText('Open detail'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    fastRoute(ItemDetailScreen(gun: gun, item: item)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact peek for a [Gungeoneer]. Characters have no full detail
/// screen yet, so this sheet is the single canonical preview surface
/// for them. Shows portrait, name, and starting loadout — exactly what
/// a player wonders about when a wiki note mentions another character.
class _CharacterPeekSheet extends StatelessWidget {
  final Gungeoneer character;
  const _CharacterPeekSheet({required this.character});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Skeuo.collapse(Colors.white).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GameIcon(
                  assetPath: character.icon,
                  fallback: Icons.person,
                  size: 56,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        character.name,
                        style: const TextStyle(
                          fontSize: FontSizes.titleMedium,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      GoopText(
                        'Gungeoneer',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Skeuo.collapse(
                            Colors.white,
                          ).withValues(alpha: 0.7),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (character.startingGuns.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PeekLoadoutRow(
                icon: Icons.gps_fixed,
                label: 'Starting guns',
                items: character.startingGuns,
              ),
            ],
            if (character.startingItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PeekLoadoutRow(
                icon: Icons.inventory_2_outlined,
                label: 'Starting items',
                items: character.startingItems,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeekLoadoutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> items;
  const _PeekLoadoutRow({
    required this.icon,
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Skeuo.collapse(Colors.white).withValues(alpha: 0.7),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoopText(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Skeuo.collapse(Colors.white).withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 2),
              GoopText(
                items.join(', '),
                style: const TextStyle(fontSize: 13.5, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact peek for a [Shrine]. Surfaces the description / message /
/// effect lines and any auto-applied curse / coolness deltas so the
/// player can decide whether to seek the shrine out, all without
/// leaving the current detail screen.
class _ShrinePeekSheet extends StatelessWidget {
  final Shrine shrine;
  const _ShrinePeekSheet({required this.shrine});

  @override
  Widget build(BuildContext context) {
    final hasDelta = shrine.curse != 0 || shrine.coolness != 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Skeuo.collapse(Colors.white).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GameIcon(
                  assetPath: shrine.icon,
                  fallback: Icons.temple_buddhist,
                  size: 56,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        shrine.name,
                        style: const TextStyle(
                          fontSize: FontSizes.titleMedium,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      GoopText(
                        'Shrine',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Skeuo.collapse(
                            Colors.white,
                          ).withValues(alpha: 0.7),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (shrine.description.isNotEmpty) ...[
              SizedBox(height: 10),
              GoopText(
                shrine.description,
                style: const TextStyle(fontSize: 13.5, height: 1.35),
              ),
            ],
            if (shrine.effect.isNotEmpty) ...[
              SizedBox(height: 10),
              GoopText(
                shrine.effect,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: Skeuo.collapse(Colors.white).withValues(alpha: 0.78),
                ),
              ),
            ],
            if (hasDelta) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  if (shrine.curse != 0)
                    _ShrineDeltaChip(
                      label: 'Curse',
                      value: shrine.curse,
                      color: Skeuo.collapse(Color(0xFFD32F2F)),
                    ),
                  if (shrine.curse != 0 && shrine.coolness != 0)
                    SizedBox(width: 8),
                  if (shrine.coolness != 0)
                    _ShrineDeltaChip(
                      label: 'Coolness',
                      value: shrine.coolness,
                      color: Skeuo.collapse(Color(0xFF29B6F6)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShrineDeltaChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ShrineDeltaChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sign = value > 0 ? '+' : '';
    final txt =
        value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.all(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoopText(
            '$label ',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.75),
            ),
          ),
          GoopText(
            '$sign$txt',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
