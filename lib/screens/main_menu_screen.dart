import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'character_select_screen.dart';
import 'mp_lobby_screen.dart';
import 'experience_studio_screen.dart';
import 'quiz/quiz_home_screen.dart';
import 'codex_screen.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import '../widgets/scale_button.dart';
import '../services/goop_talk_engine.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import '../utils/asset_paths.dart' show kAppVersion;

/// Opening screen. App title, subtitle, and primary action buttons —
/// all colored by the active theme's palette (primary tint ghosts +
/// one solid hero), never hardcoded rainbow accents.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final flair = AppTheme.flair;
    // Luminance-checked label color — readable on every palette,
    // including light ones. This is what keeps button labels from
    // going invisible when the theme changes.
    final onBtn =
        flair.scaffold.computeLuminance() > 0.5
            ? const Color(0xFF1C1C1E)
            : Colors.white;
    final sideInset = MediaQuery.sizeOf(context).width * 0.06;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Theme-tinted depth layer over ThemeOverlay's base.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 1.1,
                    colors: [
                      flair.primary.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                                  // ── Logo + subtitle (compact, centered) ──
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
                                            color: Color(0xFFFFD54F),
                                            shadows: [
                                              Shadow(
                                                offset: Offset(0, 3),
                                                blurRadius: 4,
                                                color: Colors.black54,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Sublabel pill — theme-tinted border, stat
                                  // color text (contrast-safe on scaffold).
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: flair.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: flair.primary.withValues(
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
                                        color: flair.headlineStat,
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
                                        // Local Run = single device solo
                                        // play — the solid hero button.
                                        _menuButton(
                                          icon: Icons.play_arrow_rounded,
                                          label: 'Local Run',
                                          solid: true,
                                          sf: sf,
                                          flair: flair,
                                          labelColor: onBtn,
                                          onTap: () {
                                            Haptics.selection();
                                            Navigator.push(
                                              context,
                                              fastRoute(
                                                const CharacterSelectScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        _menuButton(
                                          icon: Icons.bluetooth_searching,
                                          label: 'Multiplayer',
                                          sf: sf,
                                          flair: flair,
                                          labelColor: onBtn,
                                          onTap: () {
                                            Haptics.selection();
                                            Navigator.push(
                                              context,
                                              fastRoute(const MpLobbyScreen()),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        _menuButton(
                                          icon: Icons.palette_rounded,
                                          label: 'Theme',
                                          sf: sf,
                                          flair: flair,
                                          labelColor: onBtn,
                                          onTap: () {
                                            Haptics.selection();
                                            Navigator.push(
                                              context,
                                              fastRoute(
                                                const ExperienceStudioScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _menuButton(
                                                icon: Icons.quiz_rounded,
                                                label: 'Quiz',
                                                sf: sf,
                                                flair: flair,
                                                labelColor: onBtn,
                                                onTap: () {
                                                  Haptics.selection();
                                                  Navigator.push(
                                                    context,
                                                    fastRoute(
                                                      const QuizHomeScreen(
                                                        showBackButton: true,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _menuButton(
                                                icon: Icons.menu_book_rounded,
                                                label: 'Ammonomicon',
                                                sf: sf,
                                                flair: flair,
                                                labelColor: onBtn,
                                                onTap: () {
                                                  Haptics.selection();
                                                  Navigator.push(
                                                    context,
                                                    fastRoute(
                                                      const CodexScreen(
                                                        showBackButton: true,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
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
                                      color: onBtn.withValues(alpha: 0.4),
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

  /// Themed menu button — primary-tinted ghost, or a solid primary
  /// hero when [solid] is set. Label color is passed in pre-checked
  /// for the current palette so it can never go invisible.
  Widget _menuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double sf,
    required ThemeFlair flair,
    required Color labelColor,
    bool solid = false,
  }) {
    final fg =
        solid
            ? (flair.primary.computeLuminance() > 0.5
                ? const Color(0xFF1C1C1E)
                : Colors.white)
            : labelColor;
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 62 * sf,
        decoration: BoxDecoration(
          gradient:
              solid
                  ? null
                  : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      flair.primary.withValues(alpha: 0.16),
                      flair.primary.withValues(alpha: 0.05),
                    ],
                  ),
          color: solid ? flair.primary : null,
          borderRadius: const BorderRadius.all(Radii.lg),
          border: Border.all(
            color:
                solid
                    ? flair.primary.withValues(alpha: 0.8)
                    : flair.primary.withValues(alpha: 0.55),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: flair.primary.withValues(alpha: solid ? 0.35 : 0.15),
              blurRadius: solid ? 16 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24 * sf, color: solid ? fg : flair.primary),
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
