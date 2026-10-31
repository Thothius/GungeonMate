import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'character_select_screen.dart';
import 'mp_lobby_screen.dart';
import 'experience_studio_screen.dart';
import 'ammonomicon_screen.dart';
import '../services/haptics.dart';
import '../widgets/scale_button.dart';
import '../services/goop_talk_engine.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import '../utils/asset_paths.dart' show kAppVersion;
import '../widgets/home/home_backdrop.dart';

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

class _MainMenuScreenState extends State<MainMenuScreen> {
  // Fixed home palette — never theme-driven.
  static const Color _panel = Color(0xB31A1526); // charcoal glass
  static const Color _inkOnSolid = Color(0xFF1C1C1E);
  static const Color _amber = MainMenuBackdrop.ember;
  static const Color _gold = MainMenuBackdrop.emberGold;

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final sideInset = MediaQuery.sizeOf(context).width * 0.06;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fixed pixel-dungeon backdrop — opaque, owns the whole vibe.
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
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Padding(
                              padding: const EdgeInsets.all(Insets.xl),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // ── Logo + subtitle ──
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
                                                  ..style = PaintingStyle.stroke
                                                  ..strokeWidth = 7
                                                  ..color = const Color(
                                                    0xFFC62828,
                                                  ),
                                          ),
                                        ),
                                        const GoopText(
                                          'GUNGEON MATE',
                                          style: TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2.0,
                                            color: _gold,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(0, 3),
                                                blurRadius: 4,
                                                color: Colors.black54,
                                              ),
                                              Shadow(
                                                offset: Offset(0, 0),
                                                blurRadius: 18,
                                                color: Color(0x66FFB84D),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Sublabel pill — fixed ember accent.
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _amber.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _amber.withValues(alpha: 0.55),
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
                                    child: Column(
                                      children: [
                                        // Local Run — solid hero button.
                                        _menuButton(
                                          icon: Icons.play_arrow_rounded,
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
                                        ).animate(delay: 80.ms).fadeIn(
                                          duration: 350.ms).slideY(
                                          begin: 0.15,
                                          duration: 350.ms,
                                          curve: Curves.easeOut,
                                        ),
                                        const SizedBox(height: 10),
                                        _menuButton(
                                          icon: Icons.bluetooth_searching,
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
                                        ).animate(delay: 160.ms).fadeIn(
                                          duration: 350.ms).slideY(
                                          begin: 0.15,
                                          duration: 350.ms,
                                          curve: Curves.easeOut,
                                        ),
                                        const SizedBox(height: 14),
                                        _menuButton(
                                          icon: Icons.palette_rounded,
                                          label: 'Theme',
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
                                        ).animate(delay: 240.ms).fadeIn(
                                          duration: 350.ms).slideY(
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
                                        ).animate(delay: 320.ms).fadeIn(
                                          duration: 350.ms).slideY(
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
