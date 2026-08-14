import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'character_select_screen.dart';
import 'multiplayer_lobby_screen.dart';
import 'theme_picker_screen.dart';
import '../services/haptics.dart';
import '../widgets/scale_button.dart';
import '../services/goop_talk_engine.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import '../widgets/backgrounds/gungeon_fall_animation.dart';

/// Opening screen. App title, subtitle, and primary action buttons.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final btnHeight = 54 * sf;
    final btnFontSize = 16 * sf;
    final btnIconSize = 24 * sf;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GungeonFallAnimation(
        child: Stack(
          children: [
          Positioned.fill(
              child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      // REDESIGNED STYLISH GUNGEON MATE TITLE HEADER
                      Column(
                        children: [
                          // Styled logo/title with an intense stroke outline and golden saloon look
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Deep red backing stroke outline
                                GoopText(
                                  'GUNGEON MATE',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 6
                                      ..color = const Color(0xFFC62828), // Deep Gungeon Red
                                  ),
                                ),
                                // Metallic gold foreground text with solid shadow
                                const GoopText(
                                  'GUNGEON MATE',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    color: Color(0xFFFFD54F), // Bright Gold
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
                          // Premium Gungeon-style Ribbon Subtitle
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC62828).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFC62828).withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                            ),
                            child: const GoopText(
                              'YOUR COMPANION IN THE GUNGEON',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE57373), // Soft active red
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // 🔥 Bullet Hell Edition — animated wobble + burn heading
                      const _BulletHellHeading(),
                      const Spacer(flex: 2),
                  // Local Run = single device solo play
                  ScaleButton(
                    onTap: () {
                      Haptics.selection();
                      Navigator.push(
                        context,
                        fastRoute(const CharacterSelectScreen()),
                      );
                    },
                    child: IgnorePointer(
                      child: SizedBox(
                        width: double.infinity,
                        height: btnHeight,
                        child: FilledButton.icon(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            elevation: 3,
                            shadowColor: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                          ),
                          icon: Icon(Icons.play_arrow_rounded, size: btnIconSize),
                          label: GoopText(
                            'Local Run',
                            style: TextStyle(
                              fontSize: btnFontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Bluetooth Multiplayer = pair two devices
                  ScaleButton(
                    onTap: () {
                      Haptics.selection();
                      Navigator.push(
                        context,
                        fastRoute(const MultiplayerLobbyScreen()),
                      );
                    },
                    child: IgnorePointer(
                      child: SizedBox(
                        width: double.infinity,
                        height: btnHeight,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1.2,
                            ),
                          ),
                          icon: Icon(Icons.bluetooth_searching, size: 22 * sf),
                          label: GoopText(
                            'Multiplayer',
                            style: TextStyle(
                              fontSize: btnFontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GoopText(
                    'v1.9.10',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Language toggle pill — hidden for now (feature disabled)
                  // _LanguageToggle(),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
          ),
          ),
          // Palette quick-launch — top-right corner. Opens the theme
          // picker directly so the user can switch themes in 1 tap.
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: InkWell(
                onTap: () {
                  Haptics.selection();
                  Navigator.push(
                    context,
                    fastRoute(const ThemePickerScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.all(8 * sf),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1.2),
                  ),
                  child: Icon(Icons.palette_rounded, size: 16 * sf, color: Colors.pinkAccent),
                ),
              ),
            ),
          ),
          // Changelog button — centered at bottom, 15% bigger
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: InkWell(
                  onTap: () => _showChangelogDialog(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16 * sf, vertical: 9 * sf),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_edu_rounded, size: 16 * sf, color: const Color(0xFFFFD54F)),
                        SizedBox(width: 7 * sf),
                        GoopText(
                          'Changelog (v1.9.10)',
                          style: TextStyle(fontSize: 12.5 * sf, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  void _showChangelogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0F0F12), // Deep black-wine slate
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF332225), width: 1.5),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.history_edu_rounded, color: Color(0xFFFFD54F), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const GoopText(
                            'GUNGEON MATE COMPANION',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const GoopText(
                            'v1.9.10 — BULLET HELL EDITION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD54F),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),

                // Content Scroll View
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Core App Features
                        const GoopText(
                          'MAIN COMPANION FEATURES',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE57373),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _featureRow(Icons.inventory_2_outlined, 'Dynamic Inventory Management', 'Real-time logging of guns/items with live DPS, element properties, and synergy tracking.'),
                        _featureRow(Icons.style_rounded, 'Side-by-Side Live Theme Customizer', '10+ rich themes (e.g. Winchester, Ice Tyrant, Curseblaster) with custom fonts and particle speed toggles.'),
                        _featureRow(Icons.group_rounded, 'Dual-Player Live HUD / Multiplayer', 'Bluetooth/Wi-Fi event-driven co-op state synchronization with real-time stat-share mechanics.'),
                        _featureRow(Icons.auto_stories_outlined, 'Interactive Tomes & Guides', 'Winchester target guides, Stealing guides, and offline Wiki back-reference sheets.'),

                        const Divider(color: Colors.white12, height: 24),

                        // Section 2: Recent Overhauls
                        const GoopText(
                          'VERSION HISTORY & RECENT UPDATES',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.cyanAccent,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),

                        FutureBuilder<String>(
                          future: DefaultAssetBundle.of(context).loadString('assets/data/changelog.json'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: GoopText(
                                  'Error loading changelog.',
                                  style: TextStyle(color: Colors.white24, fontSize: 11),
                                ),
                              );
                            }

                            try {
                              final List<dynamic> data = json.decode(snapshot.data!);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: data.map((v) {
                                  final String version = v['version'] ?? '';
                                  final String title = v['title'] ?? '';
                                  final List<dynamic> items = v['items'] ?? [];
                                  final String groupTitle = '$title ($version)';
                                  return _changelogGroup(
                                    groupTitle,
                                    items.map((i) => i.toString()).toList(),
                                  );
                                }).toList(),
                              );
                            } catch (e) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: GoopText(
                                  'Failed to parse changelog.',
                                  style: TextStyle(color: Colors.white24, fontSize: 11),
                                ),
                              );
                            }
                          },
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
    },
  );
}

  Widget _featureRow(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFFD54F)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 1.5),
                GoopText(
                  body,
                  style: const TextStyle(fontSize: 11, color: Colors.white54, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _changelogGroup(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoopText(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    Expanded(
                      child: GoopText(
                        it,
                        style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.25),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// _LanguageToggle — hidden for now (Goopian feature disabled)
// /// Segmented English / Goopian language toggle pill.
// /// Tapping switches VisualPrefs.isGoopianLanguage, which triggers
// /// all GoopText widgets across the app to animate.
// class _LanguageToggle extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: VisualPrefs.notifier,
//       builder: (context, _) {
//         final isGoopian = VisualPrefs.notifier.value.isGoopianLanguage;
//         return ScaleButton(
//           onTap: () {
//             Haptics.selection();
//             VisualPrefs.setIsGoopianLanguage(!isGoopian);
//           },
//           enableHaptics: false,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
//             decoration: BoxDecoration(
//               color: const Color(0xFF1E1E22),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: isGoopian
//                     ? const Color(0xFF9C27B0).withValues(alpha: 0.5)
//                     : Colors.white.withValues(alpha: 0.15),
//                 width: 1.2,
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _Segment(
//                   label: 'English',
//                   icon: Icons.language,
//                   active: !isGoopian,
//                   activeColor: Colors.cyanAccent,
//                 ),
//                 _Segment(
//                   label: GoopTalkEngine.translateToGoop('Goopian'),
//                   icon: Icons.translate,
//                   active: isGoopian,
//                   activeColor: const Color(0xFF9C27B0),
//                   isGoopian: true,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// class _Segment extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final bool active;
//   final Color activeColor;
//   final bool isGoopian;
//
//   const _Segment({
//     required this.label,
//     required this.icon,
//     required this.active,
//     required this.activeColor,
//     this.isGoopian = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: active ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             size: 13,
//             color: active ? activeColor : Colors.white.withValues(alpha: 0.4),
//           ),
//           const SizedBox(width: 5),
//           isGoopian
//               ? Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 11.5,
//                     fontWeight: FontWeight.w700,
//                     color: active ? activeColor : Colors.white.withValues(alpha: 0.4),
//                     letterSpacing: 0.5,
//                   ),
//                 )
//               : GoopText(
//                   label,
//                   style: TextStyle(
//                     fontSize: 11.5,
//                     fontWeight: FontWeight.w700,
//                     color: active ? activeColor : Colors.white.withValues(alpha: 0.4),
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }
// }

// =============================================================================
// 🔥 Bullet Hell Edition — animated wobble + burn heading
// =============================================================================

/// A themed sub-update banner for the main menu. The "BULLET HELL" text
/// wobbles gently (rotation oscillation) while an ember glow pulses behind
/// it, giving a "burning" feel. Fire icon flickers. Uses a single
/// repeating AnimationController — disposed properly.
class _BulletHellHeading extends StatefulWidget {
  const _BulletHellHeading();

  @override
  State<_BulletHellHeading> createState() => _BulletHellHeadingState();
}

class _BulletHellHeadingState extends State<_BulletHellHeading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burn;

  @override
  void initState() {
    super.initState();
    // Cycle: 2.8s wobble + 6s pause = 8.8s total per loop.
    // The wobble plays for the first 2.8s, then the heading sits still
    // for 6s before the next fiery burst.
    _burn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8800),
    )..repeat();
  }

  @override
  void dispose() {
    _burn.dispose();
    super.dispose();
  }

  // Wobble only during the first ~32% of the cycle (2.8s / 8.8s).
  double get _wobbleValue {
    final t = _burn.value;
    if (t > 0.318) return 0.0; // resting phase
    // Map 0..0.318 → 0..1 for the wobble curve
    final wobbleT = t / 0.318;
    return -0.044 * math.sin(wobbleT * math.pi * 2);
  }

  double get _glowValue {
    final t = _burn.value;
    if (t > 0.318) return 0.25; // resting glow during pause
    final wobbleT = t / 0.318;
    return 0.25 + 0.40 * (0.5 - 0.5 * math.cos(wobbleT * math.pi * 2));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _burn,
      builder: (context, _) {
        final wobble = _wobbleValue;
        final glow = _glowValue;
        return Transform.rotate(
          angle: wobble,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFF5252).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5252)
                      .withValues(alpha: glow * 0.5),
                  blurRadius: 12 + glow * 16,
                  spreadRadius: 1 + glow * 3,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flickering fire icon
                Icon(
                  Icons.local_fire_department,
                  size: 22,
                  color: const Color(0xFFFF5252)
                      .withValues(alpha: 0.7 + glow * 0.3),
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFF5252)
                          .withValues(alpha: glow),
                      blurRadius: 8,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // "BULLET HELL" text with ember glow shadow
                GoopText(
                  'BULLET HELL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFF5252)
                            .withValues(alpha: glow),
                        blurRadius: 6 + glow * 8,
                      ),
                      const Shadow(
                        color: Color(0xFFB71C1C),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Version tag
                GoopText(
                  'v1.9.10',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(
          duration: 600.ms,
          delay: 300.ms,
        ).slideY(
          begin: 0.3,
          end: 0,
          duration: 600.ms,
          delay: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}
