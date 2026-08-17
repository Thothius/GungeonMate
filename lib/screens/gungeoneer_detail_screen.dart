import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gungeoneer.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../utils/asset_paths.dart';
import '../utils/fast_route.dart';
import '../widgets/spoiler_tag.dart';
import 'item_detail_screen.dart';

/// Rich, scrollable detail view for a single Gungeoneer.
///
/// Shows character art, short description, starting loadout (with tappable
/// tiles that link to existing gun/item detail screens), playstyle analysis,
/// gameplay tips, and spoiler-gated sections for past story, past kill
/// details, unlock methods, and alternate costume information.
class GungeoneerDetailScreen extends StatelessWidget {
  final Gungeoneer gungeoneer;

  const GungeoneerDetailScreen({super.key, required this.gungeoneer});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final g = gungeoneer;
    final p = context.watch<RunProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: GoopText(
          g.name,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (g.wikiUrl.isNotEmpty)
            IconButton(
              tooltip: 'View on Wiki',
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () => _launchWiki(context, g.wikiUrl),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Hero art + short desc ──
          SliverToBoxAdapter(child: _HeroSection(gungeoneer: g, flair: flair)),

          // ── Lore intro ──
          if (g.loreIntro.isNotEmpty)
            SliverToBoxAdapter(
              child: _Section(
                label: 'LORE',
                icon: Icons.auto_stories,
                color: Colors.purpleAccent,
                child: GoopText(
                  g.loreIntro,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),

          // ── Starting loadout ──
          SliverToBoxAdapter(
            child: _LoadoutSection(gungeoneer: g, flair: flair, provider: p),
          ),

          // ── Playstyle ──
          if (g.playstyle.isNotEmpty)
            SliverToBoxAdapter(
              child: _Section(
                label: 'PLAYSTYLE',
                icon: Icons.sports_esports,
                color: Colors.cyanAccent,
                child: GoopText(
                  g.playstyle,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),

          // ── Tips ──
          if (g.tips.isNotEmpty)
            SliverToBoxAdapter(
              child: _Section(
                label: 'TIPS',
                icon: Icons.lightbulb_outline,
                color: Colors.amberAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: g.tips
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.arrow_right_rounded,
                                    size: 18,
                                    color:
                                        Colors.amberAccent.withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: GoopText(
                                    t,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),

          // ── Spoiler sections ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Past Story
                  if (g.pastSummary.isNotEmpty)
                    SpoilerTag(
                      label: 'Past Story',
                      content: _SpoilerContent(
                        title: g.pastName,
                        body: g.pastSummary,
                      ),
                    ),
                  // Past Kill Details
                  if (g.pastDetails.isNotEmpty)
                    SpoilerTag(
                      label: 'Past Kill Details',
                      content: _SpoilerContent(
                        title: g.pastName,
                        body: g.pastDetails,
                        extra: g.pastLoadout.isNotEmpty
                            ? 'Past loadout: ${g.pastLoadout}'
                            : null,
                      ),
                    ),
                  // Past Kill Unlocks
                  if (g.pastUnlocks.isNotEmpty &&
                      !g.pastUnlocks.contains('N/A'))
                    SpoilerTag(
                      label: 'Past Kill Unlocks',
                      icon: Icons.card_giftcard,
                      content: _SpoilerContent(body: g.pastUnlocks),
                    ),
                  // Unlock Method
                  if (g.unlockMethod.isNotEmpty &&
                      !g.unlockMethod.contains('Available from the start'))
                    SpoilerTag(
                      label: 'Unlock Method',
                      icon: Icons.lock_outline,
                      content: _SpoilerContent(body: g.unlockMethod),
                    ),
                  // Alternate Unlocks
                  if (g.altCostumeUnlock.isNotEmpty &&
                      !g.altCostumeUnlock.contains('N/A'))
                    SpoilerTag(
                      label: 'Alternate Unlocks',
                      icon: Icons.palette_outlined,
                      content: _SpoilerContent(
                        body: [
                          if (g.altCostumeName.isNotEmpty &&
                              !g.altCostumeName.contains('N/A'))
                            'Alternate costume: ${g.altCostumeName}',
                          g.altCostumeUnlock,
                          if (g.altWeaponSkinUnlock.isNotEmpty &&
                              !g.altWeaponSkinUnlock.contains('N/A'))
                            g.altWeaponSkinUnlock,
                        ]
                            .where((s) => s.isNotEmpty)
                            .join('\n\n'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchWiki(BuildContext context, String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError(
      (e) {
        debugPrint('[GungeoneerDetail] url launch error: $e');
        if (context.mounted) {
          Clipboard.setData(ClipboardData(text: url));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: GoopText('Could not open — URL copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return false;
      },
    );
  }
}

// =============================================================================
// Hero section — character art + short desc + badges
// =============================================================================

class _HeroSection extends StatelessWidget {
  final Gungeoneer gungeoneer;
  final ThemeFlair flair;

  const _HeroSection({required this.gungeoneer, required this.flair});

  @override
  Widget build(BuildContext context) {
    final g = gungeoneer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Character art
          SizedBox(
            height: 180,
            child: Center(child: _buildArt()),
          ),
          const SizedBox(height: 12),
          // Short description
          if (g.shortDesc.isNotEmpty)
            GoopText(
              g.shortDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.white.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
          const SizedBox(height: 8),
          // Badges row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (g.isCoopOnly)
                _Badge(
                  label: 'CO-OP ONLY',
                  color: Colors.cyanAccent,
                  icon: Icons.group,
                ),
              if (g.hegemonyCost > 0)
                _Badge(
                  label: 'Cost: ${g.hegemonyCost} Hegemony Credits',
                  color: Colors.amberAccent,
                  icon: Icons.paid,
                ),
              if (g.startingArmor > 0 && !g.name.contains('Robot'))
                _Badge(
                  label: 'Starts with ${g.startingArmor} armor',
                  color: Colors.blueAccent,
                  icon: Icons.shield,
                ),
              if (g.name == 'The Robot')
                _Badge(
                  label: '6 Armor, No Hearts',
                  color: Colors.amberAccent,
                  icon: Icons.precision_manufacturing,
                ),
            ],
          ),
          // Nicknames trivia
          if (g.nicknames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GoopText(
                [
                  if (g.nicknames.isNotEmpty)
                    'Also called: ${g.nicknames.join(', ')}',
                  if (g.voice.isNotEmpty) 'Voice: ${g.voice}',
                ].join(' · '),
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArt() {
    final animPath = gungeoneerAnimatedCardPath(gungeoneer.name);
    if (animPath.isNotEmpty) {
      return Image.asset(
        animPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    if (gungeoneer.icon.startsWith('assets/')) {
      return Image.asset(
        gungeoneer.icon,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, size: 120, color: Colors.white54),
      );
    }
    return const Icon(Icons.person, size: 120, color: Colors.white54);
  }
}

// =============================================================================
// Loadout section — tappable gun/item tiles
// =============================================================================

class _LoadoutSection extends StatelessWidget {
  final Gungeoneer gungeoneer;
  final ThemeFlair flair;
  final RunProvider provider;

  const _LoadoutSection({
    required this.gungeoneer,
    required this.flair,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final g = gungeoneer;
    final guns = g.startingGuns;
    final items = g.startingItems;

    return _Section(
      label: 'STARTING LOADOUT',
      icon: Icons.inventory_2,
      color: flair.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guns
          if (guns.isNotEmpty) ...[
            _SubLabel('Weapons'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: guns.map((name) => _LoadoutTile(
                    name: name,
                    isRandom: name == 'Random',
                    provider: provider,
                  )).toList(),
            ),
            const SizedBox(height: 12),
          ],
          // Items
          if (items.isNotEmpty) ...[
            _SubLabel('Items'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((name) => _LoadoutTile(
                    name: name,
                    isRandom: name == 'Random',
                    provider: provider,
                  )).toList(),
            ),
            const SizedBox(height: 12),
          ],
          // Armor
          if (g.startingArmor > 0) ...[
            _SubLabel('Other'),
            Row(
              children: [
                Icon(Icons.shield, size: 16, color: Colors.blueAccent.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                GoopText(
                  '${g.startingArmor} Armor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadoutTile extends StatelessWidget {
  final String name;
  final bool isRandom;
  final RunProvider provider;

  const _LoadoutTile({
    required this.name,
    required this.isRandom,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (isRandom) {
      return _tileContainer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shuffle, size: 16, color: Colors.purpleAccent.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            GoopText(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.purpleAccent.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      );
    }

    final gun = provider.gunByName(name);
    final item = provider.itemByName(name);
    final exists = gun != null || item != null;

    return GestureDetector(
      onTap: exists
          ? () {
              Haptics.selection();
              Navigator.push(
                context,
                fastRoute(ItemDetailScreen(gun: gun, item: item)),
              );
            }
          : null,
      child: _tileContainer(
        opacity: exists ? 1.0 : 0.5,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              gun != null ? Icons.gps_fixed : Icons.inventory_2_outlined,
              size: 16,
              color: (gun != null ? Colors.cyanAccent : Colors.greenAccent)
                  .withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            GoopText(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
                decoration: exists ? null : TextDecoration.lineThrough,
              ),
            ),
            if (exists) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 14, color: Colors.white.withValues(alpha: 0.4)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tileContainer({required Widget child, double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.flair.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.flair.primary.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        child: child,
      ),
    );
  }
}

// =============================================================================
// Reusable section wrapper
// =============================================================================

class _Section extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Widget child;

  const _Section({
    required this.label,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              GoopText(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: color.withValues(alpha: 0.9),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.flair.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.flair.primary.withValues(alpha: 0.1),
                width: 0.8,
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GoopText(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// =============================================================================
// Badge
// =============================================================================

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Badge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          GoopText(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Spoiler content
// =============================================================================

class _SpoilerContent extends StatelessWidget {
  final String? title;
  final String body;
  final String? extra;

  const _SpoilerContent({this.title, required this.body, this.extra});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          GoopText(
            title!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.amber.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
        ],
        GoopText(
          body,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        if (extra != null && extra!.isNotEmpty) ...[
          const SizedBox(height: 8),
          GoopText(
            extra!,
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }
}
