part of '../gungeoneer_header.dart';

// Header builders extracted from _GungeoneerHeaderState (Phase A) —
// same library; on-clause gives context/widget/mounted/setState.

mixin _HeaderBuilders on State<GungeoneerHeader> {
  int get _avatarMode;
  String? get _quickComment;
  AnimationController get _borderPulseController;
  AnimationController get _wobbleController;
  void _onAvatarTapped();

  /// Signed stat display — '+2.5' / '−1.0' / '0.0'. Negative coolness/
  /// curse is rare but legal, and '+-1.0' reads broken.
  static String _signedStat(double v) {
    final s = v.toStringAsFixed(1);
    if (v > 0) return '+$s';
    if (v < 0) return '−${s.substring(1)}';
    return s;
  }

  Widget _buildExpanded(BuildContext context) {
    final f = AppTheme.flair;
    final iconPath = widget.character.icon;
    final trailingWidget =
        widget.trailing ??
        (widget.onEndRun != null
            ? IconButton(
              tooltip: 'End run',
              onPressed: widget.onEndRun,
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.white70,
                size: 18,
              ),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(Insets.xs),
            )
            : null);

    // Neutralize the global text scaler so the header layout stays
    // pixel-stable regardless of the theme's font-size setting. The
    // stat capsules use FittedBox, but the avatar/name area doesn't —
    // a 2.28x scale factor would blow up the single-row layout.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _borderPulseController,
            builder: (context, child) {
              final pulse =
                  (math.sin(_borderPulseController.value * 2 * math.pi) + 1) /
                  2;
              final borderAlpha = 0.15 + pulse * 0.25;
              return Container(
                decoration: BoxDecoration(
                  color: f.card,
                  borderRadius: BorderRadius.circular(f.cardRadius),
                  border: Border.all(
                    color: f.primary.withValues(alpha: borderAlpha),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: f.primary.withValues(alpha: borderAlpha * 0.3),
                      blurRadius: 8 + pulse * 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                clipBehavior: Clip.none,
                child: child,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Single row: Avatar + COOL + CURSE + SYN + Gear menu
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        children: [
                          // Clean, flat Avatar (Tappable — cycles through
                          // static icon → in-game GIF → animated card art).
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _onAvatarTapped,
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: _buildAvatarContent(iconPath),
                            ),
                          ),
                          // Robot +DMG cyber overlay — shown when robotDamageBoost > 0.
                          if (widget.robotDamageBoost > 0) ...[
                            const SizedBox(width: 3),
                            _RobotDmgBadge(boost: widget.robotDamageBoost),
                          ],
                          const SizedBox(width: 6),
                          // 4 stat capsules share the remaining space equally
                          Expanded(
                            child: _buildFlatCapsule(
                              color: StatColors.cool,
                              value: _signedStat(widget.coolness),
                              label: 'COOL',
                              tooltip: 'Coolness — tap to adjust',
                              onTap: widget.onTapCoolness,
                              onLongPress: widget.onLongPressCoolness,
                              isCool: true,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildFlatCapsule(
                              color: StatColors.curse,
                              value: _signedStat(widget.curse),
                              label: 'CURSE',
                              tooltip: 'Curse — tap to adjust',
                              onTap: widget.onTapCurse,
                              onLongPress: widget.onLongPressCurse,
                              isCurse: true,
                            ),
                          ),
                          // Pinned dash capsules (STEAL/SHRINE/SYN/DPS)
                          // followed by the "+" picker capsule.
                          for (final cap in widget.dashCapsules) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildDashCapsule(cap),
                            ),
                          ],
                          if (widget.onDashCapsulesEdit != null) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildFlatCapsule(
                                color: Colors.white38,
                                value: '',
                                label: 'ADD',
                                icon: Icons.add,
                                tooltip: 'Customize dash capsules',
                                onTap: widget.onDashCapsulesEdit,
                              ),
                            ),
                          ],
                          if (trailingWidget != null) ...[
                            const SizedBox(width: 6),
                            trailingWidget,
                          ],
                        ],
                      ),
                      if (_quickComment != null)
                        Positioned(
                          top: 42,
                          left: 60,
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Insets.sm,
                                vertical: Insets.xs,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme
                                        .flair
                                        .card, // Solid dark grey background
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: f.primary.withValues(alpha: 0.5),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: GoopText(
                                _quickComment!,
                                style: TextStyle(
                                  fontSize: FontSizes.labelSmall,
                                  fontStyle: FontStyle.italic,
                                  color: f.headlineStat,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Dynamic themed divider/decoration
                Container(
                  height: 1.0,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.05),
                ),

                // EFFECTS STRIP — slim hairline row inside the panel
                // (FUSE/CD/REWARD/JAM/BOSS). Was a padded inner card —
                // user asked for much more compact.
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: RunEffectsBlock(),
                ),
                // Footer slot — tracker pills + inline cool/curse
                // stepper slide out inside the same panel.
                if (widget.footer != null) widget.footer!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(String iconPath) {
    final char = widget.character;
    final fallback = const Icon(Icons.person, size: 28, color: Colors.white54);

    if (_avatarMode == 0) {
      // Static icon
      return iconPath.startsWith('assets/')
          ? Image.asset(
            iconPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
            cacheWidth: 96,
            cacheHeight: 96,
            errorBuilder: (_, _, _) => fallback,
          )
          : fallback;
    }

    if (_avatarMode == 1) {
      // In-game animated GIF
      final gifPath = gungeoneerGifPath(char.name);
      if (gifPath.isNotEmpty) {
        return Image.asset(
          gifPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
          cacheWidth: 96,
          cacheHeight: 96,
          errorBuilder:
              (_, _, _) =>
                  iconPath.startsWith('assets/')
                      ? Image.asset(
                        iconPath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        cacheWidth: 96,
                        cacheHeight: 96,
                        errorBuilder: (_, _, _) => fallback,
                      )
                      : fallback,
        );
      }
      return iconPath.startsWith('assets/')
          ? Image.asset(
            iconPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            cacheWidth: 96,
            cacheHeight: 96,
            errorBuilder: (_, _, _) => fallback,
          )
          : fallback;
    }

    // Animated card art
    final cardPath = gungeoneerAnimatedCardPath(char.name);
    if (cardPath.isNotEmpty) {
      return Image.asset(
        cardPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        cacheWidth: 96,
        cacheHeight: 96,
        errorBuilder:
            (_, _, _) =>
                iconPath.startsWith('assets/')
                    ? Image.asset(
                      iconPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      cacheWidth: 96,
                      cacheHeight: 96,
                      errorBuilder: (_, _, _) => fallback,
                    )
                    : fallback,
      );
    }
    return iconPath.startsWith('assets/')
        ? Image.asset(
          iconPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          cacheWidth: 96,
          cacheHeight: 96,
          errorBuilder: (_, _, _) => fallback,
        )
        : fallback;
  }

  /// One pinned dash capsule — resolves its accent color, live value
  /// and tap target from the [DashCapsule] kind.
  Widget _buildDashCapsule(DashCapsule cap) {
    final spec = cap;
    final (color, value, isActive) = switch (cap) {
      DashCapsule.steal => (spec.color, '', true),
      DashCapsule.useShrine => (spec.color, '', true),
      DashCapsule.syn => (
        widget.activeSynergies > 0 ? spec.color : Colors.white38,
        widget.partialSynergies > 0
            ? '${widget.activeSynergies}|${widget.partialSynergies}'
            : '${widget.activeSynergies}',
        widget.activeSynergies > 0,
      ),
      DashCapsule.dps => (
        widget.topGunDps > 0 ? spec.color : Colors.white38,
        widget.topGunDps > 0
            ? widget.topGunDps.toStringAsFixed(
                widget.topGunDps >= 100 ? 0 : 1,
              )
            : '—',
        widget.topGunDps > 0,
      ),
    };
    return _buildFlatCapsule(
      color: color,
      value: value,
      label: spec.label,
      icon: cap.isAction ? cap.icon : null,
      tooltip: spec.blurb,
      onTap: () => widget.onDashCapsuleTap?.call(cap),
      isActive: isActive,
    );
  }

  Widget _buildFlatCapsule({
    required Color color,
    required String value,
    required String label,
    IconData? icon,
    String? tooltip,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isActive = true,
    bool isCool = false,
    bool isCurse = false,
  }) {
    final double coolVal = widget.coolness;
    final double curseVal = widget.curse;

    final double coolGlowIntensity =
        (coolVal >= 2) ? (coolVal / 20.0).clamp(0.1, 1.0) : 0.0;
    final double curseGlowIntensity =
        (curseVal >= 2) ? (curseVal / 10.0).clamp(0.1, 1.0) : 0.0;

    // Glow wrapper for value text — replaces the old icon-based glow
    Widget valueText = GoopText(
      value,
      style: TextStyle(
        fontSize: FontSizes.bodyMedium,
        fontWeight: FontWeight.w900,
        color: isActive ? Colors.white : Colors.white38,
        height: 1.1,
      ),
    );

    if (isCool && coolGlowIntensity > 0) {
      valueText = RepaintBoundary(
        child: AnimatedBuilder(
          animation: _wobbleController,
          builder: (context, child) {
            final pulse = math.sin(_wobbleController.value * 2 * math.pi) * 3.0;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: StatColors.cool.withValues(
                      alpha: 0.55 * coolGlowIntensity,
                    ),
                    blurRadius: (8.0 + pulse) * coolGlowIntensity,
                    spreadRadius: (1.5 + pulse * 0.2) * coolGlowIntensity,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: valueText,
        ),
      );
    } else if (isCurse && curseGlowIntensity > 0) {
      valueText = RepaintBoundary(
        child: AnimatedBuilder(
          animation: _wobbleController,
          builder: (context, child) {
            final pulse =
                math.sin(_wobbleController.value * 2 * math.pi * 2) * 2.0;
            final wobbleX =
                math.sin(_wobbleController.value * 2 * math.pi * 4) *
                2.5 *
                curseGlowIntensity;
            final wobbleY =
                math.cos(_wobbleController.value * 2 * math.pi * 3) *
                1.8 *
                curseGlowIntensity;
            final wobbleAngle =
                math.sin(_wobbleController.value * 2 * math.pi * 5) *
                0.14 *
                curseGlowIntensity;

            return Transform.translate(
              offset: Offset(wobbleX, wobbleY),
              child: Transform.rotate(
                angle: wobbleAngle,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: StatColors.curse.withValues(
                          alpha: 0.65 * curseGlowIntensity,
                        ),
                        blurRadius: (8.0 + pulse) * curseGlowIntensity,
                        spreadRadius: (1.2 + pulse * 0.15) * curseGlowIntensity,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: valueText,
        ),
      );
    }

    // Icon-led capsules (actions, "+" picker) swap the numeric value
    // for a glyph; glow wrappers only apply to cool/curse stats.
    final Widget lead =
        icon != null
            ? Icon(icon, size: 18, color: isActive ? color : Colors.white38)
            : valueText;

    final capsule = Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color:
            isActive
                ? color.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isActive
                  ? color.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.10),
          width: 1.0,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            lead,
            const SizedBox(height: 2),
            GoopText(
              label,
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w900,
                color: isActive ? color : Colors.white24,
                letterSpacing: 0.4,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );

    final Widget result;
    if (onTap == null && onLongPress == null) {
      result = capsule;
    } else {
      result = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          onLongPress: onLongPress,
          child: capsule,
        ),
      );
    }
    return tooltip == null ? result : Tooltip(message: tooltip, child: result);
  }
}
