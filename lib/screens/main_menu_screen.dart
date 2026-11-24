import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../services/mp/mp_link.dart' show isMpSupported;
import '../services/run_lifecycle.dart';
import 'character_select_screen.dart';
import 'mp_lobby_screen.dart';
import 'experience_studio_screen.dart';
import 'ammonomicon_screen.dart';

import '../services/app_theme.dart';
import '../services/haptics.dart';
import '../utils/contrast.dart';
import '../widgets/scale_button.dart';
import '../services/goop_talk_engine.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import '../utils/asset_paths.dart' show kAppVersion;
import '../widgets/home/home_backdrop.dart';

import '../widgets/theme_overlay.dart';

/// Opening screen. App title, subtitle, and primary action buttons.
///
/// PALETTE-DRIVEN BY DESIGN: every color on this screen derives from
/// the active [AppTheme.flair] — switching themes, Unicorn palettes,
/// remixes, or custom presets re-skins the menu in the same frame.
/// [MainMenuBackdrop] follows the same palette for its gradient,
/// embers, and glow.
class MainMenuScreen extends StatefulWidget {
  /// Non-null when a launch-restored run is parked and the menu should
  /// offer Continue — HomeScreen passes the flip-to-run-tabs callback.
  final VoidCallback? onContinueRun;

