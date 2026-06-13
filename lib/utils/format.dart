/// Number formatting helpers shared across screens so coolness / curse /
/// DPS / damage / fire-rate render identically wherever they appear.
library;

/// Formats a stat value the way the inventory header & detail screens
/// expect:
///   * values < ±0.05 collapse to `'0'` (avoids `-0.0` / `0.0` glitches),
///   * whole numbers render without a trailing `.0`,
///   * everything else gets one decimal.
String formatStat(double v) {
  if (v.abs() < 0.05) return '0';
  if ((v - v.roundToDouble()).abs() < 0.05) {
    return v.toStringAsFixed(0);
  }
  return v.toStringAsFixed(1);
}
