part of '../stats_detail_screen.dart';

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
    child: GoopText(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
        color: Skeuo.collapse(Colors.white).withValues(alpha: 0.65),
      ),
    ),
  );
}

class _EffectRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String subtitle;
  const _EffectRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GoopText(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GoopText(
                    subtitle,
                    style: TextStyle(
                      fontSize: FontSizes.labelMedium,
                      color: Skeuo.collapse(
                        Colors.white,
                      ).withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GoopText(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Skeuo.collapse(Colors.white).withValues(alpha: 0.7),
          ),
          SizedBox(width: 8),
          Expanded(
            child: GoopText(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Skeuo.collapse(Colors.white).withValues(alpha: 0.8),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool isCool;
  const _QuickActions({required this.isCool});

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();

    final actions =
        isCool
            ? [
              _QuickAction(
                icon: runLogCategoryIcon(RunLogCategory.smokeCig),
                label: 'Smoke Cig',
                subtitle: '+1 cool',
                color: runLogCategoryColor(RunLogCategory.smokeCig),
                onTap: p.logSmokeCig,
              ),
              _QuickAction(
                icon: runLogCategoryIcon(RunLogCategory.rainbowRun),
                label: 'Rainbow Run',
                subtitle: '+1 cool',
                color: runLogCategoryColor(RunLogCategory.rainbowRun),
                onTap: p.logRainbowRun,
              ),
            ]
            : [
              _QuickAction(
                icon: runLogCategoryIcon(RunLogCategory.steal),
                label: 'Steal',
                subtitle: '+1 curse',
                color: runLogCategoryColor(RunLogCategory.steal),
                onTap: p.logSteal,
              ),
              _QuickAction(
                icon: runLogCategoryIcon(RunLogCategory.cursula),
                label: 'Cursula',
                subtitle: '+2 curse',
                color: runLogCategoryColor(RunLogCategory.cursula),
                onTap: p.logCursula,
              ),
            ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          isCool ? 'Quick coolness actions' : 'Quick curse actions',
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: actions.map((a) => _QuickActionCard(action: a)).toList(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: GoopText(
            'Things the app can\'t auto-detect — tap to log them.',
            style: TextStyle(
              fontSize: 10.5,
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Haptics.selection();
          action.onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: action.color.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(action.icon, color: action.color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GoopText(
                        action.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GoopText(
                        action.subtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: action.color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