  const MainMenuScreen({super.key, this.onContinueRun});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with RouteAware {
  Route<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    // Menu mounted = on top (it only exists as the no-run home state).
    ThemeOverlay.menuOnTop.value = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      if (_route != null) menuRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) menuRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    if (_route != null) menuRouteObserver.unsubscribe(this);
    super.dispose();
  }

  // A route was pushed above the menu → unlock theme layers there.
  @override
  void didPushNext() => ThemeOverlay.menuOnTop.value = false;

  // The route above the menu popped → menu is topmost again → re-lock.
  @override
  void didPopNext() => ThemeOverlay.menuOnTop.value = true;

  // Palette-derived colors — resolved from the active theme's flair
  // on every build (the AnimatedBuilder on AppTheme.notifier rebuilds
  // this screen on any theme/palette/remix change).
  ThemeFlair get _flair => AppTheme.flair;

  /// Primary accent — borders, icons, glows (was fixed ember).
  Color get _accent => _flair.primary;

  /// Bright accent for text and the logo fill (was fixed gold).
  Color get _accentHi => _flair.headlineStat;

  /// Secondary accent — logo stroke, gradient end.
  Color get _accent2 => _flair.secondary;

  /// Text/icon color that stays readable on [_accent] fills.
  Color get _onAccent =>
      Contrast.luminance(_accent) > 0.35
          ? const Color(0xFF1C1C1E)
          : Colors.white;

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final sideInset = MediaQuery.sizeOf(context).width * 0.06;
    // Continue Run offer — only when HomeScreen parked a restored run.
    final p = context.watch<RunProvider>();
    final showContinue =
        widget.onContinueRun != null &&
        p.runRestoredFromSave &&
        p.runState.selectedCharacter != null;

    return AnimatedBuilder(
      animation: AppTheme.notifier,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Fixed backdrop — pixel dungeon.
              const MainMenuBackdrop(),
              Positioned.fill(
                child: SafeArea(
                  child: LayoutBuilder(
                    builder:
                        (context, constraints) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(Insets.xl),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // ── Logo + subtitle — same side
                                      // inset as the button column so
                                      // the whole screen shares one
                                      // alignment grid.
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: sideInset,
                                        ),
                                        child: Column(
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            GoopText(
                                              'GUNGEON MATE',
                                              style: TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2.0,
                                                foreground:
                                                    Paint()
                                                      ..style =
                                                          PaintingStyle.stroke
                                                      ..strokeWidth = 7
                                                      ..color = _accent2,
                                              ),
                                            ),
                                            GoopText(
                                              'GUNGEON MATE',
                                              style: TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2.0,
                                                color: _accentHi,
                                                shadows: [
                                                  const Shadow(
                                                    offset: Offset(0, 3),
                                                    blurRadius: 4,
                                                    color: Colors.black54,
                                                  ),
                                                  Shadow(
                                                    offset: const Offset(0, 0),
                                                    blurRadius: 18,
                                                    color: _accent.withValues(
                                                      alpha: 0.4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Sublabel pill — accent chip.
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _accent.withValues(
                                            alpha: 0.10,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: _accent.withValues(
                                              alpha: 0.55,
                                            ),
                                            width: 1.4,
                                          ),
                                        ),
                                        child: GoopText(
                                          'YOUR COMPANION IN THE GUNGEON',
                                          style: TextStyle(
                                            fontSize: FontSizes.labelMedium,
                                            fontWeight: FontWeight.w900,
                                            color: _accentHi,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                      ],
                                    ),
                                  ),
                                      const SizedBox(height: 28),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: sideInset,
                                        ),
                                        child: Column(
                                          children: [
                                            // Continue Run — parked
                                            // launch-restored save.
                                            if (showContinue)
                                              _continueCard(p, sf)
                                                  .animate(delay: 40.ms)
                                                  .fadeIn(duration: 350.ms)
                                                  .slideY(
                                                    begin: 0.15,
                                                    duration: 350.ms,
                                                    curve: Curves.easeOut,
                                                  ),
                                            if (showContinue)
                                              const SizedBox(height: 10),
                                            // Local Run — solid hero
                                            // button (ghost while a
                                            // Continue offer is up so
                                            // only one hero shows).
                                            _menuButton(
                                                  icon:
                                                      Icons.play_arrow_rounded,
                                                  label: 'Local Run',
                                                  solid: !showContinue,
                                                  sf: sf,
                                                  onTap: () {
                                                    Haptics.selection();
                                                    Navigator.push(
                                                      context,
                                                      fastRoute(
                                                        const CharacterSelectScreen(),
                                                      ),
                                                    );
                                                  },
                                                )
                                                .animate(delay: 80.ms)
                                                .fadeIn(duration: 350.ms)
                                                .slideY(
                                                  begin: 0.15,
                                                  duration: 350.ms,
                                                  curve: Curves.easeOut,
                                                ),
                                            const SizedBox(height: 10),
                                            _menuButton(
                                                  icon:
                                                      Icons.bluetooth_searching,
                                                  label: 'Multiplayer',
                                                  // MP-1: transport is Android-only —
                                                  // disabled + hint elsewhere.
                                                  subtitle:
                                                      isMpSupported
                                                          ? null
                                                          : 'ANDROID ONLY',
                                                  sf: sf,
                                                  onTap:
                                                      isMpSupported
                                                          ? () {
                                                            Haptics.selection();
                                                            Navigator.push(
                                                              context,
                                                              fastRoute(
                                                                const MpLobbyScreen(),
                                                              ),
                                                            );
                                                          }
                                                          : null,
                                                )
                                                .animate(delay: 160.ms)
                                                .fadeIn(duration: 350.ms)
                                                .slideY(
                                                  begin: 0.15,
                                                  duration: 350.ms,
                                                  curve: Curves.easeOut,
                                                ),
                                            const SizedBox(height: 14),
                                            _menuButton(
                                                  icon: Icons.palette_rounded,
                                                  label: 'Customization',
                                                  sf: sf,
                                                  onTap: () {
                                                    Haptics.selection();
                                                    Navigator.push(
                                                      context,
                                                      fastRoute(
                                                        const ExperienceStudioScreen(),
                                                      ),
                                                    );
                                                  },
                                                )
                                                .animate(delay: 240.ms)
                                                .fadeIn(duration: 350.ms)
                                                .slideY(
                                                  begin: 0.15,
                                                  duration: 350.ms,
                                                  curve: Curves.easeOut,
                                                ),
                                            const SizedBox(height: 10),
                                            _menuButton(
                                                  icon: Icons.menu_book_rounded,
                                                  label: 'Ammonomicon',
                                                  sf: sf,
                                                  onTap: () {
                                                    Haptics.selection();
                                                    Navigator.push(
                                                      context,
                                                      fastRoute(
                                                        const AmmonomiconScreen(
                                                          showBackButton: true,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                                .animate(delay: 320.ms)
                                                .fadeIn(duration: 350.ms)
                                                .slideY(
                                                  begin: 0.15,
                                                  duration: 350.ms,
                                                  curve: Curves.easeOut,
                                                ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      GoopText(
                                        'v$kAppVersion',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Continue Run card — shown when a launch-restored save is parked.
  /// Hero CONTINUE resumes the run; a quiet END RUN routes through the
  /// same Lord-of-the-Jammed confirm as everywhere else.
  Widget _continueCard(RunProvider p, double sf) {
    final run = p.runState;
    final char = run.selectedCharacter!;
    final guns = run.main.guns.length;
    final items = run.main.items.length;
    final summary =
        '${char.name} — $guns gun${guns == 1 ? '' : 's'} · '
        '$items item${items == 1 ? '' : 's'}'
        '${run.hasCoop ? ' · CO-OP' : ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoopText(
          'SAVED RUN',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: FontSizes.labelSmall,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: _accent.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        GoopText(
          summary,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: FontSizes.labelMedium,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 10),
        _menuButton(
          icon: Icons.play_circle_rounded,
          label: 'Continue Run',
          solid: true,
          sf: sf,
          onTap: () {
            Haptics.success();
            widget.onContinueRun!();
          },
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: () {
              Haptics.selection();
              RunLifecycle.confirmEndRun(context);
            },
            child: GoopText(
              'END SAVED RUN',
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Menu button — translucent theme panel with an accent
  /// border/icon, or a gradient accent hero when [solid] is set.
  Widget _menuButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required double sf,
    bool solid = false,
    String? subtitle,
  }) {
    final fg = solid ? _onAccent : Colors.white;
    final borderWidth = solid ? 1.6 : 1.8;
    final borderAlpha = solid ? 0.9 : 0.55;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          // ~15% smaller than the original 62px hero rows.
          height: 53 * sf,
          decoration: BoxDecoration(
            // Ghost = faint accent wash; hero = solid accent fill.
            // (DESIGN.md §components — palette-driven menu spec.)
            color: solid ? _accent : null,
            gradient:
                solid
                    ? null
                    : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _accent.withValues(alpha: 0.16),
                        _accent.withValues(alpha: 0.05),
                      ],
                    ),
            borderRadius: const BorderRadius.all(Radii.lg),
            border: Border.all(
              color: _accent.withValues(alpha: borderAlpha),
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: solid ? 0.35 : 0.18),
                blurRadius: solid ? 18 : 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20 * sf, color: solid ? fg : _accent),
              const SizedBox(width: 10),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GoopText(
                        label,
                        style: TextStyle(
                          fontSize: 13.5 * sf,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: fg,
                        ),
                      ),
                      if (subtitle != null)
                        GoopText(
                          subtitle,
                          style: TextStyle(
                            fontSize: 7.2 * sf,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            color: fg.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
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
