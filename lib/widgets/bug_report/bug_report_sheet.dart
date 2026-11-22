import 'package:flutter/material.dart';

import '../../models/bug_report.dart';
import '../../services/app_theme.dart';
import '../../services/bug_report.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../theme/tokens.dart';
import '../../utils/responsive.dart';
import '../skeuo/skeuo_tokens.dart';

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

class _BugReportSheetState extends State<BugReportSheet> {
  late BugReportKind _kind = widget.context.kind;
  final _notesCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
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
    if (notes.isEmpty || _sending) return;
    setState(() => _sending = true);
    Haptics.medium();
    final ctx = _effective;
    final ok = await BugReport.send(ctx, notes);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      _snack('Report handed to your email app');
    } else {
      await BugReport.copyReport(ctx, notes);
      if (!mounted) return;
      setState(() => _sending = false);
      _snack('No email app found — report copied, paste it anywhere');
    }
  }

  Future<void> _copy() async {
    final notes = _notesCtrl.text.trim();
    if (notes.isEmpty) return;
    await BugReport.copyReport(_effective, notes);
    if (!mounted) return;
    _snack('Report copied to clipboard');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GoopText(msg),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.displayedFlair;
    final sf = Responsive.factor(context);
    final skeuo = AppTheme.isSkeuo;
    final surface = skeuo ? Skeuo.card : flair.card;
    final ink = skeuo ? Skeuo.ink : flair.primary;

    return Padding(
      // Lift above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: skeuo
              ? Border.all(color: Skeuo.ink.withValues(alpha: 0.5), width: 1.4)
              : Border.all(
                  color: flair.primary.withValues(alpha: 0.2),
                ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
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
                        color: skeuo ? Skeuo.accent : ink,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GoopText(
                          'REPORT A BUG',
                          style: TextStyle(
                            fontSize: FontSizes.titleSmall * sf,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                            color: skeuo ? Skeuo.ink : flair.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ctxChip('SCREEN', widget.context.screen, ink, skeuo),
                      if (widget.context.entity != null &&
                          widget.context.entity!.isNotEmpty)
                        _ctxChip('ITEM', widget.context.entity!, ink, skeuo),
                      const SizedBox(height: Insets.sm),
                      _kindLabel(ink, skeuo),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final k in BugReportKind.values)
                            _kindChip(k, ink, skeuo),
                        ],
                      ),
                      const SizedBox(height: Insets.md),
                      TextField(
                        controller: _notesCtrl,
                        maxLines: 5,
                        minLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: FontSizes.bodyMedium,
                          color: skeuo ? Skeuo.ink : null,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'What happened? What did you expect?',
                          hintStyle: TextStyle(
                            color: (skeuo ? Skeuo.pencil : Colors.white70)
                                .withValues(alpha: 0.7),
                          ),
                          filled: true,
                          fillColor: skeuo
                              ? Skeuo.insetPaper
                              : flair.primary.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radii.md),
                            borderSide: BorderSide(
                              color: skeuo
                                  ? Skeuo.ink.withValues(alpha: 0.35)
                                  : flair.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radii.md),
                            borderSide: BorderSide(
                              color: skeuo
                                  ? Skeuo.ink.withValues(alpha: 0.35)
                                  : flair.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radii.md),
                            borderSide: BorderSide(
                              color: skeuo ? Skeuo.accent : ink,
                              width: 1.6,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(Insets.md),
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
                              skeuo: skeuo,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _actionButton(
                              label: _sending ? 'SENDING…' : 'SEND REPORT',
                              icon: Icons.send_rounded,
                              filled: true,
                              onTap: _send,
                              ink: ink,
                              skeuo: skeuo,
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
                          color: (skeuo ? Skeuo.pencil : Colors.white60)
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: Insets.lg),
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

  Widget _kindLabel(Color ink, bool skeuo) => GoopText(
    'TYPE',
    style: TextStyle(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
      color: ink.withValues(alpha: 0.55),
    ),
  );

  Widget _ctxChip(String label, String value, Color ink, bool skeuo) {
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
                color: skeuo ? Skeuo.ink : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kindChip(BugReportKind k, Color ink, bool skeuo) {
    final sel = _kind == k;
    final chipColor = skeuo ? Skeuo.accent : ink;
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
    required bool skeuo,
  }) {
    final accent = skeuo ? Skeuo.accent : ink;
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
              Icon(
                icon,
                size: 18,
                color: filled ? (skeuo ? Skeuo.paper : Colors.white) : accent,
              ),
              const SizedBox(width: 8),
              GoopText(
                label,
                style: TextStyle(
                  fontSize: FontSizes.labelMedium,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color:
                      filled
                          ? (skeuo ? Skeuo.paper : Colors.white)
                          : accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
