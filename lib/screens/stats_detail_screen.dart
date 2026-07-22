import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/run_log_entry.dart';
import '../services/haptics.dart';

enum StatType { coolness, curse }

/// Curse effect table row.
class CurseRow {
  final int curse;
  final String jammedEnemy;
  final String jammedBoss;
  final String mimicChance;
  final String fuseChance;
  final String roomRewards;
  final String ammo;
  const CurseRow(
    this.curse,
    this.jammedEnemy,
    this.jammedBoss,
    this.mimicChance,
    this.fuseChance,
    this.roomRewards,
    this.ammo,
  );
}

const curseTable = <CurseRow>[
  CurseRow(0, '0%', '0%', '2.25%', 'Unchanged', 'Unchanged', 'Unchanged'),
  CurseRow(1, '1%', '0%', '4.35%', '+5%', '-1%', 'x1.05'),
  CurseRow(2, '1%', '0%', '6.45%', '+10%', '-2%', 'x1.10'),
  CurseRow(3, '2%', '0%', '8.55%', '+15%', '-3%', 'x1.15'),
  CurseRow(4, '2%', '0%', '10.65%', '+20%', '-4%', 'x1.20'),
  CurseRow(5, '5%', '0%', '12.75%', '+25%', '-5%', 'x1.25'),
  CurseRow(6, '5%', '0%', '14.85%', '+30%', '-6%', 'x1.30'),
  CurseRow(7, '10%', '20%', '16.95%', '+35%', '-7%', 'x1.35'),
  CurseRow(8, '10%', '20%', '19.05%', '+40%', '-8%', 'x1.40'),
  CurseRow(9, '25%', '30%', '21.15%', '+45%', '-9%', 'x1.45'),
  CurseRow(10, '50%', '50%', '23.25%', '+50%', '-10%', 'x1.50'),
];

