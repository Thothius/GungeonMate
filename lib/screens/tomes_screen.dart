import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_theme.dart';
import '../providers/run_provider.dart';
import '../models/gun.dart';
import '../models/item.dart';
import 'item_detail_screen.dart';
import 'winchester_minigame_screen.dart';

class TomesScreen extends StatefulWidget {
  const TomesScreen({super.key});

  @override
  State<TomesScreen> createState() => _TomesScreenState();
}

class _TomesScreenState extends State<TomesScreen> {
  int _activeTab = 0; // 0 = Stealing, 1 = Winchester, 2 = Gundead, 3 = Bosses
  double _curseSliderVal = 0.0;

  void _openItemDetail(BuildContext context, String title) {
    final runProvider = context.read<RunProvider>();
    final names = title.split('/').map((s) => s.trim().toLowerCase()).toList();

    // Collect all matches
    final List<Map<String, dynamic>> matches = [];
    
    for (final name in names) {
      // Special hand-wired alias checks for robust matches
      String targetName = name;
      if (name == 'box') targetName = 'the box';
      if (name == 'decoy') targetName = 'decoy';
      if (name == 'explosive decoy') targetName = 'explosive decoy';
      if (name == 'charm horn') targetName = 'charmed horn';
      if (name == 'directional pad') targetName = 'd-pad';
      if (name == 'wax wings') targetName = 'wax wings';
      if (name == 'jetpack') targetName = 'jetpack';
      if (name == 'cat throne') targetName = 'cat throne';
      if (name == 'crutch') targetName = 'easy crutch';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GUNGEON TOMES',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Custom Tab Rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: 'STEALING',
                        icon: Icons.visibility_off,
                        active: _activeTab == 0,
                        onTap: () => setState(() => _activeTab = 0),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _TabButton(
                        label: 'WINCHESTER',
                        icon: Icons.gamepad,
                        active: _activeTab == 1,
                        onTap: () => setState(() => _activeTab = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: 'GUNDEAD',
                        icon: Icons.android,
                        active: _activeTab == 2,
                        onTap: () => setState(() => _activeTab = 2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _TabButton(
                        label: 'BOSSES',
                        icon: Icons.dangerous_rounded,
                        active: _activeTab == 3,
                        onTap: () => setState(() => _activeTab = 3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: _activeTab == 0
                ? _buildStealingTome()
                : (_activeTab == 1
                    ? _buildWinchesterTome()
                    : (_activeTab == 2 ? _buildGundeadTome() : _buildBossAlmanacTome())),
          ),
        ],
      ),
    );
  }

  Widget _buildStealingTome() {
    final stealingItems = [
      ('Box', 'Active Item', 'Hide inside the box. Walk up to shop items to steal them cleanly while hidden.'),
      ('Decoy / Explosive Decoy', 'Active Item', 'Spawns a decoy. Bello targets the decoy, allowing you to steal items behind his back.'),
      ('Grappling Hook', 'Active Item', 'Fires a hook to grab any item from a distance. If you are far enough, success rate is high.'),
      ('Chaff Grenade', 'Active Item', 'Blinds Bello for a few seconds. Walk up and grab items while he is dazed.'),
      ('Smoke Bomb', 'Active Item', 'Grants temporary invisibility. Easily grab items with zero detection.'),
      ('Ring of Ethereal Form', 'Active Item', 'Grants phase/invisibility. Bello cannot see you stealing.'),
      ('Aged Bell', 'Active Item', 'Freezes time. Walk up and freely take any item from the counter.'),
      ('Grey Mauser', 'Gun', 'Reloading while empty grants temporary invisibility. Steal items while invisible.'),
      ('Predator', 'Gun', 'Holding this gun or firing it can grant invisibility. Highly spammable for steals.'),
      ('Charm Horn', 'Active Item', 'Charms all shopkeepers, allowing a 100% free steal without raising alert.'),
      ('Directional Pad', 'Gun', 'Fires a grappling hook on the 3rd press of the combo. Can pull items to you.'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rules Card
        Card(
          color: Colors.purple.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.purple.withValues(alpha: 0.35), width: 1.2),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.purpleAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'THE LAWS OF STEALING',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.purpleAccent,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  '1. The first steal attempt on any floor has a 100% SUCCESS RATE.\n'
                  '2. Subsequent steal attempts on the same floor have a much lower success rate.\n'
                  '3. Getting caught makes Bello shoot at you and CLOSE HIS SHOP for the rest of the run.\n'
                  '4. Stealing increases your CURSE by 1.0 per item. Use carefully!',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'STEALING WEAPONS & ITEMS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in stealingItems)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openItemDetail(context, item.$1),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.amberAccent,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.$2,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$3,
                      style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.8), height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWinchesterTome() {
    final winchesterItems = [
      ('Wax Wings / Jetpack / Cat Throne', 'Flight Items', 'Grants permanent flight. Fly directly to the targets and shoot them point-blank for an instant flawless victory!'),
      ('Ring of Ethereal Form', 'Invisibility/Phase', 'Allows you to fly and pass through block walls directly to the target targets.'),
      ('Remote Bullets', 'Bullet Guidance', 'Allows you to dynamically steer Winchester\'s bullets mid-air using your movement joystick. Makes hitting targets effortless.'),
      ('Homing Bullets / Crutch', 'Homing Projectiles', 'Winchester\'s bouncing projectile will automatically home in on targets upon getting close.'),
      ('Bouncing Bullets', 'Bouncing Projectiles', 'Increases bullet bounce count, giving you a huge margin of safety for angled shots.'),
      ('Backup Gun', 'Double Fire', 'Fires an extra bullet backwards. Greatly increases target coverage and accidental hit rate.'),
      ('Aged Bell', 'Time Freeze', 'Freeze time while the Winchester bullet is flying, letting you guide or track its bounces perfectly.'),
      ('Bloodied Scarf', 'Teleportation', 'Teleport past obstacles directly next to targets to fire at them from point-blank range.'),
      ('Sponge', 'Water Absorption', 'Cleanses or absorbs block liquids that might obstruct standard trajectories.'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rules Card
        Card(
          color: Colors.blue.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.blueAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'WINCHESTER\'S GAME RULEBOOK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.blueAccent,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '1. Winchester gives you 4 shots to hit 4 targets. You cannot use normal guns.\n'
                  '2. Getting a Perfect (4/4 targets) rewards you with a Black or Red chest!\n'
                  '3. Passive upgrades (flight, homing, bounces) apply directly to Winchester\'s gun!\n'
                  '4. Using flight to fly up and shoot targets point-blank is the safest way to guarantee a Black chest.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Colors.white),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.25),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.blueAccent, width: 1.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.gamepad_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'PLAY TRICKSHOT GALLERY',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WinchesterMinigameScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'WINCHESTER CHEATS & AIDS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in winchesterItems)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openItemDetail(context, item.$1),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.blueAccent,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.$2,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$3,
                      style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.8), height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGundeadTome() {
    final monsters = const [
      _GundeadMonster(
        name: 'Bullet Kin',
        description: 'Bullet Kin are the most common enemies in the Gungeon. They slowly walk towards the player and occasionally fire a single bullet.',
        hp: {'Chamber 1': 15, 'Oubliette': 20, 'Chamber 2': 20, 'Abbey': 25, 'Chamber 3': 24, 'Chamber 4': 28, 'Chamber 5/6': 32},
        locations: 'All Chambers (1 to 6)',
        ammonomicon: 'Basic Infantry. These sentient shells make up the vanguard of the Gundead. Their numbers are legion. Unaffected by the passage of time, they guard the Gungeon for eternity.',
      ),
      _GundeadMonster(
        name: 'Cubulon',
        description: 'Cubulons slowly float towards the player, frequently firing bullets in all directions in a diamond shape. While preparing an attack, they are immune to knockback.',
        hp: {'Chamber 1': 30, 'Oubliette': 40, 'Chamber 2': 39, 'Abbey': 50, 'Chamber 3': 48, 'Chamber 4': 56, 'Chamber 5/6': 63},
        locations: 'Gungeon Proper, Black Powder Mine, Hollow, Forge, Oubliette, Abbey, Bullet Hell, Rat\'s Lair',
        ammonomicon: 'Geometric Threat. Born from a geometric miscalculation in the Forge, these blocks drift slowly, radiating projectiles in symmetrical formations.',
      ),
      _GundeadMonster(
        name: 'Shotgun Kin',
        description: 'Shotgun Kin fire a 3-bullet spread with their shotguns. Red Shotgun Kin have higher health and fire a wider, more hazardous spread.',
        hp: {'Chamber 1': 30, 'Oubliette': 40, 'Chamber 2': 39, 'Abbey': 50, 'Chamber 3': 48, 'Chamber 4': 56, 'Chamber 5/6': 63},
        locations: 'All Chambers (1 to 6)',
        ammonomicon: 'Scattershot Enforcer. Heavy-set and slow-moving, these enforcers cover wide choke points with dense lead sheets. They are stubborn and rarely retreat.',
      ),
      _GundeadMonster(
        name: 'Lead Maiden',
        description: 'Lead Maidens are heavily armored sarcophagi. They open up to shoot piercing arrows that bounce off walls, and are invulnerable when closed.',
        hp: {'Chamber 1': 70, 'Oubliette': 90, 'Chamber 2': 90, 'Abbey': 115, 'Chamber 3': 110, 'Chamber 4': 125, 'Chamber 5/6': 140},
        locations: 'Gungeon Proper, Black Powder Mine, Hollow, Forge, Abbey of the True Gun',
        ammonomicon: 'Iron Sarcophagus of Lead. A terrifying relic of the pre-Gundead age. Its shell is impervious to all basic armaments when closed. Beware of its bounce trajectories!',
      ),
      _GundeadMonster(
        name: 'Gunjuror',
        description: 'Gunjurors wear wizard robes and cast rotating spell circles of bullets. If you shoot them while they are casting, they catch your bullets and redirect them back.',
        hp: {'Chamber 1': 25, 'Oubliette': 33, 'Chamber 2': 32, 'Abbey': 41, 'Chamber 3': 40, 'Chamber 4': 46, 'Chamber 5/6': 52},
        locations: 'Gungeon Proper, Black Powder Mine, Hollow, Oubliette',
        ammonomicon: 'Lead Magus. Apprentices of the high wizard, they manipulate kinetic velocities to capture and reflect projectile fire.',
      ),
      _GundeadMonster(
        name: 'Blobulon',
        description: 'Blobulons are squishy gelatinous cubes that bounce around. When killed, they split into smaller, faster Blobuloids.',
        hp: {'Chamber 1': 20, 'Oubliette': 26, 'Chamber 2': 26, 'Abbey': 33, 'Chamber 3': 32, 'Chamber 4': 37, 'Chamber 5/6': 42},
        locations: 'Keep of the Lead Lord, Oubliette, Gungeon Proper, Abbey of the True Gun',
        ammonomicon: 'Gelatinous Invader. An ancient life form composed of pure gunpowder jelly. Simple-minded and bouncy, they are attracted to heat.',
      ),
      _GundeadMonster(
        name: 'Pinhead',
        description: 'Pinheads are suicidal kamikaze shells carrying giant cartoon bombs. They run directly at the player and explode upon getting close or taking damage.',
        hp: {'Chamber 1': 15, 'Oubliette': 20, 'Chamber 2': 20, 'Abbey': 25, 'Chamber 3': 24, 'Chamber 4': 28, 'Chamber 5/6': 32},
        locations: 'Keep, Gungeon Proper, Black Powder Mine, Hollow, Forge',
        ammonomicon: 'Short Fuse. These unstable shells carry an explosive payload and have a single-minded desire to end their own existence in a blaze of glory.',
      ),
      _GundeadMonster(
        name: 'Rubber Kin',
        description: 'Rubber Kin do not deal damage. Instead, they bounce around rapidly and try to bump the player into pits or environmental hazards.',
        hp: {'Chamber 1': 10, 'Oubliette': 15, 'Chamber 2': 13, 'Abbey': 17, 'Chamber 3': 16, 'Chamber 4': 18, 'Chamber 5/6': 21},
        locations: 'Keep of the Lead Lord, Gungeon Proper, Black Powder Mine, Abbey',
        ammonomicon: 'Bounce Force. Bouncy rubber cylinders designed specifically to push Gungeoneers off the ledge. Harmless on their own, but fatal near ledges.',
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.25,
      ),
      itemCount: monsters.length,
      itemBuilder: (context, index) {
        final m = monsters[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openGundeadDetail(context, m),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, color: Color(0xFFFF455B), size: 28),
                  const SizedBox(height: 8),
                  Text(
                    m.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'TAP FOR WIKI STATS',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                      letterSpacing: 0.3,
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

  void _openGundeadDetail(BuildContext context, _GundeadMonster monster) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF15191E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Red/Pink Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF455B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        monster.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Icon(Icons.security, color: Colors.white, size: 20),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      const Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white54,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        monster.description,
                        style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      
                      // Statistics Section (Exactly like the wiki image!)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E232A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                monster.name.toUpperCase(),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFFF455B)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'STATISTICS — HEALTH POOL:',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            // Health Grid Table (like wiki image!)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Table(
                                defaultColumnWidth: const FixedColumnWidth(62),
                                border: TableBorder.all(color: Colors.white24, width: 1.0, borderRadius: BorderRadius.circular(4)),
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(color: Colors.white10),
                                    children: [
                                      for (final col in monster.hp.keys)
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Center(
                                              child: Text(
                                                col.replaceFirst('Chamber ', ''),
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      for (final val in monster.hp.values)
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Center(
                                              child: Text(
                                                '$val',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFFFD54F)),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'LOCATIONS:',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              monster.locations,
                              style: const TextStyle(fontSize: 11.5, color: Colors.white, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      
                      const Divider(color: Colors.white12, height: 24),
                      
                      // Ammonomicon entry Text
                      const Text(
                        'AMMONOMICON ENTRY',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white54,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1216),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.25), width: 1.0),
                        ),
                        child: Text(
                          monster.ammonomicon,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.amberAccent,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Close button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'CLOSE ENTRY',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBossAlmanacTome() {
    final bosses = const [
      // Chamber 1
      _BossData(
        name: 'Bullet King',
        chamber: 1,
        chamberName: 'Keep of the Lead Lord',
        baseHp: 950,
        asset: 'assets/animations/bosses/Bullet_King.webp',
        tacticalExploits: [
          'Purposely leaving his Chancellor alive carries the minion over to populate the next floor\'s boss encounter or double up a future King fight.',
          'Striking his Chancellor with a Casey bat creates an instant-kill projectile that destroys the King in a single hit from full health.',
          'The massive splitting fireball attack can be physically neutralized and broken mid-air using Blasphemy sword swings.',
          'Sweep attack: When he fires a massive circle of bullets that splits, dodge roll backward or weave without rolling.'
        ],
      ),
      _BossData(
        name: 'Gatling Gull',
        chamber: 1,
        chamberName: 'Keep of the Lead Lord',
        baseHp: 700,
        asset: 'assets/animations/bosses/Gatling_Gull.webp',
        tacticalExploits: [
          'Drops below low health trigger stackable speed and fire-rate enrage status modifiers.',
          'A completely fresh save profile automatically locks his arena to the 2 Chandeliers and 8 Tables configuration.',
          'If the arena contains pillars or bushes, stay glued behind them; his minigun tracking completely breaks against solid obstacles.',
          'Dodge rolling when backing away at close proximity drops you directly into his frame lag trail; always circle strafe far away first.'
        ],
      ),
      _BossData(
        name: 'Trigger Twins (Smiley & Shades)',
        chamber: 1,
        chamberName: 'Keep of the Lead Lord',
        baseHp: 1200,
        asset: 'assets/animations/bosses/Trigger_Twins.webp',
        tacticalExploits: [
          'Whichever twin survives the other\'s death heals half of their total individual health pool, and gets an aggressive attack speed modifier.',
          'Always balance their health pools and kill them close together to avoid facing an enraged buffed survivor!',
          'Both twins periodically whistle to pull Bullet Kin additions into the arena. Keep an eye on spawns to clear them early.'
        ],
      ),
      // Chamber 2
      _BossData(
        name: 'Ammoconda',
        chamber: 2,
        chamberName: 'Gungeon Proper',
        baseHp: 900,
        asset: 'assets/animations/bosses/Ammoconda.webp',
        tacticalExploits: [
          'He spawns static "Superball" pods on the floor. If Ammoconda paths over and eats a pod, he heals, gains armored defense, and receives a massive speed boost. Shoot them immediately!',
          'Health is distributed across independent tracking tail segments.',
          'Weapons like Sunlight Javelin require direct head collisions to apply DOT debuffs; striking body segments nullifies elemental triggers.'
        ],
      ),
      _BossData(
        name: 'The Beholster',
        chamber: 2,
        chamberName: 'Gungeon Proper',
        baseHp: 1300,
        asset: 'assets/animations/bosses/Beholster.webp',
        tacticalExploits: [
          'Homing missiles carry independent small hitboxes. Use a beam or shot-scatter weapon to sweep them down before tracking his primary frame.',
          'Eye Sweep: Do not run sideways away from the giant purple tracking laser; roll directly through the beam to clear its active intersection.',
          'Bring a piercing gun to automatically swat down homing missiles and floating eyeball spawns.'
        ],
      ),
      _BossData(
        name: 'The Gorgun',
        chamber: 2,
        chamberName: 'Gungeon Proper',
        baseHp: 1400,
        asset: 'assets/animations/bosses/The_Gorgun.webp',
        tacticalExploits: [
          'Screech wave: When her turquoise stun pulse expands, face the opposite direction of the screen or time a slide right as it intersects your position.',
          'Poison trail: When she dives under the floor leaving a green trail, stay back; touching the poison liquid inflicts damage over time.'
        ],
      ),
      // Chamber 3
      _BossData(
        name: 'Cannonbalrog',
        chamber: 3,
        chamberName: 'Black Powder Mine',
        baseHp: 1750,
        asset: 'assets/animations/bosses/Cannonbalrog.webp',
        tacticalExploits: [
          'Blind Center Pocket: During his pitch-black room-rolling phase, the geometric bounce lines spread wider the further they travel. Standing directly in the center of the screen offers the widest safety gaps.',
          'Dodge roll through his giant rolling ball form if you get trapped near walls.'
        ],
      ),
      _BossData(
        name: 'Mine Flayer',
        chamber: 3,
        chamberName: 'Black Powder Mine',
        baseHp: 1450,
        asset: 'assets/animations/bosses/Mine_Flayer.webp',
        tacticalExploits: [
          'Wall Dispersion Math: His claymore mines expand outward. Hugging the absolute bottom or top walls of the arena maximizes the distance between individual mines, letting you slip between them without rolling.',
          'Weave between expanding bell-ringing circles without rolling to avoid landing lag vulnerability.'
        ],
      ),
      _BossData(
        name: 'Treadnaught',
        chamber: 3,
        chamberName: 'Black Powder Mine',
        baseHp: 1800,
        asset: 'assets/animations/bosses/Treadnaught.webp',
        tacticalExploits: [
          'Kite Route Strategy: Never stop walking in a massive rectangle along the perimeter of the room. Standing still is fatal due to tank shell explosion splashes.',
          'Clear spawns first; Treadnaught\'s tank artillery breaks environment pillars, leaving you exposed to bullets.'
        ],
      ),
      // Chamber 4
      _BossData(
        name: 'High Priest',
        chamber: 4,
        chamberName: 'Hollow',
        baseHp: 2200,
        asset: 'assets/animations/bosses/High_Priest.webp',
        tacticalExploits: [
          'Off-screen Homing Hazard: During his total shadow-shroud phase, homing bullet nodes enter the arena directly from the outer wall borders. Keep a defensive blank handy.',
          'Always remain near the bottom of the screen to maximize reaction time for homing skulls.'
        ],
      ),
      _BossData(
        name: 'Kill Pillars',
        chamber: 4,
        chamberName: 'Hollow',
        baseHp: 2400,
        asset: 'assets/animations/bosses/Kill_Pillars.webp',
        tacticalExploits: [
          'Radial Jump Rope: When they merge into the center to spin out a bullet wheel, track the spokes. Jumping over spokes is easier if you stay closer to the outer edges.',
          'Extremely vulnerable to piercing, explosive, and bouncing weapons (like Grenade Launcher or Hexrifle) which hit multiple pillars at once.',
          'When only one pillar survives, it gains a stomping jump attack. Roll laterally when it lands.'
        ],
      ),
      _BossData(
        name: 'Wallmonger',
        chamber: 4,
        chamberName: 'Hollow',
        baseHp: 3000,
        asset: 'assets/animations/bosses/Wallmonger.webp',
        tacticalExploits: [
          'Fire Divide Trick: He moves down vertically splitting the room with a wide strip of fire. Use a liquid gun to extinguish it, or time a clean horizontal roll over the split line.',
          'Never dodge roll forward; he constantly forces the player down, making forward rolls highly dangerous.'
        ],
      ),
      // Chamber 5
      _BossData(
        name: 'High Dragun',
        chamber: 5,
        chamberName: 'Forge',
        baseHp: 3500,
        asset: 'assets/animations/bosses/High_Dragun.webp',
        tacticalExploits: [
          'Second Phase Grid: When his heart appears and sweeping bullet waterfalls blanket the screen, your dodge roll should only go horizontally left-to-right into safe highlighted zones. Do not move vertically.',
          'Avoid corners during Phase 1 to prevent getting trapped by bouncing skull fireballs.'
        ],
      ),
    ];

    final jammedChance = _curseSliderVal * 2.0;

    return Column(
      children: [
        // Pinned Curse Overlay Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: Colors.red.withValues(alpha: 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dangerous, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'ACTIVE CURSE TRACKER: ${_curseSliderVal.toInt()}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  Text(
                    jammedChance == 0
                        ? '0% JAMMED BOSS CHANCE'
                        : (jammedChance >= 20.0 
                            ? '100% GUARANTEED JAMMED!' 
                            : 'JAMMED CHANCE: ${jammedChance.toStringAsFixed(0)}%'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: jammedChance > 0 ? Colors.redAccent : Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.redAccent,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: Colors.redAccent,
                  overlayColor: Colors.red.withValues(alpha: 0.2),
                ),
                child: Slider(
                  min: 0.0,
                  max: 10.0,
                  divisions: 10,
                  value: _curseSliderVal,
                  onChanged: (v) => setState(() => _curseSliderVal = v),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),

        // Scrollable Boss Almanac List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bosses.length,
            itemBuilder: (context, index) {
              final m = bosses[index];
              final isJammed = _curseSliderVal > 0;
              final jammedHp = (m.baseHp * 1.2) + 100;
              
              return _BossCard(
                boss: m,
                isJammed: isJammed,
                jammedHp: jammedHp.toInt(),
                jammedChance: jammedChance.toInt(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BossCard extends StatefulWidget {
  final _BossData boss;
  final bool isJammed;
  final int jammedHp;
  final int jammedChance;
  const _BossCard({
    required this.boss,
    required this.isJammed,
    required this.jammedHp,
    required this.jammedChance,
  });

  @override
  State<_BossCard> createState() => _BossCardState();
}

class _BossCardState extends State<_BossCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.boss;
    final themeColor = widget.isJammed ? Colors.redAccent : Colors.lightGreenAccent;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          // Header (Tappable to expand)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Boss Avatar WebP
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        b.asset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.dangerous_rounded, color: Colors.white24, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Boss Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHAMBER ${b.chamber}: ${b.chamberName.toUpperCase()}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          b.name,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: themeColor),
                        ),
                        const SizedBox(height: 4),
                        // Dual HP Display
                        Row(
                          children: [
                            Text(
                              'Base HP: ${b.baseHp}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                            if (widget.isJammed) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Jammed HP: ${widget.jammedHp}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                  shadows: [
                                    Shadow(color: Color(0x99FF0000), blurRadius: 4),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: themeColor.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          
          // Collapsible Exploits Sheet
          if (_expanded)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: themeColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'TACTICAL CHEAT SHEET & EXPLOITS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: themeColor, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final tip in b.tacticalExploits)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: themeColor, fontSize: 14, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.isJammed) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.redAccent, size: 14),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'JAMMED WARNING: All attacks deal 1 FULL HEART of damage!',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BossData {
  final String name;
  final int baseHp;
  final int chamber;
  final String chamberName;
  final String asset;
  final List<String> tacticalExploits;
  const _BossData({
    required this.name,
    required this.baseHp,
    required this.chamber,
    required this.chamberName,
    required this.asset,
    required this.tacticalExploits,
  });
}

class _GundeadMonster {
  final String name;
  final String description;
  final Map<String, int> hp;
  final String locations;
  final String ammonomicon;
  const _GundeadMonster({
    required this.name,
    required this.description,
    required this.hp,
    required this.locations,
    required this.ammonomicon,
  });
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flair;
    return Material(
      color: active ? f.primary.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.02),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? f.primary : Colors.white12,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? f.primary : Colors.white54),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: active ? f.primary : Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
