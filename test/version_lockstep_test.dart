import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/utils/asset_paths.dart' show kAppVersion;

/// Version lockstep — pubspec.yaml, kAppVersion, changelog.json top
/// entry, and VERSION_HISTORY.md top heading must all agree. Drift
/// between these has shipped before; this test makes it impossible.
void main() {
  String pubspecVersion() {
    final text = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(r'^version:\s*(\d+\.\d+\.\d+)', multiLine: true)
        .firstMatch(text);
    return m?.group(1) ?? '';
  }

  String changelogTopVersion() {
    final json =
        jsonDecode(File('assets/data/changelog.json').readAsStringSync());
    // changelog.json is a bare list of entries.
    final entries = json is List ? json : json['entries'] as List;
    final v = entries.first['version'] as String;
    return v.startsWith('v') ? v.substring(1) : v;
  }

  String historyTopVersion() {
    final text = File('VERSION_HISTORY.md').readAsStringSync();
    final m = RegExp(r'v?(\d+\.\d+\.\d+)').firstMatch(text);
    return m?.group(1) ?? '';
  }

  test('pubspec version matches kAppVersion', () {
    expect(pubspecVersion(), kAppVersion);
  });

  test('changelog top entry matches kAppVersion', () {
    expect(changelogTopVersion(), kAppVersion);
  });

  test('VERSION_HISTORY top entry matches kAppVersion', () {
    expect(historyTopVersion(), kAppVersion);
  });
}
