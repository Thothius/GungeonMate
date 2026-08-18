import 'dart:convert';

/// A persistent device pairing between two regular co-op partners.
///
/// Once paired, two devices share a secret [pairId] that substitutes for
/// the per-session 4-digit PIN. This eliminates the manual PIN exchange
/// on every new session — a one-tap "Connect" is all that's needed.
///
/// Pairing is symmetric: both devices store a [PairedPartner] record
/// pointing at the other. The [pairId] is identical on both sides and
/// used as the Nearby Connections endpoint-name filter (advertised as
/// `nickname#<pairId>`, discovered with `pinCode: <pairId>`).
///
/// Stored in SharedPreferences under `mp.paired_partners` as a JSON
/// string list. See [PairedPartnersStore] for the persistence layer.
class PairedPartner {
  /// 8-char uppercase hex secret shared between the two paired devices.
  /// Acts as a persistent "PIN" — long enough to be unguessable, short
  /// enough to never need manual entry.
  final String pairId;

  /// The partner's nickname (captured during pairing). Shown in the UI
  /// so the user can identify which partner this is.
  final String partnerNickname;

  /// When the pairing was established (ms since epoch).
  final int createdAtMs;

  /// Last time a connection was successfully established with this
  /// partner (ms since epoch). Null if never connected since pairing.
  final int? lastConnectedAtMs;

  const PairedPartner({
    required this.pairId,
    required this.partnerNickname,
    required this.createdAtMs,
    this.lastConnectedAtMs,
  });

  PairedPartner copyWith({
    String? pairId,
    String? partnerNickname,
    int? createdAtMs,
    int? lastConnectedAtMs,
  }) =>
      PairedPartner(
        pairId: pairId ?? this.pairId,
        partnerNickname: partnerNickname ?? this.partnerNickname,
        createdAtMs: createdAtMs ?? this.createdAtMs,
        lastConnectedAtMs: lastConnectedAtMs ?? this.lastConnectedAtMs,
      );

  Map<String, dynamic> toJson() => {
        'pairId': pairId,
        'partnerNickname': partnerNickname,
        'createdAtMs': createdAtMs,
        if (lastConnectedAtMs != null) 'lastConnectedAtMs': lastConnectedAtMs,
      };

  factory PairedPartner.fromJson(Map<String, dynamic> json) => PairedPartner(
        pairId: json['pairId'] as String? ?? '',
        partnerNickname: json['partnerNickname'] as String? ?? 'Partner',
        createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
        lastConnectedAtMs: (json['lastConnectedAtMs'] as num?)?.toInt(),
      );

  String encode() => jsonEncode(toJson());

  static PairedPartner decode(String s) =>
      PairedPartner.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
