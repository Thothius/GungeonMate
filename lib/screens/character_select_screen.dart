import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import '../services/goop_talk_engine.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/gungeoneer.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import '../utils/asset_paths.dart';
import '../utils/responsive.dart';
import '../widgets/game_icon.dart';

enum CharSelectMode { solo, coop, multiplayerPick }

class CharacterSelectScreen extends StatelessWidget {
  final CharSelectMode mode;

  /// Optional filtered list of gungeoneers to show. When null, all
  /// gungeoneers from [RunProvider] are displayed. Used by the MP
  /// lobby to exclude "The Cultist" for the Main player.
  final List<Gungeoneer>? gungeoneers;

  const CharacterSelectScreen({
    super.key,
    this.mode = CharSelectMode.solo,
    this.gungeoneers,
  });

  /// Quick constructor for multiplayer lobby picking.
  const CharacterSelectScreen.multiplayerPick({super.key})
    : mode = CharSelectMode.multiplayerPick,
      gungeoneers = null;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final isCoop = mode == CharSelectMode.coop;
    final isMultiplayerPick = mode == CharSelectMode.multiplayerPick;

    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        final flair = AppTheme.flair;
        final profile = ScreenProfile.of(context);
        // On short screens we collapse the helper text to reclaim vertical
        // space for the grid — the description is nice-to-have, not essential.
        final titleFontSize = profile.isShort ? 16.0 : 18.0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: GoopText(
              isCoop
                  ? 'Add Co-op Player'
                  : isMultiplayerPick
                  ? 'Pick your Gungeoneer'
                  : 'Gungeon Mate',
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    profile.isShort ? 8 : 16,
                    16,
                    4,
                  ),
                  child: GoopText(
                    'Choose Gungeoneer',
                    style: prefs.font.textStyle.copyWith(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: flair.primary.withValues(alpha: 0.12),
                  ),
                ),
                Expanded(
                  child: _GungeoneerPicker(
                    // Cultist is only pickable as MP Sidekick — the lobby
                    // passes the full list (incl. Cultist) for Sidekick.
                    // Solo/Coop get a filtered list with Cultist excluded.
                    gungeoneers:
                        gungeoneers ??
                        p.allGungeoneers
                            .where((g) => g.name != 'The Cultist')
                            .toList(),
                    flair: flair,
                    prefs: prefs,
                    onPick: (c, char) {
                      final run = c.read<RunProvider>();
                      if (isMultiplayerPick) {
                        Navigator.pop(c, char);
                      } else if (isCoop) {
                        run.startCoopPlayer(char);
                        if (Navigator.canPop(c)) Navigator.pop(c);
                      } else {
                        run.startNewRun(char);
                        if (Navigator.canPop(c)) Navigator.pop(c);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Swipeable gungeoneer picker — icon tab strip synced with a PageView
/// and a sticky PICK bar. Replaces the old tile grid.
class _GungeoneerPicker extends StatefulWidget {
  final List<Gungeoneer> gungeoneers;
  final ThemeFlair flair;
  final VisualPrefs prefs;
  final void Function(BuildContext, Gungeoneer) onPick;

  const _GungeoneerPicker({
    required this.gungeoneers,
    required this.flair,
    required this.prefs,
    required this.onPick,
  });

  @override
  State<_GungeoneerPicker> createState() => _GungeoneerPickerState();
}

class _GungeoneerPickerState extends State<_GungeoneerPicker> {
  final PageController _pages = PageController();
  final ScrollController _tabs = ScrollController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _jumpTo(int i) {
    Haptics.selection();
    _pages.animateToPage(i, duration: Motion.base, curve: Curves.easeOutCubic);
  }

  Widget _sprite(Gungeoneer g, double size) {
    final gif = gungeoneerGifPath(g.name);
    if (gif.isNotEmpty) {
      return Image.asset(
        gif,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Icon(Icons.person, size: size * 0.6),
      );
    }
    if (g.icon.startsWith('assets/')) {
      return Image.asset(
        g.icon,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, _, _) => Icon(Icons.person, size: size * 0.6),
      );
    }
    return Icon(Icons.person, size: size * 0.6);
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gungeoneers;
    final flair = widget.flair;
    if (gs.isEmpty) return const SizedBox.shrink();
    final sel = gs[_index.clamp(0, gs.length - 1)];
    return Column(
      children: [
        // Icon tab strip — tap to jump, synced with swipes.
        SizedBox(
          height: 72,
          child: ListView.builder(
            controller: _tabs,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
            itemCount: gs.length,
            itemBuilder: (c, i) {
              final g = gs[i];
              final on = i == _index;
              return GestureDetector(
                // Tap unselected = jump to it. Tap the already-selected
                // icon = confirm and go next (no PICK-bar hunt).
                onTap:
                    on
                        ? () {
                          Haptics.selection();
                          widget.onPick(context, sel);
                        }
                        : () => _jumpTo(i),
                child: AnimatedContainer(
                  duration: Motion.fast,
                  width: 66,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        on ? flair.primary.withValues(alpha: 0.14) : flair.card,
                    borderRadius: const BorderRadius.all(Radii.md),
                    border: Border.all(
                      color:
                          on
                              ? flair.primary.withValues(alpha: 0.7)
                              : flair.primary.withValues(alpha: 0.15),
                      width: on ? 1.6 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: _sprite(g, 38),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: GoopText(
                          g.name.replaceFirst('The ', ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: FontSizes.labelSmall,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color:
                                on
                                    ? flair.primary
                                    : flair.primary.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: flair.primary.withValues(alpha: 0.12),
        ),
        // Swipe pages.
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: gs.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              if (_tabs.hasClients) {
                const cell = 74.0; // 66 width + 8 horizontal margin
                _tabs.animateTo(
                  (i * cell - 40).clamp(0.0, _tabs.position.maxScrollExtent),
                  duration: Motion.fast,
                  curve: Curves.easeOutCubic,
                );
              }
            },
            itemBuilder:
                (c, i) => _GungeoneerPage(
                  g: gs[i],
                  flair: flair,
                  sprite: _sprite(gs[i], 110),
                ),
          ),
        ),
        // Sticky PICK bar.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              Insets.md,
            ),
            child: GestureDetector(
              onTap: () {
                Haptics.selection();
                widget.onPick(context, sel);
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: flair.primary,
                  borderRadius: const BorderRadius.all(Radii.lg),
                  boxShadow: [
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: GoopText(
                    'PICK ${sel.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: FontSizes.titleSmall,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color:
                          flair.primary.computeLuminance() > 0.5
                              ? const Color(0xFF1C1C1E)
                              : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One picker page — sprite, name, armor chip, starting loadout with real
/// icons, short_desc + playstyle. Clean and compact by design.
class _GungeoneerPage extends StatelessWidget {
  final Gungeoneer g;
  final ThemeFlair flair;
  final Widget sprite;

  const _GungeoneerPage({
    required this.g,
    required this.flair,
    required this.sprite,
  });

  Widget _loadout(String label, List<String> names, bool gun) {
    if (names.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.sm),
          child: GoopText(
            label,
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: flair.primary.withValues(alpha: 0.55),
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            for (final n in names)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: flair.card,
                  borderRadius: BorderRadius.all(Radii.sm),
                  border: Border.all(
                    color: flair.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GameIcon(
                      assetPath: gun ? localGunIcon(n) : localItemIcon(n),
                      size: 30,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: GoopText(
                        n,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.lg,
        Insets.xl,
        Insets.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              // Sprite LEFT, info RIGHT — portrait and metadata read
              // side-by-side instead of stacked.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    height: 110,
                    child: Center(child: sprite),
                  ),
                  const SizedBox(width: Insets.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoopText(
                          g.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: FontSizes.titleLarge,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: flair.headlineStat,
                          ),
                        ),
                        if (g.startingArmor > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Insets.sm,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(Radii.sm),
                                border: Border.all(
                                  color: flair.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: GoopText(
                                '${g.startingArmor} ARMOR',
                                style: const TextStyle(
                                  fontSize: FontSizes.labelSmall,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: Insets.md),
                        _loadout('GUNS', g.startingGuns, true),
                        if (g.startingGuns.isNotEmpty &&
                            g.startingItems.isNotEmpty)
                          const SizedBox(height: Insets.sm),
                        _loadout('ITEMS', g.startingItems, false),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.lg),
              Divider(
                height: 1,
                thickness: 0.5,
                color: flair.primary.withValues(alpha: 0.12),
              ),
              const SizedBox(height: Insets.md),
              if (g.shortDesc.isNotEmpty)
                GoopText(
                  g.shortDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    height: 1.45,
                  ),
                ),
              if (g.playstyle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Insets.sm),
                  child: GoopText(
                    g.playstyle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: FontSizes.labelMedium,
                      height: 1.45,
                      color: flair.primary.withValues(alpha: 0.6),
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
