import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../providers/run_provider.dart';
import '../models/gun.dart';
import '../models/item.dart';
import '../models/npc_dialogue.dart';
import '../widgets/animated_chat_bubble.dart';
import '../widgets/vertical_swipe_layout.dart';
import '../services/haptics.dart';
import 'item_detail_screen.dart';
import 'winchester_minigame_screen.dart';
import '../services/app_theme.dart';

/// Tabbed NPC compendium: Bello's shop calculator + aggro tracker,
/// Winchester's modifier compatibility + minigame launcher, the Annex
/// spawn analytics engine, and Frifle & Daisuke hunting/challenge data.
class NpcViewScreen extends StatelessWidget {
  const NpcViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GUNGEON NPCS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            tabs: [
              Tab(text: 'BELLO SHOP'),
              Tab(text: 'WINCHESTER'),
              Tab(text: 'ANNEX'),
              Tab(text: 'HUNTING'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BelloTab(),
            _WinchesterTab(),
            _AnnexTab(),
            _HuntingTab(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Shared helpers
// =============================================================================

class _NpcHeader extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final String title;
  final String description;
  final Color accent;
  const _NpcHeader({
    required this.asset,
    required this.fallbackIcon,
    required this.title,
    required this.description,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: accent, size: 32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: accent, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _SectionTitle(this.text, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 1: Bello — price calculator + aggro tracker
// =============================================================================

class _BelloTab extends StatefulWidget {
  const _BelloTab();
  @override
  State<_BelloTab> createState() => _BelloTabState();
}

class _BelloTabState extends State<_BelloTab> {
  static const _floors = <String, double>{
    'Chamber 1 (Keep)': 1.0,
    'Chamber 2 (Gungeon Proper)': 1.15,
    'Chamber 3 (Black Powder Mine)': 1.3,
    'Chamber 4 (Hollow)': 1.45,
    'Secret Floors': 1.0,
  };
  static const _items = <String, int>{
    'S-Tier (Black)': 100,
    'A-Tier (Red)': 68,
    'B-Tier (Green)': 46,
    'C-Tier (Blue)': 32,
    'D-Tier (Brown)': 22,
    'Heart / Armor': 20,
    'Key': 25,
  };

  String _floor = 'Chamber 1 (Keep)';
  String _item = 'S-Tier (Black)';
  int _aggro = 0;
  double _curioDiscount = 1.0;

  @override
  void initState() {
    super.initState();
    _loadCurioDiscounts();
  }

  Future<void> _loadCurioDiscounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double discount = 1.0;
      if (prefs.getBool('npc.quest.completed.flynt_delivered') ?? false) discount -= 0.10;
      if (prefs.getBool('npc.quest.completed.vampire_delivered') ?? false) discount -= 0.10;
      if (prefs.getBool('npc.quest.completed.goopton_delivered') ?? false) discount -= 0.10;
      
      if (mounted && discount != _curioDiscount) {
        setState(() {
          _curioDiscount = discount;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    _loadCurioDiscounts();
    final base = _items[_item]!;
    final mult = _floors[_floor]!;
    final aggroMult = _aggro >= 2 ? 2.0 : 1.0;
    final shopClosed = _aggro >= 3;
    final finalCost = (base * mult * aggroMult * _curioDiscount).floor();

    return VerticalSwipeLayout(
      npcName: 'Bello',
      narrativeView: const _NpcDialoguePanel(
        npcId: 'bello',
        npcName: 'Bello',
        gifAsset: 'assets/animations/Bello_idle.gif',
        accentColor: Colors.amberAccent,
        fallbackIcon: Icons.storefront_rounded,
      ),
      utilityView: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NpcHeader(
            asset: 'assets/animations/Bello_idle.gif',
            fallbackIcon: Icons.storefront_rounded,
            title: 'BELLO — MAIN SHOPKEEPER',
            description: 'Appears on all main floors. Do not discharge weapons in his proximity.',
            accent: Colors.amberAccent,
          ),
          const _SectionTitle('DYNAMIC PRICE CALCULATOR', Icons.calculate_rounded, Colors.amberAccent),
          
          // Floors Grid Matrix
          const Text(
            'SELECT FLOOR:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in _floors.entries)
                Builder(builder: (ctx) {
                  final isSelected = _floor == entry.key;
                  final chamberNames = {
                    'Chamber 1 (Keep)': 'Keep',
                    'Chamber 2 (Gungeon Proper)': 'Gungeon Proper',
                    'Chamber 3 (Black Powder Mine)': 'Black Powder Mine',
                    'Chamber 4 (Hollow)': 'Hollow',
                    'Secret Floors': 'Secret Floors',
                  };
                  final display = chamberNames[entry.key] ?? entry.key;
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.amber.withValues(alpha: 0.08) : Colors.transparent,
                      side: BorderSide(
                        color: isSelected ? Colors.amberAccent : Colors.white24,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => setState(() => _floor = entry.key),
                    child: Text(
                      display.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.amberAccent : Colors.white70,
                      ),
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 12),
          
          // Rarity Grid Matrix
          const Text(
            'SELECT ITEM TYPE / RARITY:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in _items.entries)
                Builder(builder: (ctx) {
                  final isSelected = _item == entry.key;
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.amber.withValues(alpha: 0.08) : Colors.transparent,
                      side: BorderSide(
                        color: isSelected ? Colors.amberAccent : Colors.white24,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => setState(() => _item = entry.key),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.amberAccent : Colors.white70,
                      ),
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: shopClosed
                  ? Colors.red.withValues(alpha: 0.08)
                  : Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: shopClosed ? Colors.redAccent : Colors.amberAccent.withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                shopClosed
                    ? 'SHOP CLOSED — NO SALES'
                    : 'FINAL COST: $finalCost CASINGS'
                        '${_aggro >= 2 ? '  (DOUBLED!)' : ''}'
                        '${_curioDiscount < 1.0 ? '  (${(100 * (1.0 - _curioDiscount)).round()}% CURIOS DISCOUNT!)' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: shopClosed ? Colors.redAccent : Colors.amberAccent,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const _SectionTitle('AGGRO & PUNISHMENT TRACKER', Icons.warning_amber_rounded, Colors.orangeAccent),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.gps_not_fixed_rounded, size: 18),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.orangeAccent),
              label: Text('Discharge Weapon in Shop ($_aggro/3)'),
              onPressed: shopClosed ? null : () => setState(() => _aggro = (_aggro + 1).clamp(0, 3)),
            ),
          ),
          const SizedBox(height: 8),
          if (_aggro == 1)
            _aggroBanner('Bello warns you: "Watch where you point that thing, Gungeoneer."', Colors.yellowAccent),
          if (_aggro == 2)
            _aggroBanner('PRICES DOUBLED. Bello is visually furious.', Colors.orangeAccent),
          if (_aggro >= 3)
            _aggroBanner('SHOP CLOSED PERMANENTLY. Bello shoots you for "Justice" and vanishes for the rest of the run.', Colors.redAccent),
          const _SectionTitle('PLAYER WISDOM', Icons.lightbulb_outline_rounded, Colors.lightGreenAccent),
          const Text(
            '• Stealing Window: you can safely steal 1 item per floor with stealth '
            'items (Grey Mauser, Decoy, Box, Chaff Grenade). Stealing without '
            'stealth shuts the shop down instantly.\n'
            '• Flawless Reset Exploit: if Bello is angered, taking the elevator '
            'down to the next floor resets his aggro and prices completely.',
            style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Shop State'),
              onPressed: () => setState(() => _aggro = 0),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _aggroBanner(String text, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color, height: 1.3),
      ),
    );
  }
}

// =============================================================================
// Tab 2: Winchester — modifier compatibility + minigame launcher
// =============================================================================

class _WinchesterTab extends StatefulWidget {
  const _WinchesterTab();
  @override
  State<_WinchesterTab> createState() => _WinchesterTabState();
}

class _WinchesterTabState extends State<_WinchesterTab> {
  bool _cloverUnlocked = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _cloverUnlocked = prefs.getBool('npc.winchester.clover') ?? false);
    } catch (_) {}
  }

  Future<void> _setClover(bool v) async {
    setState(() => _cloverUnlocked = v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('npc.winchester.clover', v);
    } catch (_) {}
  }

  static const _modifiers = <(String, String, Color)>[
    ('Remote Bullets', 'TRIVIALIZES MINIGAME. Lets you manually steer the Prize Pistol bullet with your touchscreen.', Colors.greenAccent),
    ('Wax Wings / Jetpack / Cat Throne', 'AUTO-WIN CHEAT. Fly over the pits directly point-blank into targets. No penalty!', Colors.greenAccent),
    ('Scattershot / Crutch', 'Double-Edged Sword. Splits bullets or bends angles — unpredictable trick shots but more hitbox coverage.', Colors.amberAccent),
    ('Backup Gun / Helix Bullets / Bloody 9mm', 'CRITICAL HAZARD. Drastically warps the precision line. Drop this item before paying Winchester!', Colors.redAccent),
  ];

  void _openItemDetail(BuildContext context, String title) {
    final runProvider = context.read<RunProvider>();
    final names = title.split('/').map((s) => s.trim().toLowerCase()).toList();

    // Collect all matches
    final List<Map<String, dynamic>> matches = [];
    
    for (final name in names) {
      String targetName = name;
      if (name == 'wax wings') targetName = 'wax wings';
      if (name == 'jetpack') targetName = 'jetpack';
      if (name == 'cat throne') targetName = 'cat throne';
      if (name == 'remote bullets') targetName = 'remote bullets';
      if (name == 'crutch') targetName = 'easy crutch';
      if (name == 'backup gun') targetName = 'backup gun';
      if (name == 'helix bullets') targetName = 'helix bullets';
      if (name == 'bloody 9mm') targetName = 'bloody 9mm';
      if (name == 'scattershot') targetName = 'scattershot';

      for (final it in runProvider.allItems) {
        final itName = it.name.toLowerCase();
        if (itName == targetName || itName.contains(targetName) || targetName.contains(itName)) {
          if (!matches.any((m) => m['obj'] == it)) {
            matches.add({'type': 'item', 'name': it.name, 'obj': it});
          }
        }
      }
      for (final g in runProvider.allGuns) {
        final gName = g.name.toLowerCase();
        if (gName == targetName || gName.contains(targetName) || targetName.contains(gName)) {
          if (!matches.any((m) => m['obj'] == g)) {
            matches.add({'type': 'gun', 'name': g.name, 'obj': g});
          }
        }
      }
    }

    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find detailed information for "$title".'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (matches.length == 1) {
      final match = matches.first;
      _navigateToDetail(context, match);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1C1C1E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Select an item to view:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        final isGun = match['type'] == 'gun';
                        return ListTile(
                          leading: Icon(
                            isGun ? Icons.sports_esports_rounded : Icons.extension_rounded,
                            color: isGun ? Colors.cyanAccent : Colors.amberAccent,
                          ),
                          title: Text(
                            match['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            isGun ? 'Gun' : 'Active/Passive Item',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _navigateToDetail(context, match);
                          },
                        );
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

  void _navigateToDetail(BuildContext context, Map<String, dynamic> match) {
    final isGun = match['type'] == 'gun';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          gun: isGun ? match['obj'] as Gun : null,
          item: !isGun ? match['obj'] as Item : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VerticalSwipeLayout(
      npcName: 'Winchester',
      narrativeView: const _NpcDialoguePanel(
        npcId: 'winchester',
        npcName: 'Winchester',
        gifAsset: 'assets/animations/Winchester_idle.gif',
        accentColor: Colors.pinkAccent,
        fallbackIcon: Icons.casino_rounded,
      ),
      utilityView: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NpcHeader(
            asset: 'assets/animations/Winchester_idle.gif',
            fallbackIcon: Icons.adjust_rounded,
            title: 'WINCHESTER — GAME MASTER',
            description: 'Hosts the 4-shot target-shooting minigame room for a small Casing entry fee.',
            accent: Colors.cyanAccent,
          ),
          const SizedBox(height: 16),
          // Minigame launcher
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              icon: const Icon(Icons.sports_esports_rounded),
              label: const Text(
                'PLAY THE TRICKSHOT MINIGAME',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WinchesterMinigameScreen()),
                );
              },
            ),
          ),
          const _SectionTitle('ITEM MODIFIER COMPATIBILITY', Icons.science_rounded, Colors.cyanAccent),
          for (final (name, note, color) in _modifiers)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openItemDetail(context, name),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
                            const SizedBox(height: 4),
                            Text(note, style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.3)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ),
            ),
          const _SectionTitle('LIFETIME UNLOCK TRACKER', Icons.emoji_events_rounded, Colors.amberAccent),
          InkWell(
            onTap: () => _setClover(!_cloverUnlocked),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Checkbox(
                  value: _cloverUnlocked,
                  activeColor: Colors.amberAccent,
                  onChanged: (v) => _setClover(v ?? false),
                ),
                const Expanded(
                  child: Text(
                    'Ace 3 separate trickshot galleries across your lifetime profile',
                    style: TextStyle(fontSize: 11.5, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          if (_cloverUnlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amberAccent),
              ),
              child: const Text(
                '🍀 UNLOCKED: Seven-Leaf Clover — S-Tier passives appear vastly more frequently in chests!',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.amberAccent, height: 1.3),
              ),
            ),
        ],
      ),
    ));
  }
}

// =============================================================================
// Tab 3: The Annex — spawn analytics engine
// =============================================================================

class _GungeonNpc {
  final String name;
  final double baseWeight;
  final bool needsRescue;
  final String asset;
  const _GungeonNpc(this.name, this.baseWeight, this.needsRescue, this.asset);
}

class _AnnexTab extends StatefulWidget {
  const _AnnexTab();
  @override
  State<_AnnexTab> createState() => _AnnexTabState();
}

class _AnnexTabState extends State<_AnnexTab> {
  static const _npcs = <_GungeonNpc>[
    _GungeonNpc('Muncher', 0.53, false, 'assets/animations/Evilmuncher_idle.webp'),
    _GungeonNpc('Sell Creep', 0.53, false, 'assets/animations/Sellcreep_idle.gif'),
    _GungeonNpc('Vampire', 0.25, true, 'assets/animations/Vampire_idle.gif'),
    _GungeonNpc('Old Red', 0.10, true, 'assets/animations/Oldred_idle.gif'),
    _GungeonNpc('Cursula', 0.10, true, 'assets/animations/Cursula_idle.gif'),
    _GungeonNpc('Flynt', 0.10, true, 'assets/animations/Flynt_idle.gif'),
    _GungeonNpc('Professor Goopton', 0.10, true, 'assets/animations/Goopton_idle.gif'),
    _GungeonNpc('Evil Muncher', 0.005, false, 'assets/animations/Evilmuncher_idle.webp'),
  ];
  static const _floors = ['Keep', 'Proper', 'Mines', 'Hollow', 'Secret Floors'];

  String _floor = 'Keep';
  bool _hasMasterRound = false;
  final Map<String, bool> _rescued = {
    'Vampire': true,
    'Old Red': true,
    'Cursula': true,
    'Flynt': true,
    'Professor Goopton': true,
  };

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        for (final k in _rescued.keys) {
          _rescued[k] = prefs.getBool('npc.annex.rescued.$k') ?? true;
        }
      });
    } catch (_) {}
  }

