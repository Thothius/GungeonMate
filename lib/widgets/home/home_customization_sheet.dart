import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/home_customization.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';
import '../../utils/asset_paths.dart';

/// Which section of the customization sheet to focus on open.
enum HomeCustomSection { gungeoneer, junk }

/// Bottom sheet for home-screen customization: pick the vortex
/// gungeoneer (or RNG cycle / off) and configure which junk pickups drift
/// through the vortex and how many of each.
class HomeCustomizationSheet extends StatefulWidget {
  final HomeCustomSection initialSection;
  const HomeCustomizationSheet({super.key, this.initialSection = HomeCustomSection.gungeoneer});

  @override
  State<HomeCustomizationSheet> createState() => _HomeCustomizationSheetState();
}

class _HomeCustomizationSheetState extends State<HomeCustomizationSheet> {
  late HomeCustomSection _section;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HomeCustomization>(
      valueListenable: HomeCustomization.notifier,
      builder: (context, cust, _) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(color: Color(0xFFBCA0F8), width: 1.2),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grabber
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title + section toggle
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: Color(0xFFBCA0F8), size: 20),
                    const SizedBox(width: 8),
                    const GoopText(
                      'CUSTOMIZE HOME',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    _SectionChip(
                      label: 'Gungeoneer',
                      active: _section == HomeCustomSection.gungeoneer,
                      onTap: () => setState(() => _section = HomeCustomSection.gungeoneer),
                    ),
                    const SizedBox(width: 6),
                    _SectionChip(
                      label: 'Junk',
                      active: _section == HomeCustomSection.junk,
                      onTap: () => setState(() => _section = HomeCustomSection.junk),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 18),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _section == HomeCustomSection.gungeoneer
                        ? _GungeoneerPicker(cust: cust)
                        : _JunkSettings(cust: cust),
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

// =============================================================================
// Section chip
// =============================================================================

class _SectionChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SectionChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { Haptics.selection(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFBCA0F8).withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFFBCA0F8).withValues(alpha: 0.7) : Colors.white24,
            width: active ? 1.2 : 0.8,
          ),
        ),
        child: GoopText(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : Colors.white60,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Gungeoneer picker — RNG / Off + grid of in-game sprites
// =============================================================================

class _GungeoneerPicker extends StatelessWidget {
  final HomeCustomization cust;
  const _GungeoneerPicker({required this.cust});

  @override
  Widget build(BuildContext context) {
    final gungeoneers = context.watch<RunProvider>().allGungeoneers;
    final isRng = cust.showGungeoneer && cust.gungeoneerName.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoopText(
          'Pick a Gungeoneer to rotate in the vortex, or let it cycle randomly.',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
        ),
        const SizedBox(height: 10),
        // Special options row: RNG + Off
        Row(
          children: [
            _SpecialTile(
              label: 'RNG Cycle',
              icon: Icons.shuffle_rounded,
              color: const Color(0xFFAB47BC),
              selected: isRng,
              onTap: () {
                Haptics.selection();
                HomeCustomization.setGungeoneerName('');
              },
            ),
            const SizedBox(width: 8),
            _SpecialTile(
              label: 'Off',
              icon: Icons.visibility_off_rounded,
              color: Colors.white54,
              selected: !cust.showGungeoneer,
              onTap: () {
                Haptics.selection();
                HomeCustomization.setShowGungeoneer(false);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.72,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
          ),
          itemCount: gungeoneers.length,
          itemBuilder: (context, i) {
            final g = gungeoneers[i];
            final selected = cust.showGungeoneer && cust.gungeoneerName == g.name;
            return _GungeoneerTile(
              name: g.name,
              selected: selected,
              onTap: () {
                Haptics.selection();
                HomeCustomization.setGungeoneerName(g.name);
              },
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SpecialTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _SpecialTile({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 56,
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.8) : Colors.white24,
              width: selected ? 1.4 : 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? color : Colors.white54),
              const SizedBox(width: 6),
              GoopText(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : Colors.white60,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GungeoneerTile extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const _GungeoneerTile({required this.name, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gif = gungeoneerGifPath(name);
    final icon = localGungeoneerIcon(name);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFBCA0F8).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFBCA0F8).withValues(alpha: 0.85) : Colors.white24,
            width: selected ? 1.6 : 0.8,
          ),
          boxShadow: selected
              ? [BoxShadow(color: const Color(0xFFBCA0F8).withValues(alpha: 0.25), blurRadius: 8)]
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: gif.isNotEmpty
                    ? Image.asset(gif, fit: BoxFit.contain, filterQuality: FilterQuality.none,
                        errorBuilder: (_, __, ___) => _fallback(icon))
                    : _fallback(icon),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
              child: GoopText(
                name.replaceFirst('The ', ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.white70,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(String icon) {
    if (icon.isNotEmpty) {
      return Image.asset(icon, fit: BoxFit.contain, filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 28, color: Colors.white54));
    }
    return const Icon(Icons.person, size: 28, color: Colors.white54);
  }
}

// =============================================================================
// Junk settings — master toggle + per-type count steppers
// =============================================================================

class _JunkSettings extends StatelessWidget {
  final HomeCustomization cust;
  const _JunkSettings({required this.cust});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoopText(
          'Choose which pickups drift through the vortex and how many of each.',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
        ),
        const SizedBox(height: 12),
        // Master toggle row
        _MasterToggle(
          on: cust.showJunk,
          onChanged: (v) {
            Haptics.selection();
            HomeCustomization.setShowJunk(v);
          },
        ),
        const SizedBox(height: 12),
        // Per-type steppers
        for (final t in HomeCustomization.junkTypes) ...[
          _JunkStepper(
            stem: t.stem,
            label: t.label,
            count: cust.junkCounts[t.stem] ?? 0,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            GoopText(
              'Total: ${cust.totalJunk} sprites',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MasterToggle extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChanged;
  const _MasterToggle({required this.on, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_rounded, size: 18, color: on ? const Color(0xFFFFD54F) : Colors.white54),
          const SizedBox(width: 8),
          const GoopText(
            'Show junk in vortex',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const Spacer(),
          Switch(
            value: on,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFFFFD54F).withValues(alpha: 0.5),
            activeColor: const Color(0xFFFFD54F),
          ),
        ],
      ),
    );
  }
}

class _JunkStepper extends StatelessWidget {
  final String stem;
  final String label;
  final int count;
  const _JunkStepper({required this.stem, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: count > 0 ? const Color(0xFFFFD54F).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Sprite preview
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              HomeCustomization.junkAssetPath(stem),
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => const SizedBox(width: 26, height: 26),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GoopText(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: count > 0 ? Colors.white : Colors.white60,
              ),
            ),
          ),
          // Stepper
          _StepBtn(
            icon: Icons.remove_rounded,
            onTap: () { Haptics.selection(); HomeCustomization.setJunkCount(stem, count - 1); },
          ),
          SizedBox(
            width: 30,
            child: Center(
              child: GoopText(
                '$count',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            onTap: () { Haptics.selection(); HomeCustomization.setJunkCount(stem, count + 1); },
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
      ),
    );
  }
}