class StatsDetailScreen extends StatelessWidget {
  final StatType statType;
  const StatsDetailScreen({super.key, required this.statType});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final isCool = statType == StatType.coolness;
    final total = isCool ? p.runState.totalCoolness : p.runState.totalCurse;
    final base = isCool ? p.runState.coolness : p.runState.curse;
    final fromItems = total - base;
    final title = isCool ? 'Coolness' : 'Curse';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title),
        actions: [
          if (base != 0)
            IconButton(
              tooltip: 'Reset manual adjustments',
              icon: const Icon(Icons.restart_alt),
              onPressed: () => p.resetManualStats(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _ValueCard(
            isCool: isCool,
            value: total,
            base: base,
            fromItems: fromItems,
            isTeam: p.runState.hasCoop,
            onDelta: (delta) {
              if (isCool) {
                p.adjustCoolness(delta);
              } else {
                p.adjustCurse(delta);
              }
            },
          ),
          const SizedBox(height: 16),
          _QuickActions(isCool: isCool),
          const SizedBox(height: 16),
          _EventLog(isCool: isCool),
          const SizedBox(height: 16),
          if (isCool)
            _CoolnessEffects(coolness: total, curse: p.runState.totalCurse)
          else
            _CurseEffects(curse: total, coolness: p.runState.totalCoolness),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E2A27),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white12, width: 1.2),
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: const Text(
                'BACK TO RUN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final bool isCool;
  final double value;
  final double base;
  final double fromItems;
  final bool isTeam;
  final void Function(double) onDelta;

  const _ValueCard({
    required this.isCool,
    required this.value,
    required this.base,
    required this.fromItems,
    required this.onDelta,
    this.isTeam = false,
  });

  String _fmt(double v) {
    final sign = v > 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = isCool ? const Color(0xFF00E5FF) : const Color(0xFFFF3D00);
    final hasBreakdown = base != 0 || fromItems != 0;

    // Mathematical calculations for the visual meters
    final double maxSlider = 15.0;
    final double minSlider = 0.0;
    final double clampedVal = value.clamp(minSlider, maxSlider);

    // Active item reduction percent (max 50%) or Lord of the Jammed Threat percentage
    final meterPercentage = isCool 
        ? (value * 5).clamp(0.0, 50.0) / 50.0 
        : (value * 10).clamp(0.0, 100.0) / 100.0;

    final meterLabel = isCool 
        ? 'Active Cooldown Speedup: +${(value * 5).clamp(0, 50).toStringAsFixed(1)}%' 
        : 'Bullet Hell Threat Level: ${(value * 10).clamp(0, 100).toStringAsFixed(1)}%';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Main Value readout & Visual Indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Column(
              children: [
                Icon(
                  isCool ? Icons.ac_unit_rounded : Icons.local_fire_department_rounded,
                  size: 48,
                  color: color,
                ),
                const SizedBox(height: 6),
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasBreakdown) ...[
                  Text(
                    isTeam
                        ? 'Base ${_fmt(base)}  ·  From Team ${_fmt(fromItems)}'
                        : 'Base ${_fmt(base)}  ·  From Items ${_fmt(fromItems)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Live Tactile Interactive Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                    thumbColor: Colors.white,
                    overlayColor: color.withValues(alpha: 0.2),
                    valueIndicatorColor: color,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Slider(
                    value: clampedVal,
                    min: minSlider,
                    max: maxSlider,
                    divisions: 30, // steps of 0.5
                    label: value.toStringAsFixed(1),
                    onChanged: (newVal) {
                      final delta = newVal - value;
                      if (delta.abs() > 0.01) {
                        onDelta(delta);
                      }
                    },
                  ),
                ),
                // Slider scale labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0.0', style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
                      Text('5.0', style: TextStyle(fontSize: 10, color: Colors.white30)),
                      Text('10.0', style: TextStyle(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold)),
                      Text('15.0+', style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Incremental presets (oiled quick buttons in a single spacious mobile-friendly row)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _btn('-1.0', () => onDelta(-1), Colors.redAccent, isCool),
                _btn('-0.5', () => onDelta(-0.5), Colors.redAccent, isCool),
                _btn('+0.5', () => onDelta(0.5), color, isCool),
                _btn('+1.0', () => onDelta(1), color, isCool),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Progress Bar (Gungeon Meter)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      meterLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color.withValues(alpha: 0.9),
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (isCool && value >= 10.0)
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: meterPercentage,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    color: color,
                    minHeight: 6,
                  ),
                ),
                // Lord of the Jammed Special Alert Card
                if (!isCool && value >= 10.0) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent, width: 1.0),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'LORD OF THE JAMMED HAS SPAWNED!',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.redAccent,
                              letterSpacing: 0.5,
                            ),
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

  Widget _btn(String label, VoidCallback cb, Color btnColor, bool isCoolMode) {
    final isMinus = label.startsWith('-');
    final showWarningColor = !isCoolMode && !isMinus; // Curse addition highlights orange-red
    final activeColor = showWarningColor ? Colors.deepOrange : btnColor;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: SizedBox(
          height: 38,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: isMinus
                  ? Colors.red.withValues(alpha: 0.12)
                  : activeColor.withValues(alpha: 0.12),
              foregroundColor: isMinus ? Colors.redAccent : activeColor,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isMinus
                      ? Colors.red.withValues(alpha: 0.15)
                      : activeColor.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
            ),
            onPressed: cb,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------- Coolness effects -------------------------------------

class _CoolnessEffects extends StatelessWidget {
  final double coolness;
  final double curse;
  const _CoolnessEffects({required this.coolness, required this.curse});

  @override
  Widget build(BuildContext context) {
    // Clamp to int for the displayed curve math (game uses integer buckets).
    final c = coolness;
    final rechargeReduction = (c * 5).clamp(0, 50);
    final fuseReduction = (c * 2.5).clamp(0, 10);
    final baseRoomReward = (1 + c - curse).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Live effects at current coolness'),
        _EffectRow(
          icon: Icons.flash_on,
          color: Colors.lightBlueAccent,
          label: 'Active item cooldown reduction',
          value: '${rechargeReduction.toStringAsFixed(1)}%',
          subtitle: '5% per point (max 50%)',
        ),
        _EffectRow(
          icon: Icons.shield,
          color: Colors.lightBlueAccent,
          label: 'Chest fuse chance reduction',
          value: '${fuseReduction.toStringAsFixed(1)}%',
          subtitle: '2.5% per point (max 10%)',
        ),
        _EffectRow(
          icon: Icons.auto_awesome,
          color: Colors.amber,
          label: 'Base room-clear reward chance',
          value: '${baseRoomReward.toStringAsFixed(1)}%',
          subtitle: '(1 + coolness - curse)%',
        ),
        const SizedBox(height: 8),
        const _SectionTitle('Also'),
        _InfoRow(
          icon: Icons.casino,
          text: 'If reward triggers: 20% chest / 80% pickup',
        ),
        _InfoRow(
          icon: Icons.star,
          text: 'Increases Vorpal Gun critical shot chance',
        ),
      ],
    );
  }
}

// ---------------------- Curse effects + table --------------------------------

class _CurseEffects extends StatelessWidget {
  final double curse;
  final double coolness;
  const _CurseEffects({required this.curse, required this.coolness});

  @override
  Widget build(BuildContext context) {
    final currentIdx = curse.floor().clamp(0, 10);
    final row = curseTable[currentIdx];
    final roomReward = (1 + coolness - curse).clamp(-50, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Live effects at current curse'),
        _EffectRow(
          icon: Icons.local_fire_department,
          color: Colors.deepOrangeAccent,
          label: 'Jammed enemy chance',
          value: row.jammedEnemy,
          subtitle: curse >= 10 ? 'Capped at 10+ curse' : 'Scales per point',
        ),
        _EffectRow(
          icon: Icons.emoji_events_outlined,
          color: Colors.deepOrangeAccent,
          label: 'Jammed boss chance',
          value: row.jammedBoss,
          subtitle: 'Starts at curse 7',
        ),
        _EffectRow(
          icon: Icons.pest_control,
          color: Colors.redAccent,
          label: 'Mimic chest chance',
          value: row.mimicChance,
          subtitle: '+2.1% per curse point',
        ),
        _EffectRow(
          icon: Icons.whatshot,
          color: Colors.redAccent,
          label: 'Chest fuse chance',
          value: row.fuseChance,
          subtitle: '+5% per curse point',
        ),
        _EffectRow(
          icon: Icons.redeem,
          color: Colors.amber,
          label: 'Base room-clear reward chance',
          value: '${roomReward.toStringAsFixed(1)}%',
          subtitle: '(1 + coolness - curse)%',
        ),
        _EffectRow(
          icon: Icons.dataset,
          color: Colors.lightGreenAccent,
          label: 'Ammo drop multiplier',
          value: row.ammo,
          subtitle: 'Ammo drops increase with curse',
        ),
        if (curse >= 10)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent, width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lord of the Jammed has spawned. Run.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const _SectionTitle('Full curse effect table'),
        _CurseTable(highlightIdx: currentIdx),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Jam E./B. = Jammed Enemy / Boss chance · Mimic = chest mimic chance · '
            'Fuse = fused chest chance · Room = room-clear reward mod · '
            'Ammo = ammo drop multiplier. At 10+ curse, enemy/boss jam chances '
            'cap at 50% but other effects keep scaling.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _CurseTable extends StatelessWidget {
  final int highlightIdx;
  const _CurseTable({required this.highlightIdx});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.05),
          ),
          dataRowMinHeight: 32,
          dataRowMaxHeight: 36,
          columnSpacing: 18,
          columns: const [
            DataColumn(
              label: Tooltip(message: 'Current curse level', child: Text('Curse')),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Chance a regular enemy spawns Jammed (golden, tougher)',
                child: Text('Jam E.'),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Chance a boss spawns Jammed',
                child: Text('Jam B.'),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Chance chests are mimics',
                child: Text('Mimic'),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Chance chests spawn with a fuse',
                child: Text('Fuse'),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Change to base room-clear reward chance',
                child: Text('Room'),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Ammo drop multiplier',
                child: Text('Ammo'),
              ),
            ),
          ],
          rows: [
            for (int i = 0; i < curseTable.length; i++)
              DataRow(
                color: i == highlightIdx
                    ? WidgetStatePropertyAll(Colors.amber.withValues(alpha: 0.18))
                    : null,
                cells: [
                  DataCell(Text(
                    '${curseTable[i].curse}',
                    style: TextStyle(
                      fontWeight: i == highlightIdx
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: i == highlightIdx ? Colors.amber : null,
                    ),
                  )),
                  DataCell(Text(curseTable[i].jammedEnemy)),
                  DataCell(Text(curseTable[i].jammedBoss)),
                  DataCell(Text(curseTable[i].mimicChance)),
                  DataCell(Text(curseTable[i].fuseChance)),
                  DataCell(Text(curseTable[i].roomRewards)),
                  DataCell(Text(curseTable[i].ammo)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- Shared UI bits ---------------------------------------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      );
}

class _EffectRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String subtitle;
  const _EffectRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------- Quick action buttons ---------------------------------

class _QuickActions extends StatelessWidget {
  final bool isCool;
  const _QuickActions({required this.isCool});

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();

    final actions = isCool
        ? [
            _QuickAction(
              icon: runLogCategoryIcon(RunLogCategory.smokeCig),
              label: 'Smoke Cig',
              subtitle: '+1 cool',
              color: runLogCategoryColor(RunLogCategory.smokeCig),
              onTap: p.logSmokeCig,
            ),
            _QuickAction(
              icon: runLogCategoryIcon(RunLogCategory.rainbowRun),
              label: 'Rainbow Run',
              subtitle: '+1 cool',
              color: runLogCategoryColor(RunLogCategory.rainbowRun),
              onTap: p.logRainbowRun,
            ),
          ]
        : [
            _QuickAction(
              icon: runLogCategoryIcon(RunLogCategory.steal),
              label: 'Steal',
              subtitle: '+1 curse',
              color: runLogCategoryColor(RunLogCategory.steal),
              onTap: p.logSteal,
            ),
            _QuickAction(
              icon: runLogCategoryIcon(RunLogCategory.cursula),
              label: 'Cursula',
              subtitle: '+2 curse',
              color: runLogCategoryColor(RunLogCategory.cursula),
              onTap: p.logCursula,
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(isCool ? 'Quick coolness actions' : 'Quick curse actions'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: actions
              .map((a) => _QuickActionCard(action: a))
              .toList(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Text(
            'Things the app can\'t auto-detect — tap to log them.',
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Haptics.selection();
          action.onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: action.color.withValues(alpha: 0.25), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(action.icon, color: action.color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        action.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        action.subtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: action.color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------- Event log feed ---------------------------------------

class _EventLog extends StatefulWidget {
  final bool isCool;
  const _EventLog({required this.isCool});

  @override
  State<_EventLog> createState() => _EventLogState();
}

class _EventLogState extends State<_EventLog> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final entries = widget.isCool ? p.coolnessLog : p.curseLog;
    final title = widget.isCool ? 'Coolness event log' : 'Curse event log';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tap-to-expand header with entry count badge
        InkWell(
          onTap: entries.isEmpty
              ? null
              : () {
                  Haptics.selection();
                  setState(() => _collapsed = !_collapsed);
                },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(width: 8),
                if (entries.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entries.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                const Spacer(),
                if (entries.isNotEmpty)
                  AnimatedRotation(
                    turns: _collapsed ? 0 : 0.5,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!_collapsed && entries.isNotEmpty) ...[
          ...entries.take(20).map((e) => _LogTile(entry: e, isCool: widget.isCool)),
          const SizedBox(height: 8),
          _LogLegend(entries: entries),
        ],
        if (_collapsed && entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Text(
              'No events yet. Pick up items or use quick actions above to start tracking.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  final RunLogEntry entry;
  final bool isCool;
  const _LogTile({required this.entry, required this.isCool});

  @override
  Widget build(BuildContext context) {
    final catColor = runLogCategoryColor(entry.category);
    final delta = isCool ? entry.coolnessDelta : entry.curseDelta;
    final hasDelta = (isCool ? entry.affectsCoolness : entry.affectsCurse);
    final isPositive = delta > 0;
    final deltaColor = isPositive ? catColor : Colors.redAccent;

    final timeStr =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          color: catColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: catColor, width: 3),
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(runLogCategoryIcon(entry.category), size: 18, color: catColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        if (entry.playerName != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.playerName!,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasDelta)
                Text(
                  '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: deltaColor,
                  ),
                )
              else
                Icon(runLogCategoryIcon(entry.category),
                    size: 14, color: catColor.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Color-to-category legend shown at the bottom of the event log.
/// Only shows categories that actually appear in the current log.
class _LogLegend extends StatelessWidget {
  final List<RunLogEntry> entries;
  const _LogLegend({required this.entries});

  @override
  Widget build(BuildContext context) {
    final present = <RunLogCategory>{};
    for (final e in entries) {
      present.add(e.category);
    }
    final cats = present.toList()..sort((a, b) => a.index.compareTo(b.index));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGEND',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: cats.map((c) {
              final color = runLogCategoryColor(c);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    runLogCategoryLabel(c),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
