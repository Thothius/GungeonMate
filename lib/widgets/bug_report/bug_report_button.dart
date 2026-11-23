import 'package:flutter/material.dart';

import '../../models/bug_report.dart';
import '../../services/app_theme.dart';
import '../../services/haptics.dart';

import 'bug_report_sheet.dart';

/// Bug-report affordance — a bug icon that opens [BugReportSheet] with
/// the given context pre-filled. Accent-colored so it reads as an
/// action, not decoration.
class BugReportButton extends StatelessWidget {
  final BugReportContext report;
  final double size;
  const BugReportButton({super.key, required this.report, this.size = 22});

  /// Compact icon button for AppBars / header rows.
  static Widget iconButton(
    BuildContext context,
    BugReportContext report, {
    double iconSize = 22,
  }) {
    return BugReportButton(report: report, size: iconSize);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.flair.primary;
    return IconButton(
      icon: Icon(Icons.bug_report_outlined, size: size, color: color),
      tooltip: 'Report a bug',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: () {
        Haptics.light();
        BugReportSheet.show(context, report);
      },
    );
  }
}
