import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/bug_report.dart';
import '../../services/app_theme.dart';
import '../../services/bug_report.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../theme/tokens.dart';
import '../../utils/responsive.dart';

/// Context-aware bug reporter — opened from [BugReportButton] or the
/// run-tools sheet. The kind/location/entity are pre-filled from the
/// [BugReportContext]; the user only writes what happened.
///
/// Send → mailto to the dedicated inbox. If no email handler exists the
/// report is copied to the clipboard instead (with a hint snackbar).
class BugReportSheet extends StatefulWidget {
  final BugReportContext context;
  const BugReportSheet({super.key, required this.context});

  static Future<void> show(BuildContext context, BugReportContext report) {
    Haptics.selection();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BugReportSheet(context: report),
    );
  }

  @override
  State<BugReportSheet> createState() => _BugReportSheetState();
}

enum _DonePhase { sent, copied }

class _BugReportSheetState extends State<BugReportSheet> {
  late BugReportKind _kind = widget.context.kind;
  final _notesCtrl = TextEditingController();
  bool _sending = false;
  _DonePhase? _done;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _notesCtrl.dispose();
    super.dispose();
  }

  BugReportContext get _effective => BugReportContext(
    kind: _kind,
    screen: widget.context.screen,
    entity: widget.context.entity,
  );

  Future<void> _send() async {
    final notes = _notesCtrl.text.trim();
    if (notes.isEmpty || _sending || _done != null) return;
    setState(() => _sending = true);
    Haptics.medium();
    final ctx = _effective;
    final ok = await BugReport.send(ctx, notes);
    if (!mounted) return;
    if (ok) {
      _finish(_DonePhase.sent);
    } else {
      await BugReport.copyReport(ctx, notes);
      if (!mounted) return;
      _finish(_DonePhase.copied);
    }
  }

  Future<void> _copy() async {
    final notes = _notesCtrl.text.trim();
    if (notes.isEmpty || _done != null) return;
    await BugReport.copyReport(_effective, notes);
    if (!mounted) return;
    _finish(_DonePhase.copied);
  }

  /// Swap to the confirmation state, then auto-dismiss — the report is
  /// already safe (email app opened / clipboard written), so the sheet
  /// doesn't need to linger.
  void _finish(_DonePhase phase) {
    Haptics.success();
    setState(() {
      _sending = false;
      _done = phase;
    });
    _dismissTimer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.displayedFlair;
    final sf = Responsive.factor(context);
    final surface = flair.card;
    final ink = flair.primary;

    return Padding(
      // Lift above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: flair.primary.withValues(alpha: 0.2)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child:
                _done == null
                    ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Grab handle.
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(top: Insets.sm),
                            decoration: BoxDecoration(
                              color: ink.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Insets.lg,
                            Insets.md,
                            Insets.lg,
                            Insets.sm,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bug_report_outlined,
                                size: 22,
                                color: ink,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GoopText(
                                  'REPORT A BUG',
                                  style: TextStyle(
                                    fontSize: FontSizes.titleSmall * sf,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.6,
                                    color: flair.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Insets.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ctxChip('SCREEN', widget.context.screen, ink),
                              if (widget.context.entity != null &&
                                  widget.context.entity!.trim().isNotEmpty)
                                _ctxChip('ITEM', widget.context.entity!, ink),
                              const SizedBox(height: Insets.sm),
                              _kindLabel(ink),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final k in BugReportKind.values)
                                    _kindChip(k, ink),
                                ],
                              ),
                              const SizedBox(height: Insets.md),
                              TextField(
                                controller: _notesCtrl,
                                maxLines: 5,
                                minLines: 3,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: const TextStyle(
                                  fontSize: FontSizes.bodyMedium,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'What happened? What did you expect?',
                                  hintStyle: TextStyle(
                                    color: Colors.white70.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: flair.primary.withValues(
                                    alpha: 0.06,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radii.md),
                                    borderSide: BorderSide(
                                      color: flair.primary.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radii.md),
                                    borderSide: BorderSide(
                                      color: flair.primary.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radii.md),
                                    borderSide: BorderSide(
                                      color: ink,
                                      width: 1.6,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(
                                    Insets.md,
                                  ),
                                ),
                              ),
                              const SizedBox(height: Insets.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: _actionButton(
                                      label: 'COPY',
                                      icon: Icons.copy_rounded,
                                      filled: false,
                                      onTap: _copy,
                                      ink: ink,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: _actionButton(
                                      label:
                                          _sending ? 'SENDING…' : 'SEND REPORT',
                                      icon: Icons.send_rounded,
                                      filled: true,
                                      onTap: _send,
                                      ink: ink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Insets.sm),
                              GoopText(
                                'Opens your email app — nothing is sent until you '
                                'hit send there. Includes app version + device info.',
                                style: TextStyle(
                                  fontSize: FontSizes.labelSmall,
                                  color: Colors.white60.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: Insets.lg),
                            ],
                          ),
                        ),
                      ],
                    )
                    : _buildDoneView(ink),
          ),
        ),
      ),
    );
  }

  /// Post-send confirmation — icon pops in with a spring, text rises
  /// behind it. Sheet auto-dismisses ~1.7s after this appears.
  Widget _buildDoneView(Color ink) {
    final sent = _done == _DonePhase.sent;
    final accent = ink;
    const okColor = Colors.greenAccent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.xl,
        Insets.lg,
        Insets.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: okColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: okColor.withValues(alpha: 0.55),
                    width: 1.6,
                  ),
                ),
                child: Icon(
                  sent ? Icons.send_rounded : Icons.content_copy_rounded,
                  size: 38,
                  color: okColor,
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1, 1),
                duration: 420.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 200.ms),
          const SizedBox(height: Insets.lg),
          GoopText(
                sent ? 'REPORT SENT' : 'COPIED',
                style: TextStyle(
                  fontSize: FontSizes.titleMedium,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              )
              .animate(delay: 120.ms)
              .fadeIn(duration: 260.ms)
              .moveY(begin: 8, end: 0),
          const SizedBox(height: Insets.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
            child: GoopText(
              sent
                  ? 'Your email app has the draft — '
                      'hit send there to deliver it.'
                  : 'No email app found — the report is on your '
                      'clipboard. Paste it anywhere.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: FontSizes.bodyMedium,
                height: 1.45,
                color: Colors.white60.withValues(alpha: 0.85),
              ),
            ),
          ).animate(delay: 220.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: Insets.xs),
          GoopText(
            sent ? 'THANKS, PARTNER' : 'PASTE IT INTO ANY MESSAGE',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: accent.withValues(alpha: 0.75),
            ),
          ).animate(delay: 320.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: Insets.lg),
        ],
      ),
    );
  }

  Widget _kindLabel(Color ink) => GoopText(
    'TYPE',
    style: TextStyle(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
      color: ink.withValues(alpha: 0.55),
    ),
  );

  Widget _ctxChip(String label, String value, Color ink) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: GoopText(
              label,
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: ink.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: GoopText(
              value.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: FontSizes.bodyMedium,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kindChip(BugReportKind k, Color ink) {
    final sel = _kind == k;
    final chipColor = ink;
    return InkWell(
      borderRadius: Radii.pill,
      onTap: () {
        Haptics.selection();
        setState(() => _kind = k);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? chipColor.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: Radii.pill,
          border: Border.all(
            color: sel ? chipColor : chipColor.withValues(alpha: 0.3),
            width: sel ? 1.6 : 1.0,
          ),
        ),
        child: GoopText(
          k.label.toUpperCase(),
          style: TextStyle(
            fontSize: FontSizes.labelMedium,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: sel ? chipColor : chipColor.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
    required Color ink,
  }) {
    final accent = ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.all(Radii.md),
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? accent : accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: filled ? accent : accent.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: filled ? Colors.white : accent),
              const SizedBox(width: 8),
              GoopText(
                label,
                style: TextStyle(
                  fontSize: FontSizes.labelMedium,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: filled ? Colors.white : accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
