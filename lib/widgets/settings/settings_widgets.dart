part of 'settings_tab.dart';

/// Shared card chrome for every settings surface — themed fill, radius,
/// border, and clip so panels/cards never drift into ad-hoc styling.
BoxDecoration _settingsCardDecoration(ThemeFlair flair) {
  return BoxDecoration(
    color: flair.card.withValues(alpha: 0.72),
    borderRadius: BorderRadius.circular(flair.cardRadius),
    border: Border.all(
      color:
          flair.cardBorderColor ?? flair.primary.withValues(alpha: 0.22),
      width: flair.cardBorderWidth > 0 ? flair.cardBorderWidth : 1.0,
    ),
  );
}

/// Small pill used by the header status strip and collapsed panel
/// summaries so contents are glanceable without expanding.
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final ThemeFlair flair;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.flair,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ChipStyle.padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(flair.chipRadius),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: GoopText(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TypeScale.labelSmall.copyWith(
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Section eyebrow + hairline rule. Labels are passed already-uppercase.
class _SettingsSection extends StatelessWidget {
  final String label;
  final ThemeFlair flair;
  final Widget child;

  const _SettingsSection({
    required this.label,
    required this.flair,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoopText(
                label,
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  color: flair.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: Insets.xs),
              Container(
                height: 1,
                color:
                    flair.headerUnderlineColor ??
                    flair.primary.withValues(alpha: 0.22),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.sm),
        child,
      ],
    );
  }
}

/// Collapsible settings panel — icon chip + title + live summary + chevron
/// header over a hairline-divided body.
class _SettingsPanel extends StatefulWidget {
  final String title;
  final IconData icon;
  final ThemeFlair flair;
  final String? summary;
  final Widget child;

  const _SettingsPanel({
    required this.title,
    required this.icon,
    required this.flair,
    required this.child,
    this.summary,
  });

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final flair = widget.flair;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final still = MediaQuery.disableAnimationsOf(context);
    final duration = still ? Duration.zero : Motion.base;
    final accent = flair.primary;

    return Container(
      decoration: _settingsCardDecoration(flair),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Haptics.selection();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.lg,
                vertical: Insets.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(flair.chipRadius),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(widget.icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoopText(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: FontSizes.titleSmall,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: accent.withValues(alpha: 0.92),
                          ),
                        ),
                        if (widget.summary != null) ...[
                          const SizedBox(height: 2),
                          GoopText(
                            widget.summary!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TypeScale.labelSmall.copyWith(
                              color: onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: duration,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                Container(
                  height:
                      flair.dividerThickness > 0
                          ? flair.dividerThickness
                          : 1.0,
                  color:
                      flair.dividerColor ??
                      flair.primary.withValues(alpha: 0.14),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.lg,
                    Insets.md,
                    Insets.lg,
                    Insets.lg,
                  ),
                  child: widget.child,
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState:
                _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
            duration: duration,
          ),
        ],
      ),
    );
  }
}

/// Title + subtitle + trailing control row used for toggles.
class _SettingsToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ThemeFlair flair;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.flair,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoopText(
                title,
                style: const TextStyle(
                  fontSize: FontSizes.bodyMedium,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GoopText(
                subtitle,
                style: TypeScale.bodySmall.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: flair.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Icon chip + title + subtitle + chevron row for navigation/actions.
class _SettingsActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ThemeFlair flair;
  final VoidCallback onTap;

  const _SettingsActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.flair,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(flair.chipRadius),
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(flair.chipRadius),
                  border: Border.all(color: iconColor.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: FontSizes.bodyMedium,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GoopText(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TypeScale.bodySmall.copyWith(
                        color: onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: flair.primary.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card-wrapped [_SettingsActionRow] for standalone section entries.
class _SettingsActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ThemeFlair flair;
  final VoidCallback onTap;

  const _SettingsActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.flair,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _settingsCardDecoration(flair),
      clipBehavior: Clip.antiAlias,
      child: _SettingsActionRow(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        flair: flair,
        onTap: onTap,
      ),
    );
  }
}

/// Danger action row — same anatomy as [_SettingsActionRow] but with a
/// fixed danger accent and heavier press haptic.
class _DangerRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final ThemeFlair flair;
  final VoidCallback onTap;

  const _DangerRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.flair,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(flair.chipRadius),
        onTap: () {
          Haptics.warning();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(flair.chipRadius),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: FontSizes.bodyMedium,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: color,
                      ),
                    ),
                    GoopText(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TypeScale.bodySmall.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Non-interactive orientation strip: version, active theme, run state.
class _SettingsStatusStrip extends StatelessWidget {
  final String version;
  final String themeLabel;
  final String runLabel;
  final Color runColor;
  final ThemeFlair flair;

  const _SettingsStatusStrip({
    required this.version,
    required this.themeLabel,
    required this.runLabel,
    required this.runColor,
    required this.flair,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _settingsCardDecoration(flair),
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.md,
      ),
      child: Wrap(
        spacing: Insets.sm,
        runSpacing: Insets.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _StatusChip(
            label: 'v$version',
            color: flair.secondary,
            flair: flair,
          ),
          _StatusChip(
            label: themeLabel,
            color: flair.primary,
            flair: flair,
          ),
          _StatusChip(label: runLabel, color: runColor, flair: flair),
        ],
      ),
    );
  }
}
