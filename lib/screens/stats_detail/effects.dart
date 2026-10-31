part of '../stats_detail_screen.dart';

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

class _CoolnessEffects extends StatefulWidget {
  final double coolness;
  final double curse;
  const _CoolnessEffects({required this.coolness, required this.curse});

  @override
  State<_CoolnessEffects> createState() => _CoolnessEffectsState();
}

class _CoolnessEffectsState extends State<_CoolnessEffects> {
  bool _alsoExpanded = false;

  @override
  Widget build(BuildContext context) {
    final coolness = widget.coolness;
    final curse = widget.curse;
    // Clamp to int for the displayed curve math (game uses integer buckets).
    final c = coolness;
    final rechargeReduction = (c * 5).clamp(0, 50);
    final fuseReduction = (c * 2.5).clamp(0, 10);
    final baseRoomReward = (1 + c - curse).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Live effects at current coolness'),
        _EffectRow(
          icon: Icons.flash_on,
          color: Skeuo.inkIf(Colors.lightBlueAccent),
          label: 'Active item cooldown reduction',
          value: '${rechargeReduction.toStringAsFixed(1)}%',
          subtitle: '5% per point (max 50%)',
        ),
        _EffectRow(
          icon: Icons.shield,
          color: Skeuo.inkIf(Colors.lightBlueAccent),
          label: 'Chest fuse chance reduction',
          value: '${fuseReduction.toStringAsFixed(1)}%',
          subtitle: '2.5% per point (max 10%)',
        ),
        _EffectRow(
          icon: Icons.auto_awesome,
          color: Skeuo.inkIf(Colors.amber),
          label: 'Base room-clear reward chance',
          value: '${baseRoomReward.toStringAsFixed(1)}%',
          subtitle: '(1 + coolness - curse)%',
        ),
        const SizedBox(height: 8),
        // "Also" section — collapsed by default
        InkWell(
          onTap: () {
            Haptics.selection();
            setState(() => _alsoExpanded = !_alsoExpanded);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
            child: Row(
              children: [
                GoopText(
                  'ALSO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                    color: Skeuo.collapse(Colors.white).withValues(alpha: 0.65),
                  ),
                ),
                Spacer(),
                AnimatedRotation(
                  turns: _alsoExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: Skeuo.collapse(Colors.white).withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_alsoExpanded) ...[
          _InfoRow(
            icon: Icons.casino,
            text: 'If reward triggers: 20% chest / 80% pickup',
          ),
          _InfoRow(
            icon: Icons.star,
            text: 'Increases Vorpal Gun critical shot chance',
          ),
        ],
      ],
    );
  }
}

class _CurseEffects extends StatefulWidget {
  final double curse;
  final double coolness;
  const _CurseEffects({required this.curse, required this.coolness});

  @override
  State<_CurseEffects> createState() => _CurseEffectsState();
}

class _CurseEffectsState extends State<_CurseEffects> {
  bool _tableExpanded = false;

