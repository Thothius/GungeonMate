import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/bug_report.dart';
import '../utils/asset_paths.dart';

/// Bug-report plumbing — builds a structured mailto to the dedicated
/// report inbox and a clipboard fallback. No server, no account: the
/// user's own email app sends it.
///
/// Subject format is pipe-delimited so the Apps Script pipeline can parse
/// fields positionally:
///   GM-BUG v3.7.0|Bug|Item Detail · Gun|Hegemony
/// Body = user notes first, then a --- context block with app/platform
/// metadata.
class BugReport {
  /// Dedicated report inbox. Swap here when the project moves to a
  /// dedicated address.
  static const String email = 'faaremets.fristjan@gmail.com';

  static String _safe(String s) => s.replaceAll('|', '/').trim();

  /// e.g. `GM-BUG v3.7.0|Bug|Item Detail|Hegemony`
  static String subjectFor(BugReportContext ctx) {
    final parts = <String>[
      'GM-BUG v$kAppVersion',
      ctx.kind.label,
      _safe(ctx.screen),
      if (ctx.entity != null && ctx.entity!.trim().isNotEmpty)
        _safe(ctx.entity!),
    ];
    return parts.join('|');
  }

  /// Notes first (that's what the user wrote), context block after the
  /// divider so the pipeline can split on '\n---\n'.
  static String bodyFor(BugReportContext ctx, String notes) {
    final entity = ctx.entity == null || ctx.entity!.trim().isEmpty
        ? '—'
        : ctx.entity!;
    return '$notes\n\n---\n'
        'APP: GungeonMate v$kAppVersion\n'
        'PLATFORM: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
        'KIND: ${ctx.kind.label}\n'
        'SCREEN: ${ctx.screen}\n'
        'ENTITY: $entity\n'
        'TIME: ${DateTime.now().toIso8601String()}\n';
  }

  /// mailto URI — exposed for tests.
  static Uri mailtoUri(BugReportContext ctx, String notes) {
    return Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subjectFor(ctx),
        'body': bodyFor(ctx, notes),
      },
    );
  }

  /// Launch the user's email app. Returns false when no handler exists —
  /// callers should fall back to [copyReport].
  static Future<bool> send(BugReportContext ctx, String notes) async {
    final uri = mailtoUri(ctx, notes);
    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      return false;
    }
  }

  /// Copy the full report (subject line + body) to the clipboard so the
  /// user can paste it into any app — the no-email-app fallback.
  static Future<void> copyReport(BugReportContext ctx, String notes) async {
    final text = '${subjectFor(ctx)}\n\n${bodyFor(ctx, notes)}';
    await Clipboard.setData(ClipboardData(text: text));
  }
}
