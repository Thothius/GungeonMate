import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/paired_partner.dart';

/// Persisted store of [PairedPartner]s — the device's co-op partner
/// address book. Backed by SharedPreferences (`mp.paired_partners`).
///
/// Exposed as a single [ValueNotifier] so the lobby UI rebuilds
/// automatically when a partner is added or removed. Mirrors the
/// [HomeCustomization] notifier pattern.
class PairedPartnersStore {
  static const _key = 'mp.paired_partners';

  static final ValueNotifier<List<PairedPartner>> notifier =
      ValueNotifier<List<PairedPartner>>(const []);

  /// Load persisted partners into [notifier]. Call once at startup.
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? const [];
    final list = <PairedPartner>[];
    for (final s in raw) {
      try {
        list.add(PairedPartner.decode(s));
      } catch (_) {
        // Skip malformed entries — never crash on bad stored data.
      }
    }
    // Newest pairing first.
    list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    notifier.value = list;
  }

  static List<PairedPartner> get all => notifier.value;

  /// Find a partner by pairId, or null.
  static PairedPartner? byId(String pairId) {
    for (final p in notifier.value) {
      if (p.pairId == pairId) return p;
    }
    return null;
  }

  /// Add or replace a partner (keyed by pairId) and persist.
  static Future<void> upsert(PairedPartner partner) async {
    final list = <PairedPartner>[];
    for (final p in notifier.value) {
      if (p.pairId != partner.pairId) list.add(p);
    }
    list.add(partner);
    list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    notifier.value = list;
    await _persist(list);
  }

  /// Update [lastConnectedAtMs] for a partner after a successful
  /// connection. No-op if the pairId isn't known.
  static Future<void> markConnected(String pairId) async {
    final list = <PairedPartner>[];
    var changed = false;
    for (final p in notifier.value) {
      if (p.pairId == pairId) {
        list.add(p.copyWith(
          lastConnectedAtMs: DateTime.now().millisecondsSinceEpoch,
        ));
        changed = true;
      } else {
        list.add(p);
      }
    }
    if (!changed) return;
    notifier.value = list;
    await _persist(list);
  }

  /// Remove a partner by pairId and persist.
  static Future<void> remove(String pairId) async {
    final list =
        notifier.value.where((p) => p.pairId != pairId).toList(growable: false);
    notifier.value = list;
    await _persist(list);
  }

  static Future<void> _persist(List<PairedPartner> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, list.map((e) => e.encode()).toList());
  }
}
