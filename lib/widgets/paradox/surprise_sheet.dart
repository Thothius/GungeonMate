import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../services/mp_session.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';
import '../../utils/responsive.dart';
import '../scale_button.dart';
import '../skeuo/skeuo_tokens.dart';

/// MP surprise composer — opened by tapping your or the peer's avatar.
/// Preset grid for one-tap sends plus a custom step: pick an animation
/// fx and optionally attach a short text line.
class SurpriseSheet extends StatefulWidget {
  const SurpriseSheet({super.key});

  static void open(BuildContext context) {
    Haptics.selection();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Skeuo.collapse(Color(0xFF1E122E)),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (_) => const SurpriseSheet(),
    );
  }

  @override
  State<SurpriseSheet> createState() => _SurpriseSheetState();
}

class _SurpriseSheetState extends State<SurpriseSheet> {
  bool _custom = false;
  String _fx = '';
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  static const _presets = <(String, String, IconData)>[
    ('love', 'LOVE', Icons.favorite_rounded),
    ('slap', 'SLAP', Icons.back_hand_rounded),
    ('blank', 'BLANK', Icons.brightness_7_rounded),
    ('mimic', 'MIMIC', Icons.warning_amber_rounded),
    ('heal', 'HEAL', Icons.healing_rounded),
    ('gungeon', 'GUNGEON', Icons.gps_fixed_rounded),
  ];

  static const _fxOptions = <(String, String, IconData)>[
    ('', 'NONE', Icons.block_rounded),
    ('bulletrain', 'BULLET RAIN', Icons.water_drop_outlined),
    ('heartsburst', 'HEART BURST', Icons.favorite_border_rounded),
    ('explosion', 'EXPLOSION', Icons.whatshot_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final session = context.read<MpSession>();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18 * sf,
          14 * sf,
          18 * sf,
          18 * sf + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Skeuo.collapse(Colors.white).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child:
                  _custom ? _customStep(session, sf) : _presetStep(session, sf),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetStep(MpSession session, double sf) {
    return Column(
      key: const ValueKey('presets'),
      mainAxisSize: MainAxisSize.min,
      children: [
        GoopText(
          'SEND A SURPRISE',
          style: TextStyle(
            fontSize: 11 * sf,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Skeuo.inkIf(Colors.amberAccent).withValues(alpha: 0.9),
          ),
        ),
        SizedBox(height: 14 * sf),
        Wrap(
          spacing: 10 * sf,
          runSpacing: 10 * sf,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < _presets.length; i++)
              _PresetTile(
                    preset: _presets[i].$1,
                    label: _presets[i].$2,
                    icon: _presets[i].$3,
                    sf: sf,
                    onTap: () {
                      Haptics.medium();
                      session.sendSurprise(preset: _presets[i].$1);
                      Navigator.of(context).pop();
                    },
                  )
                  .animate(delay: (40 * i).ms)
                  .fadeIn(duration: 220.ms)
                  .scale(begin: const Offset(0.85, 0.85), duration: 220.ms),
          ],
        ),
        SizedBox(height: 14 * sf),
        ScaleButton(
          onTap: () => setState(() => _custom = true),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * sf,
              vertical: 10 * sf,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Skeuo.collapse(Color(0xFFB388FF)).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 15,
                  color: Skeuo.collapse(Color(0xFFB388FF)),
                ),
                SizedBox(width: 6 * sf),
                GoopText(
                  'CUSTOM…',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Skeuo.collapse(Color(0xFFB388FF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _customStep(MpSession session, double sf) {
    final accent = Skeuo.collapse(Color(0xFFB388FF));
    return Column(
      key: const ValueKey('custom'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _custom = false),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: Skeuo.collapse(Colors.white).withValues(alpha: 0.6),
              ),
            ),
            SizedBox(width: 10 * sf),
            GoopText(
              'CUSTOM SURPRISE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: accent,
              ),
            ),
          ],
        ),
        SizedBox(height: 14 * sf),
        // Animation fx picker.
        Row(
          children: [
            for (final (fx, label, icon) in _fxOptions)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3 * sf),
                  child: GestureDetector(
                    onTap: () {
                      Haptics.light();
                      setState(() => _fx = fx);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(vertical: 10 * sf),
                      decoration: BoxDecoration(
                        color:
                            _fx == fx
                                ? accent.withValues(alpha: 0.15)
                                : Skeuo.collapse(
                                  Colors.white,
                                ).withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              _fx == fx
                                  ? accent.withValues(alpha: 0.8)
                                  : Skeuo.collapse(
                                    Colors.white,
                                  ).withValues(alpha: 0.12),
                          width: _fx == fx ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            icon,
                            size: 18 * sf,
                            color:
                                _fx == fx
                                    ? accent
                                    : Skeuo.collapse(
                                      Colors.white,
                                    ).withValues(alpha: 0.4),
                          ),
                          SizedBox(height: 4 * sf),
                          GoopText(
                            label,
                            style: TextStyle(
                              fontSize: 7.5 * sf,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color:
                                  _fx == fx
                                      ? accent
                                      : Skeuo.collapse(
                                        Colors.white,
                                      ).withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12 * sf),
        TextField(
          controller: _textCtrl,
          maxLength: 30,
          style: TextStyle(color: Skeuo.collapse(Colors.white), fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Optional message (≤30 chars)',
            hintStyle: TextStyle(
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.35),
              fontSize: 12,
            ),
            counterStyle: TextStyle(
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.3),
              fontSize: 10,
            ),
            filled: true,
            fillColor: Skeuo.collapse(Colors.white).withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Skeuo.collapse(Colors.white).withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Skeuo.collapse(Colors.white).withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accent.withValues(alpha: 0.6)),
            ),
          ),
        ),
        SizedBox(height: 8 * sf),
        ScaleButton(
          onTap: () {
            final text = _textCtrl.text.trim();
            if (_fx.isEmpty && text.isEmpty) return;
            Haptics.medium();
            session.sendSurprise(preset: 'custom', text: text, fx: _fx);
            Navigator.of(context).pop();
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12 * sf),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.6)),
            ),
            child: Center(
              child: GoopText(
                'SEND',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: accent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  final String preset;
  final String label;
  final IconData icon;
  final double sf;
  final VoidCallback onTap;
  const _PresetTile({
    required this.preset,
    required this.label,
    required this.icon,
    required this.sf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * sf, vertical: 12 * sf),
        decoration: BoxDecoration(
          color: Skeuo.inkIf(Colors.amberAccent).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Skeuo.inkIf(Colors.amberAccent).withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Skeuo.inkIf(Colors.amberAccent), size: 26 * sf),
            SizedBox(height: 4 * sf),
            GoopText(
              label,
              style: TextStyle(
                fontSize: 10 * sf,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Skeuo.inkIf(Colors.amberAccent).withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
