/// Single source of truth for Coolness/Curse effect math.
///
/// Values verified against the official Enter the Gungeon wiki
/// (wiki.gg/wiki/Curse + wiki.gg/wiki/Coolness). Both the stats-detail
/// effects tab and the Cool & Curse screen must read from here — do not
/// re-derive formulas inline.
library;

/// One row of the per-point Curse effect table (integer curse 0–10).
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

/// Wiki Curse table — verbatim values, including the 50% jam cap at 10+.
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

int _curseIndex(double curse) => curse.floor().clamp(0, 10);

/// Chance a regular enemy spawns Jammed, percent. Caps at 50% (10+ curse).
double jammedEnemyChance(double curse) {
  const pct = [0, 1, 1, 2, 2, 5, 5, 10, 10, 25, 50];
  return pct[_curseIndex(curse)].toDouble();
}

/// Chance a boss spawns Jammed, percent. Starts at curse 7, caps at 50%.
double jammedBossChance(double curse) {
  const pct = [0, 0, 0, 0, 0, 0, 0, 20, 20, 30, 50];
  return pct[_curseIndex(curse)].toDouble();
}

/// Mimic chest chance, percent — 2.25% base + 2.1% per curse point.
double mimicChance(double curse) => 2.25 + curse * 2.1;

/// Fused-chest chance increase from curse, percent — +5% per point,
/// continues linearly past 10 (only jam chances cap).
double curseFuseBonus(double curse) => curse * 5;

/// Ammo drop multiplier — x1.05 per curse point.
double ammoDropMultiplier(double curse) => 1 + curse * 0.05;

/// Active-item cooldown reduction from coolness, percent — 5%/pt, cap 50%.
double cooldownReduction(double coolness) =>
    (coolness * 5).clamp(0.0, 50.0);

/// Chest fuse-chance reduction from coolness, percent — 2.5%/pt, cap 10%.
double fuseChanceReduction(double coolness) =>
    (coolness * 2.5).clamp(0.0, 10.0);

/// Base room-clear reward chance, percent — (1 + coolness - curse),
/// floored at 0 (negative drop chance effect is undocumented in-game).
double roomRewardChance(double coolness, double curse) =>
    (1 + coolness - curse).clamp(0.0, 100.0);