  Future<void> _setRescued(String name, bool v) async {
    setState(() => _rescued[name] = v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('npc.annex.rescued.$name', v);
    } catch (_) {}
  }

  Map<String, double> _calculate() {
    final active = <String, double>{};
    double total = 0;
    for (final npc in _npcs) {
      double w = npc.baseWeight;
      if (_floor == 'Keep' && (npc.name == 'Muncher' || npc.name == 'Evil Muncher')) w = 0;
      if (_floor != 'Hollow' && npc.name == 'Evil Muncher') w = 0;
      if (_floor == 'Hollow' && _hasMasterRound && npc.name == 'Sell Creep') w = 0;
      if (npc.needsRescue && !(_rescued[npc.name] ?? false)) w = 0;
      active[npc.name] = w;
      total += w;
    }
    return {
      for (final e in active.entries)
        e.key: total > 0 && e.value > 0 ? (e.value / total) * 100 : 0.0,
    };
  }

  void _talkToNpc(BuildContext context, _GungeonNpc npc) {
    String npcId = npc.name.toLowerCase().trim();
    if (npcId == 'professor goopton') npcId = 'goopton';
    if (npcId == 'evil muncher') npcId = 'evil_muncher';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151518),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _NpcDialoguePanel(
                  npcId: npcId,
                  npcName: npc.name,
                  gifAsset: npc.asset,
                  accentColor: npc.name == 'Evil Muncher' ? Colors.redAccent : Colors.purpleAccent,
                  fallbackIcon: Icons.person_rounded,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chances = _calculate();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NpcHeader(
            asset: 'assets/animations/Sellcreep_idle.gif',
            fallbackIcon: Icons.door_front_door_rounded,
            title: 'THE ANNEX — SIDE SHOP ANALYTICS',
            description: 'Calculates the dynamic spawn probabilities for the extra side-room vendor based on your global unlock states.',
            accent: Colors.purpleAccent,
          ),
          const _SectionTitle('RUN CONTEXT', Icons.layers_rounded, Colors.purpleAccent),
          DropdownButtonFormField<String>(
            value: _floor,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Current Floor',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: const TextStyle(fontSize: 13, color: Colors.white),
            items: [for (final f in _floors) DropdownMenuItem(value: f, child: Text(f))],
            onChanged: (v) => setState(() => _floor = v!),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Has Master Round (Sell Creep penalty in Hollow)',
                style: TextStyle(fontSize: 11.5, color: Colors.white70)),
            value: _hasMasterRound,
            activeColor: Colors.purpleAccent,
            onChanged: (v) => setState(() => _hasMasterRound = v),
          ),
          const _SectionTitle('CELL RESCUE UNLOCKS', Icons.lock_open_rounded, Colors.lightGreenAccent),
          for (final name in _rescued.keys)
            InkWell(
              onTap: () => _setRescued(name, !(_rescued[name] ?? false)),
              child: Row(
                children: [
                  Checkbox(
                    value: _rescued[name],
                    activeColor: Colors.lightGreenAccent,
                    visualDensity: VisualDensity.compact,
                    onChanged: (v) => _setRescued(name, v ?? false),
                  ),
                  Text('Cell Rescued: $name',
                      style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
                ],
              ),
            ),
          const _SectionTitle('LIVE SPAWN PROBABILITIES', Icons.percent_rounded, Colors.cyanAccent),
          for (final npc in _npcs)
            Builder(builder: (context) {
              final pct = chances[npc.name] ?? 0.0;
              final locked = pct <= 0;
              return InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _talkToNpc(context, npc),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Opacity(
                    opacity: locked ? 0.45 : 1.0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            npc.asset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, size: 16, color: Colors.white38),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 110,
                          child: Text(
                            npc.name,
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                locked ? Colors.white24 : Colors.cyanAccent,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 76,
                          child: Text(
                            locked ? '[LOCKED]' : '${pct.toStringAsFixed(2)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: locked ? Colors.white38 : Colors.cyanAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 4: Frifle & Grey Mauser quests + Daisuke challenge data
// =============================================================================

class _HuntingTab extends StatefulWidget {
  const _HuntingTab();
  @override
  State<_HuntingTab> createState() => _HuntingTabState();
}

class _HuntingTabState extends State<_HuntingTab> {
  static const _quests = <(String, int, String)>[
    ('Bullet Kin', 30, 'Rejects'),
    ('Shroomers', 30, 'Sunlight Javelin'),
    ('Ashen Bullet Kin', 25, 'Grey Mauser gun'),
    ('Mutant Shotgun Kin', 15, 'its/a/gun'),
    ('Spenders', 20, 'Huntsman'),
    ('Gunzooms', 15, 'Cat Claw'),
    ('Skullets', 15, 'Skull Spitter'),
    ('Lead Maiden', 10, 'Fleshbox'),
    ('Shambling Rounds', 15, 'Blood Brooch'),
    ('Gunjurors', 15, 'Magic Lamp'),
    ('Killpillars', 30, 'Microtransaction Gun'),
    ('Dragun', 1, 'Hunting Trophy'),
  ];

  static const _monsterIntel = <String, (String, String, String)>{
    'Bullet Kin': (
      'Keep, Gungeon Proper, Mines, Hollow, Forge, Bullet Hell',
      'Guaranteed (100% density across almost every room)',
      'Basic infantry of the Gundead. Move slowly, shoot infrequently. Kite them in circles to save ammo.'
    ),
    'Shroomers': (
      'Gungeon Proper, Oubliette, Abbey of the True Gun',
      'Common (30-45% in Fungus/Mushroom room layouts)',
      'Shoots a delayed explosive puff of spores. Stay far away and wait for the spore cloud to dissipate.'
    ),
    'Ashen Bullet Kin': (
      'Black Powder Mine, Hollow, Abbey of the True Gun',
      'Common (40-60% on Mines/Hollow, replaces normal Bullet Kin)',
      'Much faster and aggressive than normal Bullet Kin. They run directly at you, shooting immediately.'
    ),
    'Mutant Shotgun Kin': (
      'Oubliette, Gungeon Proper, Abbey',
      'Uncommon (20-30% spawn density in toxic chambers)',
      'Fires a 3-way shotgun spread. Highly resistant to knockback. Roll directly through their bullet wall.'
    ),
    'Spenders': (
      'Oubliette, Abbey of the True Gun, Hollow',
      'Moderate (30-40% in crypt and graveyard themed layouts)',
      'Melee swarmers. Extremely fast but low health. Do not get backed into a corner — use any splash/AOE weapon.'
    ),
    'Gunzooms': (
      'Black Powder Mine, Resourceful Rat\'s Lair',
      'Common (45% in minecart tracks and rail rooms)',
      'Flit diagonally at high speeds. Hard to hit with slow-firing sniper rifles. Use shotguns or beam weapons.'
    ),
    'Skullets': (
      'Hollow, Abbey of the True Gun, Bullet Hell',
      'Uncommon (25% in tomb/crypt layouts)',
      'Floating skulls that fire fast straight laser lines. Take them down first before they align their shots.'
    ),
    'Lead Maiden': (
      'Gungeon Proper, Black Powder Mine, Hollow',
      'Rare (5-10% density, usually spawns as a high-threat mini-boss)',
      'Extremely dangerous. Opens its armor shell to fire spikes that bounce off walls. Hide behind stone pillars or hard walls immediately when it opens!'
    ),
    'Shambling Rounds': (
      'Black Powder Mine, Hollow, Forge',
      'Rare (8-12% in deep underground mines)',
      'Enormous stone golems. High health. Shoots a ring of expanding bullets that split when hit. Keep moving circularly.'
    ),
    'Gunjurors': (
      'Gungeon Proper, Black Powder Mine, Hollow',
      'Uncommon (15-20% in magic/library layouts)',
      'Can grab your fired bullets and redirect them back at you! Use lasers, beams, or high-rate automatic fire which they cannot catch.'
    ),
    'Killpillars': (
      'Hollow (Chamber 4 Boss Room)',
      'Boss Encounter (100% chance if Killpillars are selected as the floor boss)',
      'Four massive pillars chasing you. Highly vulnerable to piercing, explosion, and bouncing bullet weapons which can damage multiple pillars at once.'
    ),
    'Dragun': (
      'Forge (Chamber 5 Boss Room)',
      'Boss Encounter (100% guaranteed on Forge completion)',
      'The final sentinel of the Gungeon. Phase 1: focus on the blank/blank zones. Phase 2 (Heart): dodge-roll across the bullet rows when the safe squares highlight.'
    ),
  };

  static const _challengeMods = <(String, String)>[
    ('Gulls-Eye View', 'An air strike crosshair tracks the player, firing exploding shells periodically.'),
    ('Gorgun\'s Gaze', 'A petrification wave triggers every few seconds. Turn away from the center flash to avoid being frozen.'),
    ('Hammer Time', 'An invincible Forge Hammer constantly follows and slams down on the player\'s position.'),
    ('High Stress', 'Taking damage instantly reduces health to exactly half a heart / 1 armor piece for 5 seconds.'),
  ];

  int _questIdx = 0;
  int _kills = 0;
  bool _challengeMode = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _questIdx = (prefs.getInt('npc.frifle.quest') ?? 0).clamp(0, _quests.length - 1);
        _kills = prefs.getInt('npc.frifle.kills') ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('npc.frifle.quest', _questIdx);
      await prefs.setInt('npc.frifle.kills', _kills);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final quest = _quests[_questIdx];
    final done = _kills >= quest.$2;

    return VerticalSwipeLayout(
      npcName: 'Frifle & Grey Mauser',
      narrativeView: const _NpcDialoguePanel(
        npcId: 'frifle',
        npcName: 'Frifle & Grey Mauser',
        gifAsset: 'assets/animations/Frifle_idle.gif',
        accentColor: Colors.orangeAccent,
        fallbackIcon: Icons.track_changes_rounded,
      ),
      utilityView: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NpcHeader(
            asset: 'assets/animations/Frifle_idle.gif',
            fallbackIcon: Icons.track_changes_rounded,
            title: 'FRIFLE & GREY MAUSER',
            description: 'Gives global multi-run hunting quests in exchange for Hegemony Credits and exclusive unlocks.',
            accent: Colors.orangeAccent,
          ),
          const _SectionTitle('ACTIVE HUNTING QUEST', Icons.flag_rounded, Colors.orangeAccent),
          DropdownButtonFormField<int>(
            value: _questIdx,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Quest',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: const TextStyle(fontSize: 12.5, color: Colors.white),
            items: [
              for (var i = 0; i < _quests.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text('${_quests[i].$2}× ${_quests[i].$1} → ${_quests[i].$3}'),
                ),
            ],
            onChanged: (v) {
              setState(() {
                _questIdx = v!;
                _kills = 0;
              });
              _save();
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: done ? Colors.green.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: done ? Colors.greenAccent : Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        done
                            ? 'QUEST COMPLETE! Reward: ${quest.$3}'
                            : 'Count: $_kills / ${quest.$2} ${quest.$1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: done ? Colors.greenAccent : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (_kills / quest.$2).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            done ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white60),
                  onPressed: _kills > 0
                      ? () {
                          setState(() => _kills--);
                          _save();
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white60),
                  onPressed: () {
                    setState(() => _kills++);
                    _save();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Builder(builder: (ctx) {
            final intel = _monsterIntel[quest.$1] ?? (
              'Unknown Chamber',
              'Undetermined',
              'No data available on the selected target.'
            );
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_outlined, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'QUEST INTELLIGENCE: ${quest.$1.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.orangeAccent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.45),
                      children: [
                        const TextSpan(text: 'Primary Locations:\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        TextSpan(text: '• ${intel.$1}\n\n', style: const TextStyle(color: Colors.white70)),
                        const TextSpan(text: 'Spawn Probability:\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        TextSpan(text: '• ${intel.$2}\n\n', style: const TextStyle(color: Colors.white70)),
                        const TextSpan(text: 'Tactical Advice (Wiki):\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        TextSpan(text: '• ${intel.$3}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 32),
          const _NpcHeader(
            asset: 'assets/animations/Greymauser_idle.gif',
            fallbackIcon: Icons.casino_rounded,
            title: 'DAISUKE — CHALLENGE MODIFIER',
            description: 'Activates Challenge Mode for 6 Hegemony Credits. Adds random negative status rules to every room.',
            accent: Colors.redAccent,
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Challenge Mode Active (2× Hegemony Credit payouts!)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
            value: _challengeMode,
            activeColor: Colors.redAccent,
            onChanged: (v) => setState(() => _challengeMode = v),
          ),
          const _SectionTitle('ROOM MODIFIER RISK SHEET', Icons.dangerous_rounded, Colors.redAccent),
          for (final (name, desc) in _challengeMods)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                  const SizedBox(height: 3),
                  Text(desc, style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.3)),
                ],
              ),
            ),
        ],
      ),
    ));
  }
}

// =============================================================================
// REUSABLE NPC NARRATIVE LAYER PANEL
// =============================================================================
class _NpcDialoguePanel extends StatefulWidget {
  final String npcId;
  final String npcName;
  final String gifAsset;
  final Color accentColor;
  final IconData fallbackIcon;

  const _NpcDialoguePanel({
    required this.npcId,
    required this.npcName,
    required this.gifAsset,
    required this.accentColor,
    required this.fallbackIcon,
  });

  @override
  State<_NpcDialoguePanel> createState() => _NpcDialoguePanelState();
}

class _NpcDialoguePanelState extends State<_NpcDialoguePanel> {
  DialogueNode? _node;
  bool _isLoading = true;
  int _chamberIndex = 1;
  int? _selectedResponseIdx;
  bool _isPromptTyping = true;
  bool _isReplyTyping = false;
  bool _hasMet = false;
  PlayerResponse? _rewardedResponse;

  @override
  void initState() {
    super.initState();
    _loadDialogue();
  }

  Future<void> _loadDialogue() async {
    setState(() {
      _isLoading = true;
      _selectedResponseIdx = null;
      _isPromptTyping = true;
      _isReplyTyping = false;
    });

    final met = await NpcNarrativeService.hasMetNpc(widget.npcId);
    final dialogue = await NpcNarrativeService.getDialogue(
      npcId: widget.npcId,
      chamberIndex: _chamberIndex,
    );

    if (mounted) {
      setState(() {
        _node = dialogue;
        _hasMet = met;
        _isLoading = false;
      });
    }
  }

  Future<void> _onResponseSelected(int index) async {
    Haptics.selection();
    final response = _node!.responses[index];

    setState(() {
      _selectedResponseIdx = index;
      _isReplyTyping = true;
    });

    if (response.rewardItemName != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final idClean = widget.npcId.toLowerCase().trim();
        if (idClean == 'bello') {
          if (_node!.id.contains('flynt')) {
            await prefs.setBool('npc.quest.completed.flynt_delivered', true);
          } else if (_node!.id.contains('vampire')) {
            await prefs.setBool('npc.quest.completed.vampire_delivered', true);
          } else if (_node!.id.contains('goopton')) {
            await prefs.setBool('npc.quest.completed.goopton_delivered', true);
          }
        } else {
          await prefs.setBool('npc.quest.completed.$idClean', true);
        }
      } catch (_) {}

      // Prompt the "ITEM ACQUIRED" screen shortly after the reply typewriter triggers!
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          Haptics.success();
          setState(() {
            _rewardedResponse = response;
          });
        }
      });
    }
  }

  Future<void> _onDialogueCompleted() async {
    Haptics.success();
    await NpcNarrativeService.markNpcAsMet(widget.npcId);
    _loadDialogue();
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return ValueListenableBuilder<VisualPrefs>(
          valueListenable: VisualPrefs.notifier,
          builder: (context, prefs, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DIALOGUE SETTINGS',
                        style: TextStyle(
                          fontFamily: 'EnterTheGungeonBig',
                          fontSize: 14,
                          color: widget.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  
                  // Toggle haptics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Typewriter Haptic Ticks',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Vibrate briefly as letters print on-screen',
                            style: TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                        ],
                      ),
                      Switch(
                        value: prefs.dialogueHapticsEnabled,
                        activeColor: widget.accentColor,
                        onChanged: (v) {
                          Haptics.selection();
                          VisualPrefs.setDialogueHapticsEnabled(v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Text speed options
                  const Text(
                    'TEXT SCROLL SPEED',
                    style: TextStyle(
                      fontFamily: 'EnterTheGungeonBig',
                      fontSize: 10,
                      color: Colors.white54,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSpeedButton('INSTANT', 0, prefs),
                      _buildSpeedButton('FAST', 12, prefs),
                      _buildSpeedButton('NORMAL', 30, prefs),
                      _buildSpeedButton('SLOW', 60, prefs),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpeedButton(String label, int ms, VisualPrefs prefs) {
    final isSelected = prefs.dialogueTextSpeedMs == ms;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? widget.accentColor.withValues(alpha: 0.08) : Colors.transparent,
            side: BorderSide(
              color: isSelected ? widget.accentColor : Colors.white24,
              width: isSelected ? 1.8 : 1.0,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            Haptics.light();
            VisualPrefs.setDialogueTextSpeedMs(ms);
          },
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isSelected ? widget.accentColor : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _node == null) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white30)),
      );
    }

    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Floor/Chamber Selector & Settings Bar (Top-Right - Enlarged for Accessibility!)
          Positioned(
            top: 14,
            right: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialogue & Typewriter Tuning Icon Button
                GestureDetector(
                  onTap: () {
                    Haptics.light();
                    _showSettingsModal(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.accentColor.withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: widget.accentColor,
                      size: 18, // Bigger settings gear icon!
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Floor Selector (Larger, beveled touch targets)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: widget.accentColor.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'FLOOR:',
                          style: TextStyle(
                            fontFamily: 'EnterTheGungeonBig',
                            fontSize: 11, // Larger text!
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      for (int i = 1; i <= 5; i++)
                        GestureDetector(
                          onTap: () {
                            Haptics.light();
                            setState(() {
                              _chamberIndex = i;
                            });
                            _loadDialogue();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 32, // Grown from 20 -> super clear tap target!
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _chamberIndex == i ? widget.accentColor : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _chamberIndex == i ? Colors.transparent : Colors.white10,
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              '$i',
                              style: TextStyle(
                                fontSize: 13, // Larger numbers
                                fontWeight: FontWeight.w900,
                                color: _chamberIndex == i ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Met badge indicators on Top-Left (Enlarged)
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _hasMet ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _hasMet ? Colors.greenAccent : Colors.amberAccent, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _hasMet ? 'MET ONCE' : 'FIRST ENCOUNTER',
                style: TextStyle(
                  fontFamily: 'EnterTheGungeonBig',
                  fontSize: 10, // Larger badge text!
                  fontWeight: FontWeight.bold,
                  color: _hasMet ? Colors.greenAccent : Colors.amberAccent,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // 3. Center Layer: Animated NPC Sprite with Platform Glow (200%+ Enlaraged & Vertically Anchored!)
          Positioned(
            top: screenHeight * 0.16,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: const BorderRadius.all(Radius.elliptical(110, 8)),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.7),
                            blurRadius: 35,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 240, // Expanded by 200%+ for massive, gorgeous detail!
                      height: 160,
                      margin: const EdgeInsets.only(bottom: 25),
                      child: Image.asset(
                        widget.gifAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none, // Strict pixel art enforcement
                        errorBuilder: (_, __, ___) => Icon(
                          widget.fallbackIcon,
                          size: 110, // Matching giant fallback icon size
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Bottom Layer: Branching Dialogue & Input Response (Rock-Solid Fixed Height!)
          Positioned(
            bottom: 24,
            left: 12,
            right: 12,
            child: SizedBox(
              height: 310, // Strict, non-shifting dialog box height boundary!
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Chamber A: Non-shifting dialogue bubble
                  SizedBox(
                    height: 110,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(), // Absolutely locked
                      child: _selectedResponseIdx == null
                          ? AnimatedChatBubble(
                              key: ValueKey('prompt_${_node!.id}_$_chamberIndex'),
                              fullText: _node!.prompt,
                              icon: widget.fallbackIcon,
                              iconColor: widget.accentColor,
                              borderColor: widget.accentColor,
                              onCompleted: () {
                                if (mounted) {
                                  setState(() {
                                    _isPromptTyping = false;
                                  });
                                }
                              },
                            )
                          : AnimatedChatBubble(
                              key: ValueKey('reply_${_node!.id}_$_selectedResponseIdx'),
                              fullText: _node!.responses[_selectedResponseIdx!].reply,
                              icon: Icons.chat_bubble_outline_rounded,
                              iconColor: widget.accentColor,
                              borderColor: widget.accentColor.withValues(alpha: 0.5),
                              onCompleted: () {
                                if (mounted) {
                                  setState(() {
                                    _isReplyTyping = false;
                                  });
                                }
                              },
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Chamber B: Dedicated inputs area (options and confirmation buttons)
                  SizedBox(
                    height: 180,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOutQuad,
                        switchOutCurve: Curves.easeInQuad,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.08),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _buildAnswerContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 5. Secret Item Acquired Immersive Overlay!
          if (_rewardedResponse != null)
            _buildItemAcquiredOverlay(_rewardedResponse!),
        ],
      ),
    );
  }

  Widget _buildAnswerContent() {
    if (_isPromptTyping) {
      return const SizedBox.shrink(); // Pure empty placeholder while typing
    }

    if (_selectedResponseIdx == null) {
      return Column(
        key: const ValueKey('response_options'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _node!.responses.length; i++)
            _buildResponseButton(i, _node!.responses[i]),
        ],
      );
    } else {
      if (_isReplyTyping) {
        return const SizedBox.shrink();
      } else {
        return Center(
          key: const ValueKey('dialog_completion_btn'),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _onDialogueCompleted,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 4,
              ),
              child: const Text(
                'TALK AGAIN',
                style: TextStyle(
                  fontFamily: 'EnterTheGungeonBig',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  Widget _buildResponseButton(int index, PlayerResponse response) {
    Color btnColor;
    Color borderHighlight;
    String toneLabel;

    switch (response.tone) {
      case 'PEP':
        btnColor = const Color(0xFF4CAF50); // Friendly green
        borderHighlight = Colors.greenAccent;
        toneLabel = '[PEPPY]';
        break;
      case 'TOUGH':
        btnColor = const Color(0xFFFF5722); // Aggressive action red
        borderHighlight = Colors.deepOrangeAccent;
        toneLabel = '[TOUGH]';
        break;
      case 'DEMENTED':
        btnColor = const Color(0xFF9C27B0); // Deep magic purple
        borderHighlight = Colors.purpleAccent;
        toneLabel = '[UNHINGED]';
        break;
      default:
        btnColor = Colors.grey;
        borderHighlight = Colors.white;
        toneLabel = '';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black87,
          side: BorderSide(color: btnColor.withValues(alpha: 0.8), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _onResponseSelected(index),
        child: Row(
          children: [
            Text(
              toneLabel,
              style: TextStyle(
                fontFamily: 'EnterTheGungeonBig',
                fontSize: 8.5,
                color: borderHighlight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                response.text,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemAcquiredOverlay(PlayerResponse response) {
    IconData iconData = Icons.star_rounded;
    if (response.rewardItemIcon == 'vpn_key_rounded') iconData = Icons.vpn_key_rounded;
    if (response.rewardItemIcon == 'science_rounded') iconData = Icons.science_rounded;
    if (response.rewardItemIcon == 'token_rounded') iconData = Icons.token_rounded;
    if (response.rewardItemIcon == 'biotech_rounded') iconData = Icons.biotech_rounded;
    if (response.rewardItemIcon == 'favorite_rounded') iconData = Icons.favorite_rounded;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.90),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF131316),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.accentColor, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Text(
                  '★ SECRET ITEM ACQUIRED ★',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'EnterTheGungeonBig',
                    fontSize: 14,
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: widget.accentColor.withValues(alpha: 0.8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  _PoofParticles(color: widget.accentColor),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.accentColor.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Icon(
                      iconData,
                      color: widget.accentColor,
                      size: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                response.rewardItemName!.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'EnterTheGungeonBig',
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  response.rewardItemDesc!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Haptics.success();
                    setState(() {
                      _rewardedResponse = null;
                    });
                    _loadDialogue();
                  },
                  child: const Text(
                    'EQUIP TO RUN COMPANION',
                    style: TextStyle(
                      fontFamily: 'EnterTheGungeonBig',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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

class _PoofParticles extends StatefulWidget {
  final Color color;
  const _PoofParticles({required this.color});

  @override
  State<_PoofParticles> createState() => _PoofParticlesState();
}

class _PoofParticlesState extends State<_PoofParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
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
      builder: (context, _) {
        return CustomPaint(
          painter: _PoofPainter(
            progress: _controller.value,
            color: widget.color,
          ),
          size: const Size(120, 120),
        );
      },
    );
  }
}

class _PoofPainter extends CustomPainter {
  final double progress;
  final Color color;

  _PoofPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final math.Random rng = math.Random(1337);

    for (int i = 0; i < 10; i++) {
      final double angle = i * 2 * math.pi / 10 + rng.nextDouble() * 0.2;
      final double distance = progress * 40.0 + rng.nextDouble() * 10.0;
      final double radius = (1.0 - progress) * 15.0 + 3.0;
      
      final double x = center + math.cos(angle) * distance;
      final double y = center + math.sin(angle) * distance;
      
      final paint = Paint()
        ..color = color.withValues(alpha: (1.0 - progress) * 0.6)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), radius, paint);

      if (i % 2 == 0) {
        final innerPaint = Paint()
          ..color = Colors.white.withValues(alpha: (1.0 - progress) * 0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), radius * 0.6, innerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_PoofPainter old) => old.progress != progress;
}
