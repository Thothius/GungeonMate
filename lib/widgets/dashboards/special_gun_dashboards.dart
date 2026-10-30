import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/player.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
part 'special_gun/gun_evo_dashboards.dart';

/// Damage Calculator bottom sheet — opened via the calc icon in the
/// GungeoneerHeader trailing row. Sums quantifiable "Damage Up"/"Damage
/// Down" effects from the player's current guns + items via
/// [DamageCalculator] and applies the resulting multiplier to every