  @override
  Widget build(BuildContext context) {
    final curse = widget.curse;
    final coolness = widget.coolness;
    final currentIdx = curse.floor().clamp(0, 10);
    final row = curseTable[currentIdx];
    final roomReward = (1 + coolness - curse).clamp(-50, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Live effects at current curse'),
        _EffectRow(
          icon: Icons.local_fire_department,
          color: Skeuo.inkIf(Colors.deepOrangeAccent),
          label: 'Jammed enemy chance',
          value: row.jammedEnemy,
          subtitle: curse >= 10 ? 'Capped at 10+ curse' : 'Scales per point',
        ),
        _EffectRow(
          icon: Icons.emoji_events_outlined,
          color: Skeuo.inkIf(Colors.deepOrangeAccent),
          label: 'Jammed boss chance',
          value: row.jammedBoss,
          subtitle: 'Starts at curse 7',
        ),
        _EffectRow(
          icon: Icons.pest_control,
          color: Skeuo.inkIf(Colors.redAccent),
          label: 'Mimic chest chance',
          value: row.mimicChance,
          subtitle: '+2.1% per curse point',
        ),
        _EffectRow(
          icon: Icons.whatshot,
          color: Skeuo.inkIf(Colors.redAccent),
          label: 'Chest fuse chance',
          value: row.fuseChance,
          subtitle: '+5% per curse point',
        ),
        _EffectRow(
          icon: Icons.redeem,
          color: Skeuo.inkIf(Colors.amber),
          label: 'Base room-clear reward chance',
          value: '${roomReward.toStringAsFixed(1)}%',
          subtitle: '(1 + coolness - curse)%',
        ),
        _EffectRow(
          icon: Icons.dataset,
          color: Skeuo.inkIf(Colors.lightGreenAccent),
          label: 'Ammo drop multiplier',
          value: row.ammo,
          subtitle: 'Ammo drops increase with curse',
        ),
        if (curse >= 10)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(Insets.md),
            decoration: BoxDecoration(
              color: Skeuo.inkIf(Colors.red).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Skeuo.inkIf(Colors.redAccent),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Skeuo.inkIf(Colors.redAccent),
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GoopText(
                    'Lord of the Jammed has spawned. Run.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Skeuo.inkIf(Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        // Full curse table — collapsed by default
        InkWell(
          onTap: () {
            Haptics.selection();
            setState(() => _tableExpanded = !_tableExpanded);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
            child: Row(
              children: [
                GoopText(
                  'FULL CURSE EFFECT TABLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                    color: Skeuo.collapse(Colors.white).withValues(alpha: 0.65),
                  ),
                ),
                Spacer(),
                AnimatedRotation(
                  turns: _tableExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: Skeuo.collapse(Colors.white).withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_tableExpanded) ...[
          SizedBox(height: 6),
          _CurseTable(highlightIdx: currentIdx),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.xs),
            child: GoopText(
              'Jam E./B. = Jammed Enemy / Boss chance · Mimic = chest mimic chance · '
              'Fuse = fused chest chance · Room = room-clear reward mod · '
              'Ammo = ammo drop multiplier. At 10+ curse, enemy/boss jam chances '
              'cap at 50% but other effects keep scaling.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: Skeuo.collapse(Colors.white).withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
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
            Skeuo.collapse(Colors.white).withValues(alpha: 0.05),
          ),
          dataRowMinHeight: 32,
          dataRowMaxHeight: 36,
          columnSpacing: 18,
          columns: const [
            DataColumn(
              label: Tooltip(
                message: 'Current curse level',
                child: GoopText('Curse'),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message:
                    'Chance a regular enemy spawns Jammed (golden, tougher)',
                child: GoopText('Jam E.'),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Chance a boss spawns Jammed',
                child: GoopText('Jam B.'),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Chance chests are mimics',
                child: GoopText('Mimic'),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Chance chests spawn with a fuse',
                child: GoopText('Fuse'),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Change to base room-clear reward chance',
                child: GoopText('Room'),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Ammo drop multiplier',
                child: GoopText('Ammo'),
              ),
            ),
          ],
          rows: [
            for (int i = 0; i < curseTable.length; i++)
              DataRow(
                color:
                    i == highlightIdx
                        ? WidgetStatePropertyAll(
                          Skeuo.inkIf(Colors.amber).withValues(alpha: 0.18),
                        )
                        : null,
                cells: [
                  DataCell(
                    GoopText(
                      '${curseTable[i].curse}',
                      style: TextStyle(
                        fontWeight:
                            i == highlightIdx
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            i == highlightIdx
                                ? Skeuo.inkIf(Colors.amber)
                                : null,
                      ),
                    ),
                  ),
                  DataCell(GoopText(curseTable[i].jammedEnemy)),
                  DataCell(GoopText(curseTable[i].jammedBoss)),
                  DataCell(GoopText(curseTable[i].mimicChance)),
                  DataCell(GoopText(curseTable[i].fuseChance)),
                  DataCell(GoopText(curseTable[i].roomRewards)),
                  DataCell(GoopText(curseTable[i].ammo)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
