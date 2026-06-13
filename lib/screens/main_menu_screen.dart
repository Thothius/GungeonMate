import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'character_select_screen.dart';
import 'multiplayer_lobby_screen.dart';
import 'theme_picker_screen.dart';
import '../services/haptics.dart';

/// Opening screen. App title, subtitle, and primary action buttons.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  String? _mascotQuote;
  Timer? _quoteTimer;

  void _onMascotTapped() {
    _quoteTimer?.cancel();
    Haptics.selection();
    
    final quotes = [
      "Mind the grease, Gungeoneer! Heavy machinery at work.",
      "Need a shortcut to Chamber 3? Bring me 3 Master Rounds!",
      "Weld, hammer, build... the elevator shafts never rest.",
      "I like a foreman with hands-on grit. Let's make this cable hold!",
      "Is the floor going down, or are we flying upwards? Mechanical philosophy!",
    ];
    
    final rand = math.Random().nextInt(quotes.length);
    setState(() {
      _mascotQuote = quotes[rand];
    });
    
    _quoteTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _mascotQuote = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF231A1D), // soft deep wine-pink/charcoal center for cat theme!
              Color(0xFF0C090A), // rich pitch-black edges
            ],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: _FloatingPawsBackground(
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
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Deep red backing stroke outline
                              Text(
                                'GUNGEON MATE',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 6
                                    ..color = const Color(0xFFC62828), // Deep Gungeon Red
                                ),
                              ),
                              // Metallic gold foreground text with solid shadow
                              const Text(
                                'GUNGEON MATE',
                                style: TextStyle(
                                  fontSize: 34,
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
                            child: const Text(
                              'YOUR COMPANION IN THE GUNGEON',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE57373), // Soft active red
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 2),
                      // The Tailor — GungeonMate's inventory-hauling mascot (Now fully interactive on tap!)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_mascotQuote != null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1F), // Charcoal Gungeon bubble
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(maxWidth: 240),
                              child: Text(
                                _mascotQuote!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFFFFD54F),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                          GestureDetector(
                            onTap: _onMascotTapped,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.3),
                                border: Border.all(
                                  color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD54F).withValues(alpha: 0.08),
                                    blurRadius: 24,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/animations/Tailor_idle.gif',
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none, // crisp pixel art
                                  gaplessPlayback: true,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.backpack_rounded,
                                    size: 64,
                                    color: Color(0xFFFFD54F),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 1),
                  // Local Run = single device solo play
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 26),
                      label: const Text(
                        'Local Run',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CharacterSelectScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bluetooth Multiplayer = pair two devices
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bluetooth_searching, size: 24),
                      label: const Text(
                        'Multiplayer',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MultiplayerLobbyScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Customize (formerly Theme Picker)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.palette_outlined, size: 24),
                      label: const Text(
                        'Customize',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ThemePickerScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'v1.8.4',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
            ),
            // Small top-left Changelog button
            Positioned(
              left: 16,
              top: 16,
              child: SafeArea(
                child: InkWell(
                  onTap: () => _showChangelogDialog(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_edu_rounded, size: 14, color: Color(0xFFFFD54F)),
                        SizedBox(width: 6),
                        Text(
                          'Changelog',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      ],
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GUNGEON MATE COMPANION',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'v1.8.4 — 2026 Ultimate Edition',
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
                        const Text(
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
                        const Text(
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
                                child: Text(
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
                                child: Text(
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 1.5),
                Text(
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
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Expanded(
                      child: Text(
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

class _FloatingPawsBackground extends StatefulWidget {
  final Widget child;
  const _FloatingPawsBackground({required this.child});

  @override
  State<_FloatingPawsBackground> createState() => _FloatingPawsBackgroundState();
}

class _FloatingPawsBackgroundState extends State<_FloatingPawsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_PawParticle> _paws = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Spawn 15 floating paws in random positions!
    final rand = math.Random();
    for (int i = 0; i < 15; i++) {
      _paws.add(
        _PawParticle(
          x: rand.nextDouble(),
          y: rand.nextDouble(),
          speed: 0.02 + rand.nextDouble() * 0.03,
          scale: 0.6 + rand.nextDouble() * 0.8,
          rotation: rand.nextDouble() * 2 * math.pi,
          opacity: 0.04 + rand.nextDouble() * 0.12,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update positions!
        for (final p in _paws) {
          p.y -= p.speed * 0.01; // Drift upwards!
          if (p.y < -0.1) {
            p.y = 1.1; // reset to bottom
            p.x = math.Random().nextDouble();
          }
        }

        return Stack(
          children: [
            // Drifting paws layer
            ..._paws.map((p) {
              return Positioned(
                left: p.x * MediaQuery.of(context).size.width,
                top: p.y * MediaQuery.of(context).size.height,
                child: Transform.rotate(
                  angle: p.rotation,
                  child: Transform.scale(
                    scale: p.scale,
                    child: Opacity(
                      opacity: p.opacity,
                      child: const Text(
                        '🐾',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              );
            }),
            widget.child,
          ],
        );
      },
    );
  }
}

class _PawParticle {
  double x;
  double y;
  final double speed;
  final double scale;
  final double rotation;
  final double opacity;

  _PawParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.scale,
    required this.rotation,
    required this.opacity,
  });
}
