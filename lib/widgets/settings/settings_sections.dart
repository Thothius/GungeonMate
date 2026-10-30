part of 'settings_tab.dart';

// Section builders extracted from _SettingsTabState (Phase A) — same
// library; on-clause gives context/widget/mounted/setState.

mixin _SettingsTabSections on State<SettingsTab> {
  void _confirmEndRun(BuildContext context, RunProvider p);
  Future<void> _confirmResetAppData(BuildContext context);
  (Color, Color, Color, Color) _diceColors(
    CustomDiceType type,
    ThemeFlair flair,
  );

  /// Section label — GENERAL / CUSTOMIZATION / APP group headers.
  Widget _sectionLabel(String text, ThemeFlair flair) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GoopText(
        text,
        style: TextStyle(
          fontSize: FontSizes.labelSmall,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.2,
          color: flair.primary.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  Widget _buildGrid(List<_TileData> tiles) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: tiles.map((t) => _CompactActionTile(data: t)).toList(),
    );
  }

  Widget _buildDicePanel(ThemeFlair flair, VisualPrefs prefs) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      color: flair.card.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radii.md),
        side: BorderSide(color: flair.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            SwipePicker<CustomDiceType>(
              items: CustomDiceType.values,
              value: prefs.customDiceType,
              onChanged: (t) => VisualPrefs.setCustomDiceType(t),
              height: 56,
              itemBuilder:
                  (type, isSelected) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? flair.card.withValues(alpha: 0.9)
                              : flair.card.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color:
                              isSelected
                                  ? onSurface
                                  : onSurface.withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: _dicePreview(type: prefs.customDiceType, flair: flair),
            ),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.$2, width: 3),
        boxShadow: [
          BoxShadow(color: colors.$4, blurRadius: 12, spreadRadius: 3),
        ],
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w900,
          color: colors.$3,
        ),
      ),
    );
  }

  /// Full-width, prominent End Run button styled with the Lord of the
  /// Jammed sprite and red-accent danger styling.
  Widget _buildEndRunButton(BuildContext context, RunProvider p) {
    return GestureDetector(
      onTap: () => _confirmEndRun(context, p),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.red.shade900.withValues(alpha: 0.25),
          borderRadius: BorderRadius.all(Radii.md),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.4),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Image.asset(
              'assets/images/end_run/Lord_of_the_Jammed.webp',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              cacheWidth: 72,
              cacheHeight: 72,
              errorBuilder:
                  (_, __, ___) => const Icon(
                    Icons.cancel_presentation_rounded,
                    size: 28,
                    color: Colors.redAccent,
                  ),
            ),
            const SizedBox(width: 12),
            const GoopText(
              'END RUN',
              style: TextStyle(
                fontSize: FontSizes.titleSmall,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.redAccent,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  /// Full-width Reset All Data button with deep-orange danger styling.
  Widget _buildResetDataButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmResetAppData(context),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.deepOrange.withValues(alpha: 0.18),
          borderRadius: const BorderRadius.all(Radii.md),
          border: Border.all(
            color: Colors.deepOrange.withValues(alpha: 0.45),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withValues(alpha: 0.08),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.restart_alt, size: 28, color: Colors.deepOrange),
            const SizedBox(width: 12),
            const GoopText(
              'RESET DATA',
              style: TextStyle(
                fontSize: FontSizes.titleSmall,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.deepOrange,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Colors.deepOrange,
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMpStatusBar(
    BuildContext context,
    RunProvider p,
    bool hasCoop,
    String player2Name,
    bool mpActive,
  ) {
    final iconColor =
        mpActive
            ? Colors.greenAccent
            : (hasCoop
                ? Colors.pinkAccent
                : Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5));
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withValues(alpha: 0.12),
            iconColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            mpActive
                ? Icons.wifi_rounded
                : (hasCoop ? Icons.people_alt_rounded : Icons.person_rounded),
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GoopText(
              mpActive
                  ? 'MP ACTIVE'
                  : (hasCoop ? 'P2 ACTIVE: $player2Name' : 'SOLO'),
              style: TextStyle(
                fontSize: FontSizes.bodyMedium,
                fontWeight: FontWeight.w800,
                color: iconColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
