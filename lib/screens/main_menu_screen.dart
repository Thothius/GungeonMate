import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'character_select_screen.dart';
import 'mp_lobby_screen.dart';
import 'experience_studio_screen.dart';
import 'ammonomicon_screen.dart';
import 'neo_skeuo_lab_screen.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import '../widgets/scale_button.dart';
import '../services/goop_talk_engine.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import '../utils/asset_paths.dart' show kAppVersion;
import '../widgets/home/home_backdrop.dart';
import '../widgets/skeuo/skeuo_backdrop.dart';
import '../widgets/skeuo/skeuo_surface.dart';
import '../widgets/skeuo/skeuo_tokens.dart';
import '../widgets/theme_overlay.dart';

/// Opening screen. App title, subtitle, and primary action buttons.
///
/// THEME-LOCKED BY DESIGN: this screen reads no `AppTheme` colors —
/// the user-facing menu must look identical on every theme, so the
/// palette below is fixed and shared with [MainMenuBackdrop]. If you
/// restyle it, keep it theme-free.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

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

  // Fixed home palette — never theme-driven.
  static const Color _panel = Color(0xB31A1526); // charcoal glass
  static const Color _inkOnSolid = Color(0xFF1C1C1E);
  static const Color _amber = MainMenuBackdrop.ember;
  static const Color _gold = MainMenuBackdrop.emberGold;

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final sideInset = MediaQuery.sizeOf(context).width * 0.06;

    return AnimatedBuilder(
      animation: AppTheme.notifier,
      builder: (context, _) {
        final skeuo = AppTheme.isSkeuo;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Fixed backdrop — pixel dungeon normally, cream paper
              // while the Neo-Skeuo skin is active.
              if (skeuo)
                const SkeuoPaperBackdrop()
              else
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
                                      // ── Logo + subtitle ──
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child:
                                            skeuo
                                                ? Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    // Cream offset under
                                                    // ink letters — printed
                                                    // letterpress look.
                                                    Transform.translate(
                                                      offset: const Offset(
                                                        3,
                                                        3,
                                                      ),
                                                      child: const GoopText(
                                                        'GUNGEON MATE',
                                                        style: TextStyle(
                                                          fontSize: 48,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          letterSpacing: 2.0,
                                                          color: Skeuo.card,
                                                        ),
                                                      ),
                                                    ),
                                                    const GoopText(
                                                      'GUNGEON MATE',
                                                      style: TextStyle(
                                                        fontSize: 48,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 2.0,
                                                        color: Skeuo.ink,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                : Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    GoopText(
                                                      'GUNGEON MATE',
                                                      style: TextStyle(
                                                        fontSize: 48,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 2.0,
                                                        foreground:
                                                            Paint()
                                                              ..style =
                                                                  PaintingStyle
                                                                      .stroke
                                                              ..strokeWidth = 7
                                                              ..color =
                                                                  const Color(
                                                                    0xFFC62828,
                                                                  ),
                                                      ),
                                                    ),
                                                    const GoopText(
                                                      'GUNGEON MATE',
                                                      style: TextStyle(
                                                        fontSize: 48,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 2.0,
                                                        color: _gold,
                                                        shadows: [
                                                          Shadow(
                                                            offset: Offset(
                                                              0,
                                                              3,
                                                            ),
                                                            blurRadius: 4,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                          Shadow(
                                                            offset: Offset(
                                                              0,
                                                              0,
                                                            ),
                                                            blurRadius: 18,
                                                            color: Color(
                                                              0x66FFB84D,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Sublabel pill — ember chip, or an
                                      // ink-bordered paper chip in skeuo.
                                      if (skeuo)
                                        const SkeuoSurface(
                                          elevation: SkeuoElevation.base,
                                          radius: Skeuo.rSm,
                                          sketchy: false,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 5,
                                          ),
                                          child: GoopText(
                                            'YOUR COMPANION IN THE GUNGEON',
                                            style: TextStyle(
                                              fontSize: FontSizes.labelMedium,
                                              fontWeight: FontWeight.w900,
                                              color: Skeuo.ink,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _amber.withValues(
                                              alpha: 0.10,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: _amber.withValues(
                                                alpha: 0.55,
                                              ),
                                              width: 1.4,
                                            ),
                                          ),
                                          child: const GoopText(
                                            'YOUR COMPANION IN THE GUNGEON',
                                            style: TextStyle(
                                              fontSize: FontSizes.labelMedium,
                                              fontWeight: FontWeight.w900,
                                              color: _gold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 28),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: sideInset,
                                        ),
                                        child:
                                            skeuo
                                                ? _skeuoMenuButtons(context)
                                                : Column(
                                                  children: [
                                                    // Local Run — solid hero button.
                                                    _menuButton(
                                                          icon:
                                                              Icons
                                                                  .play_arrow_rounded,
                                                          label: 'Local Run',
                                                          solid: true,
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
                                                        .fadeIn(
                                                          duration: 350.ms,
                                                        )
                                                        .slideY(
                                                          begin: 0.15,
                                                          duration: 350.ms,
                                                          curve: Curves.easeOut,
                                                        ),
                                                    const SizedBox(height: 10),
                                                    _menuButton(
                                                          icon:
                                                              Icons
                                                                  .bluetooth_searching,
                                                          label: 'Multiplayer',
                                                          sf: sf,
                                                          onTap: () {
                                                            Haptics.selection();
                                                            Navigator.push(
                                                              context,
                                                              fastRoute(
                                                                const MpLobbyScreen(),
                                                              ),
                                                            );
                                                          },
                                                        )
                                                        .animate(delay: 160.ms)
                                                        .fadeIn(
                                                          duration: 350.ms,
                                                        )
                                                        .slideY(
                                                          begin: 0.15,
                                                          duration: 350.ms,
                                                          curve: Curves.easeOut,
                                                        ),
                                                    const SizedBox(height: 14),
                                                    _menuButton(
                                                          icon:
                                                              Icons
                                                                  .palette_rounded,
                                                          label:
                                                              'Customization',
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
                                                        .fadeIn(
                                                          duration: 350.ms,
                                                        )
                                                        .slideY(
                                                          begin: 0.15,
                                                          duration: 350.ms,
                                                          curve: Curves.easeOut,
                                                        ),
                                                    const SizedBox(height: 10),
                                                    _menuButton(
                                                          icon:
                                                              Icons
                                                                  .menu_book_rounded,
                                                          label: 'Ammonomicon',
                                                          sf: sf,
                                                          onTap: () {
                                                            Haptics.selection();
                                                            Navigator.push(
                                                              context,
                                                              fastRoute(
                                                                const AmmonomiconScreen(
                                                                  showBackButton:
                                                                      true,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        )
                                                        .animate(delay: 320.ms)
                                                        .fadeIn(
                                                          duration: 350.ms,
                                                        )
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
                                          color:
                                              skeuo
                                                  ? Skeuo.pencil
                                                  : Colors.white.withValues(
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
              // Neo-Skeuo toggle — always top-right; a ghost pencil on the
              // locked menu, a pressed ink chip while the skin is active.
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.md),
                    child: _skeuoToggleChip(skeuo),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Skeuo menu — Local Run as the ink hero, the rest as paper
  /// outlines. DEMO showcases the kit; Customization sits locked.
  Widget _skeuoMenuButtons(BuildContext context) {
    return Column(
      children: [
        SkeuoButton.primary(
          label: 'Local Run',
          icon: Icons.play_arrow_rounded,
          drawDelay: const Duration(milliseconds: 60),
          onTap: () {
            Navigator.push(context, fastRoute(const CharacterSelectScreen()));
          },
        ),
        const SizedBox(height: 10),
        SkeuoButton(
          label: 'Multiplayer',
          icon: Icons.bluetooth_searching,
          drawDelay: const Duration(milliseconds: 150),
          onTap: () {
            Navigator.push(context, fastRoute(const MpLobbyScreen()));
          },
        ),
        const SizedBox(height: 10),
        SkeuoButton(
          label: 'Style Demo',
          icon: Icons.auto_stories_rounded,
          drawDelay: const Duration(milliseconds: 240),
          onTap: () {
            Navigator.push(context, fastRoute(const NeoSkeuoLabScreen()));
          },
        ),
        const SizedBox(height: 10),
        const Tooltip(
          message: 'Locked while Neo-Skeuo is on',
          child: SkeuoButton.disabled(
            label: 'Customization',
            icon: Icons.lock_outline_rounded,
            drawDelay: Duration(milliseconds: 330),
          ),
        ),
        const SizedBox(height: 10),
        SkeuoButton(
          label: 'Ammonomicon',
          icon: Icons.menu_book_rounded,
          drawDelay: const Duration(milliseconds: 420),
          onTap: () {
            Navigator.push(
              context,
              fastRoute(const AmmonomiconScreen(showBackButton: true)),
            );
          },
        ),
      ],
    );
  }

  /// The Neo-Skeuo mode toggle — ghost pencil chip on the ember menu,
  /// pressed ink chip while the skin is on.
  Widget _skeuoToggleChip(bool active) {
    return Tooltip(
      message: active ? 'Exit Neo-Skeuo' : 'Neo-Skeuo theme',
      child: ScaleButton(
        onTap: () {
          if (active) {
            AppTheme.exitSkeuo();
          } else {
            AppTheme.enterSkeuo();
          }
        },
        child:
            active
                ? const SkeuoSurface(
                  elevation: SkeuoElevation.pressed,
                  radius: Skeuo.rLg,
                  sketchy: false,
                  padding: EdgeInsets.all(11),
                  child: Icon(Icons.draw_rounded, size: 22, color: Skeuo.ink),
                )
                : Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _panel,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _amber.withValues(alpha: 0.5),
                      width: 1.4,
                    ),
                  ),
                  child: const Icon(
                    Icons.draw_rounded,
                    size: 22,
                    color: _amber,
                  ),
                ),
      ),
    );
  }

  /// Locked menu button — translucent charcoal panel with a warm
  /// ember border/icon, or a solid amber hero when [solid] is set.
  Widget _menuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double sf,
    bool solid = false,
  }) {
    final fg = solid ? _inkOnSolid : Colors.white;
    final border =
        solid ? _amber.withValues(alpha: 0.9) : _amber.withValues(alpha: 0.5);
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 62 * sf,
        decoration: BoxDecoration(
          gradient:
              solid
                  ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFC966), _amber],
                  )
                  : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_panel, Color(0x991A1526)],
                  ),
          borderRadius: const BorderRadius.all(Radii.lg),
          border: Border.all(color: border, width: 1.6),
          boxShadow: [
            BoxShadow(
              color:
                  solid
                      ? _amber.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.35),
              blurRadius: solid ? 18 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24 * sf, color: solid ? fg : _amber),
            const SizedBox(width: 10),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: GoopText(
                  label,
                  style: TextStyle(
                    fontSize: 16 * sf,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: fg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
