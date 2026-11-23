part of 'settings_tab.dart';

// Section builders extracted from _SettingsTabState — same library;
// on-clause gives context/widget/mounted/setState.

mixin _SettingsTabSections on State<SettingsTab> {
  void _confirmEndRun(BuildContext context, RunProvider p);
  Future<void> _confirmResetAppData(BuildContext context);

  /// Orientation strip: version, active theme, run state.
  Widget _buildStatusStrip(RunProvider p, VisualPrefs prefs) {
    final flair = AppTheme.flair;
    final hasRun = p.runState.main.character != null;
    final hasCoop = p.runState.hasCoop;
    final runLabel = hasCoop
        ? 'CO-OP RUN'
        : hasRun
        ? 'SOLO RUN'
        : 'NO ACTIVE RUN';
    final runColor = hasCoop
        ? Colors.pinkAccent
        : hasRun
        ? Colors.greenAccent
        : Colors.white38;
    return _SettingsStatusStrip(
      version: kAppVersion,
      themeLabel: AppTheme.mode.label,
      runLabel: runLabel,
      runColor: runColor,
      flair: flair,
    );
  }

  /// Dice face palette per [CustomDiceType] — fixed game identity, not
  /// theme chrome.
  (Color, Color, Color, Color) _diceColors(
    CustomDiceType type,
    ThemeFlair flair,
  ) {
    switch (type) {
      case CustomDiceType.classicWhite:
        return (
          const Color(0xFFFAFAFA),
          const Color(0xFF90A4AE),
          const Color(0xFF263238),
          Colors.white24,
        );
      case CustomDiceType.goldGlimmer:
        return (
          const Color(0xFF2C2210),
          const Color(0xFFFFD54F),
          const Color(0xFFFFD54F),
          const Color(0x33FFD54F),
        );
      case CustomDiceType.frostShard:
        return (
          const Color(0xFF101C2C),
          const Color(0xFF00E5FF),
          const Color(0xFF00E5FF),
          const Color(0x3300E5FF),
        );
      case CustomDiceType.moltenAmber:
        return (
          const Color(0xFF2C1010),
          const Color(0xFFFF3D00),
          const Color(0xFFFF3D00),
          const Color(0x33FF3D00),
        );
      case CustomDiceType.voidPurple:
        return (
          const Color(0xFF1F102C),
          const Color(0xFFD500F9),
          const Color(0xFFD500F9),
          const Color(0x33D500F9),
        );
      case CustomDiceType.toxicOoze:
        return (
          const Color(0xFF102C13),
          const Color(0xFF00E676),
          const Color(0xFF00E676),
          const Color(0x3300E676),
        );
      case CustomDiceType.themeDefault:
        return (
          const Color(0xFF161413),
          flair.primary,
          flair.primary,
          flair.primary.withValues(alpha: 0.3),
        );
    }
  }

  /// DICE STYLE panel body — roll shortcut, style picker, live preview.
  Widget _buildDicePanel(ThemeFlair flair, VisualPrefs prefs) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        _SettingsActionRow(
          icon: Icons.casino_outlined,
          iconColor: const Color(0xFFFFD54F),
          title: 'Dice Roll',
          subtitle: 'Roll dice for run buffs',
          flair: flair,
          onTap: () => showDiceRollDialog(context),
        ),
        const SizedBox(height: Insets.md),
        SwipePicker<CustomDiceType>(
          items: CustomDiceType.values,
          value: prefs.customDiceType,
          onChanged: (t) => VisualPrefs.setCustomDiceType(t),
          height: 56,
          itemBuilder:
              (type, isSelected) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.sm,
                  vertical: Insets.sm,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? flair.card.withValues(alpha: 0.9)
                          : flair.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(flair.chipRadius),
                  border: Border.all(
                    color:
                        isSelected
                            ? flair.primary.withValues(alpha: 0.6)
                            : onSurface.withValues(alpha: 0.12),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Center(
                  child: GoopText(
                    type.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TypeScale.labelLarge.copyWith(
                      color:
                          isSelected
                              ? onSurface
                              : onSurface.withValues(alpha: 0.55),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
        ),
        const SizedBox(height: Insets.lg),
        Center(
          child: _dicePreview(type: prefs.customDiceType, flair: flair),
        ),
      ],
    );
  }

  Widget _dicePreview({
    required CustomDiceType type,
    required ThemeFlair flair,
    int value = 5,
  }) {
    final colors = _diceColors(type, flair);
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.all(Radii.lg),
        border: Border.all(color: colors.$2, width: 3),
        boxShadow: [
          BoxShadow(color: colors.$4, blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: GoopText(
        '$value',
        style: TypeScale.displaySmall.copyWith(
          fontWeight: FontWeight.w900,
          color: colors.$3,
        ),
      ),
    );
  }

  /// DANGER ZONE — END RUN (active run only) + RESET ALL DATA.
  Widget _buildDangerZone(
    BuildContext context,
    RunProvider p,
    bool hasRun,
    ThemeFlair flair,
  ) {
    return _SettingsSection(
      label: 'DANGER ZONE',
      flair: flair,
      child: Container(
        decoration: _settingsCardDecoration(flair),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (hasRun) ...[
              _DangerRow(
                icon: Icons.flag_rounded,
                color: Colors.redAccent,
                title: 'END RUN',
                subtitle: 'End the active run and return to the main menu',
                flair: flair,
                onTap: () => _confirmEndRun(context, p),
              ),
              Container(
                height: flair.dividerThickness > 0
                    ? flair.dividerThickness
                    : 1.0,
                color: flair.dividerColor ?? flair.primary.withValues(alpha: 0.14),
              ),
            ],
            _DangerRow(
              icon: Icons.restart_alt_rounded,
              color: Colors.deepOrange,
              title: 'RESET ALL DATA',
              subtitle: 'Erase every saved pref, run, favourite, and theme',
              flair: flair,
              onTap: () => _confirmResetAppData(context),
            ),
          ],
        ),
      ),
    );
  }
}
