import 'package:flutter/material.dart';

/// A snappy, fluid, vertical swipe page drawer that merges an immersive narrative NPC screen
/// (top page) with a high-density utility toolset dashboard (bottom page).
class VerticalSwipeLayout extends StatefulWidget {
  final Widget narrativeView;
  final Widget utilityView;
  final String npcName;

  const VerticalSwipeLayout({
    super.key,
    required this.narrativeView,
    required this.utilityView,
    required this.npcName,
  });

  @override
  State<VerticalSwipeLayout> createState() => _VerticalSwipeLayoutState();
}

class _VerticalSwipeLayoutState extends State<VerticalSwipeLayout> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _arrowController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      onPageChanged: _onPageChanged,
      children: [
        // --- PAGE 0: Full Screen Narrative View ---
        Stack(
          children: [
            Positioned.fill(child: widget.narrativeView),

            // Animated Spring Chevron Indicator floating at the bottom
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_arrowController),
                  child: AnimatedBuilder(
                    animation: _arrowController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _arrowController.value * 6),
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'SWIPE DOWN FOR TOOLS',
                          style: TextStyle(
                            fontFamily: 'EnterTheGungeonBig',
                            fontSize: 8,
                            color: Colors.white54,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.keyboard_double_arrow_down_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // --- PAGE 1: Dynamic Utility Dashboards ---
        Stack(
          children: [
            Positioned.fill(child: widget.utilityView),

            // Floating "Swipe Up" Chevron floating at the top of utility view
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.3, end: 0.8).animate(_arrowController),
                  child: AnimatedBuilder(
                    animation: _arrowController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_arrowController.value * 4),
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard_double_arrow_up_rounded,
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                          size: 14,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'SWIPE UP TO TALK',
                          style: TextStyle(
                            fontFamily: 'EnterTheGungeonBig',
                            fontSize: 7,
                            color: Colors.white38,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
