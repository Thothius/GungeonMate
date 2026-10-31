part of '../shrine_picker_screen.dart';

/// Modal bottom sheet opened when the user taps a shrine card. Shows
/// full detail + a big "Use Shrine" button.
class ShrineActivationSheet extends StatelessWidget {
  final Shrine shrine;
  final BuildContext parentContext;
  const ShrineActivationSheet({
    super.key,
    required this.shrine,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RunProvider>();
    final name = shrine.name.toLowerCase();
    final currentCurse = provider.runState.totalCurse;
    final heroBlocked = name == 'hero' && currentCurse >= 9;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder:
          (c, ctrl) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    children: [
                      // Centered Large Image
                      Center(
                        child: Hero(
                          tag: 'shrine_${shrine.name}',
                          child: Container(
                            padding: const EdgeInsets.all(Insets.md),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.all(Radii.lg),
                              border: Border.all(
                                color: Skeuo.inkIf(
                                  Colors.amber,
                                ).withValues(alpha: 0.1),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              height: 160,
                              width: 160,
                              child:
                                  resolveShrineIcon(
                                        shrine.name,
                                        shrine.icon,
                                      ).startsWith('assets/')
                                      ? Image.asset(
                                        resolveShrineIcon(
                                          shrine.name,
                                          shrine.icon,
                                        ),
                                        fit: BoxFit.contain,
                                        filterQuality:
                                            FilterQuality.none, // Pixel art!
                                        cacheWidth: 320,
                                        cacheHeight: 320,
                                        errorBuilder:
                                            (_, _, _) => Icon(
                                              Icons.temple_buddhist_outlined,
                                              size: 64,
                                              color: Skeuo.inkIf(Colors.amber),
                                            ),
                                      )
                                      : resolveShrineIcon(
                                        shrine.name,
                                        shrine.icon,
                                      ).startsWith('http')
                                      ? Image.network(
                                        resolveShrineIcon(
                                          shrine.name,
                                          shrine.icon,
                                        ),
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.none,
                                        errorBuilder:
                                            (_, _, _) => Icon(
                                              Icons.temple_buddhist_outlined,
                                              size: 64,
                                              color: Skeuo.inkIf(Colors.amber),
                                            ),
                                      )
                                      : Icon(
                                        Icons.temple_buddhist_outlined,
                                        size: 64,
                                        color: Skeuo.inkIf(Colors.amber),
                                      ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Centered Title
                      Center(
                        child: GoopText(
                          shrine.name,
                          style: const TextStyle(
                            fontSize: FontSizes.headlineSmall,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Lore line under the title (the in-game prayer quote
                      // is dropped — it adds nothing at pick time).
                      if (shrine.description.isNotEmpty)
                        Center(
                          child: GoopText(
                            shrine.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      // Health Cost Alert — same shrines the list tile flags.
                      if (name.contains('angel') ||
                          name.contains('blood') ||
                          name.contains('companion')) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Skeuo.inkIf(
                              Colors.red,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.all(Radii.sm),
                            border: Border.all(
                              color: Skeuo.inkIf(
                                Colors.redAccent,
                              ).withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Skeuo.inkIf(
                                  Colors.red,
                                ).withValues(alpha: 0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.heart_broken_rounded,
                                color: Skeuo.inkIf(Colors.redAccent),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              GoopText(
                                '💔 PENALTY COST: -1 HEART CONTAINER (LIFE -1)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: Skeuo.inkIf(Colors.redAccent),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const _SectionHeader(
                        icon: Icons.auto_awesome,
                        title: 'EFFECT',
                      ),
                      const SizedBox(height: 10),
                      _buildEffectBody(shrine),
                      const SizedBox(height: 16),
                      _WillApplyCard(
                        shrine: shrine,
                        currentCurse: currentCurse,
                      ),
                      if (heroBlocked) ...[
                        const SizedBox(height: 12),
                        _BlockedNotice(
                          message:
                              'Hero shrine cannot be used while curse ≥ 9 (currently ${currentCurse.toStringAsFixed(1)}).',
                        ),
                      ],
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const GoopText('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed:
                              heroBlocked
                                  ? null
                                  : () {
                                    final result = provider.applyShrine(shrine);
                                    Navigator.pop(context);
                                    _showShrineResult(parentContext, result);
                                  },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Skeuo.inkIf(Colors.amber),
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.bolt, size: 20),
                          label: GoopText(
                            shrine.hasAutoEffect
                                ? 'Use Shrine'
                                : 'Mark as Used',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Skeuo.inkIf(Colors.amber)),
        const SizedBox(width: 6),
        GoopText(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Skeuo.inkIf(Colors.amber),
          ),
        ),
      ],
    );
  }
}

class _WillApplyCard extends StatelessWidget {
  final Shrine shrine;
  final double currentCurse;
  const _WillApplyCard({required this.shrine, required this.currentCurse});

  @override
  Widget build(BuildContext context) {
    final name = shrine.name.toLowerCase();
    final auto = <({String label, Color color, IconData icon})>[];

    if (name == 'cleanse') {
      auto.add((
        label: 'Curse → 0   (Δ ${(-currentCurse).toStringAsFixed(1)})',
        color: Skeuo.inkIf(Colors.lightGreenAccent),
        icon: Icons.water_drop,
      ));
    } else if (name == 'hero') {
      if (currentCurse < 9) {
        auto.add((
          label: 'Curse → 9   (Δ +${(9 - currentCurse).toStringAsFixed(1)})',
          color: Skeuo.inkIf(Colors.deepOrangeAccent),
          icon: Icons.warning_amber,
        ));
      }
    } else {
      if (shrine.curse != 0) {
        auto.add((
          label:
              'Curse ${shrine.curse > 0 ? '+' : ''}${shrine.curse.toStringAsFixed(1)}',
          color: Skeuo.inkIf(Colors.deepOrangeAccent),
          icon: Icons.warning_amber,
        ));
      }
      if (shrine.coolness != 0) {
        auto.add((
          label:
              'Coolness ${shrine.coolness > 0 ? '+' : ''}${shrine.coolness.toStringAsFixed(1)}',
          color: Skeuo.inkIf(Colors.lightBlueAccent),
          icon: Icons.ac_unit,
        ));
      }
    }

    return Card(
      color: Skeuo.inkIf(Colors.amber).withValues(alpha: 0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Skeuo.inkIf(Colors.amber).withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(icon: Icons.bolt, title: 'WILL BE APPLIED'),
            const SizedBox(height: 8),
            if (auto.isEmpty)
              GoopText(
                'No automatic stat changes — marks the shrine as used in your log.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final a in auto)
                    _AutoRow(label: a.label, color: a.color, icon: a.icon),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AutoRow extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _AutoRow({
    required this.label,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          GoopText(
            label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BlockedNotice extends StatelessWidget {
  final String message;
  const _BlockedNotice({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Skeuo.inkIf(Colors.red).withValues(alpha: 0.08),
        borderRadius: BorderRadius.all(Radii.sm),
        border: Border.all(
          color: Skeuo.inkIf(Colors.red).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.block, color: Skeuo.inkIf(Colors.redAccent), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: GoopText(
              message,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildEffectBody(Shrine shrine) {
  if (shrine.name.toLowerCase() == 'dice') {
    return _diceEffectBody(effect: shrine.effect);
  }
  return _genericEffectBody(effect: shrine.effect);
}

Widget _genericEffectBody({required String effect}) {
  final sentences =
      effect
          .split('. ')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

  if (sentences.isEmpty) return const SizedBox.shrink();

  for (var i = 0; i < sentences.length; i++) {
    if (!sentences[i].endsWith('.') &&
        !sentences[i].endsWith('!') &&
        !sentences[i].endsWith('?')) {
      sentences[i] = '${sentences[i]}.';
    }
  }

  final main = sentences.first;
  final rest = sentences.length > 1 ? sentences.sublist(1) : <String>[];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: Skeuo.inkIf(Colors.amber).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Skeuo.inkIf(Colors.amber).withValues(alpha: 0.3),
          ),
        ),
        child: GoopText(
          main,
          style: const TextStyle(
            fontSize: FontSizes.bodyMedium,
            fontWeight: FontWeight.w800,
            height: 1.35,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 10),
      for (final s in rest)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Insets.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•  ',
                style: TextStyle(
                  color: Skeuo.inkIf(Colors.amber),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Text(
                  s,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

const _diceEffectNames = [
  'Renewed',
  'Pained',
  'Bolstered',
  'Enfeebled',
  'Paid',
  'Robbed',
  'Cleansed',
  'Cursed',
  'Blanked',
  'De-Blanked',
  'Gift',
  'Disarmed',
  'Reloaded',
  'Limited',
  'Hasted',
  'Unsteady',
  'Shielded',
  'Priceless',
];

Widget _diceEffectBody({required String effect}) {
  var text = effect;
  if (text.startsWith('Good Effects Bad Effects ')) {
    text = text.substring('Good Effects Bad Effects '.length);
  }

  final pattern = _diceEffectNames.map(RegExp.escape).join('|');
  final re = RegExp(
    r'(' + pattern + r')(.*?)(?=(' + pattern + r')|$)',
    dotAll: true,
  );
  final matches = re.allMatches(text).toList();
  final lastEnd = matches.isNotEmpty ? matches.last.end : 0;
  final tail = text.substring(lastEnd).trim();
  final notes =
      tail.split('. ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  for (var i = 0; i < notes.length; i++) {
    if (!notes[i].endsWith('.') &&
        !notes[i].endsWith('!') &&
        !notes[i].endsWith('?')) {
      notes[i] = '${notes[i]}.';
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const GoopText(
        'One positive and one negative effect:',
        style: TextStyle(
          fontSize: FontSizes.bodyMedium,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 10),
      for (var i = 0; i < matches.length; i++) ...[
        _DiceEffectCard(
          name: matches[i].group(1)!,
          body: matches[i].group(2)!.trim(),
          isGood: i.isEven,
        ),
        const SizedBox(height: 6),
      ],
      if (notes.isNotEmpty) ...[
        const _SectionHeader(icon: Icons.info_outline, title: 'NOTES'),
        const SizedBox(height: 6),
        for (final n in notes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: TextStyle(
                    color: Skeuo.inkIf(Colors.amber),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Expanded(
                  child: Text(
                    n,
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
      ],
    ],
  );
}

class _DiceEffectCard extends StatelessWidget {
  final String name;
  final String body;
  final bool isGood;
  const _DiceEffectCard({
    required this.name,
    required this.body,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isGood
            ? Skeuo.inkIf(Colors.lightGreenAccent)
            : Skeuo.inkIf(Colors.redAccent);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.all(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(fontSize: 13, height: 1.35)),
        ],
      ),
    );
  }
}
