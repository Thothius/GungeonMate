import 'dart:convert';
import 'dart:typed_data';

/// Wire protocol for local multiplayer. Every message is a compact JSON
/// object sent as a single bytes payload over `nearby_connections`.
///
/// Design notes:
/// * We send **name-only** gun/item references, not full entities.
///   Both phones ship identical asset JSON with the build, so the
///   receiver re-resolves names against its own master data — that
///   keeps payloads small (a typical snapshot is ~300 bytes) and makes
///   stats consistent with whatever asset version each phone has.
/// * Timestamps are milliseconds-since-epoch so snapshots can be
///   last-write-wins when reconnecting after a drop.
/// * `reqId` on requests is a short random token so the responder can
///   tie `requestResp` back to the original ask without needing a full
///   correlation framework.

enum MpRole { main, sidekick }

extension MpRoleWire on MpRole {
  String get wire => switch (this) {
        MpRole.main => 'main',
        MpRole.sidekick => 'sidekick',
      };

  static MpRole parse(String s) => switch (s) {
        'main' => MpRole.main,
        'sidekick' => MpRole.sidekick,
        _ => throw FormatException('Unknown MpRole: $s'),
      };
}

/// Base type for every transport message. Subclasses are `final` so
/// switch-on-runtime-type is exhaustive at the call-site.
sealed class MpMessage {
  const MpMessage();

  /// Wire discriminator.
  String get type;

  /// Subclass-provided JSON body (without the `type` field — that's
  /// added by [encode] so subclasses don't have to remember).
  Map<String, dynamic> toJson();

  Uint8List encode() {
    final map = {'type': type, ...toJson()};
    return Uint8List.fromList(utf8.encode(jsonEncode(map)));
  }

  /// Decode a raw bytes payload. Throws [FormatException] on malformed
  /// JSON or unknown `type` — callers should catch + log + drop so one
  /// bad message doesn't tear down the whole session.
  static MpMessage decode(Uint8List bytes) {
    final s = utf8.decode(bytes, allowMalformed: false);
    final map = jsonDecode(s);
    if (map is! Map<String, dynamic>) {
      throw const FormatException('MpMessage: root is not a JSON object');
    }
    final t = map['type'];
    if (t is! String) {
      throw const FormatException('MpMessage: missing string "type"');
    }
    return switch (t) {
      'hello' => MpHello.fromJson(map),
      'snapshot' => MpSnapshot.fromJson(map),
      'gift' => MpGift.fromJson(map),
      'request' => MpRequest.fromJson(map),
      'requestResp' => MpRequestResp.fromJson(map),
      'endRun' => const MpEndRun(),
      'ping' => MpPing.fromJson(map),
      'pong' => MpPong.fromJson(map),
      'diceChallenge' => MpDiceChallenge.fromJson(map),
      'diceAccept' => const MpDiceAccept(),
      'diceResult' => MpDiceResult.fromJson(map),
      _ => throw FormatException('MpMessage: unknown type "$t"'),
    };
  }
}

/// Sent immediately after the underlying Nearby connection establishes.
/// Confirms role, character, and a display label so the UI can show
/// "Connected to <label> (Cultist)" before the first snapshot lands.
final class MpHello extends MpMessage {
  final MpRole role;
  final String character; // Gungeoneer name
  final String userLabel; // free-form nickname shown in UI
  final String appVersion; // for compat diagnostics
  final int protocolVersion;
  final String? sessionName;
  final String? sessionId;
  final String? pinCode;

  const MpHello({
    required this.role,
    required this.character,
    required this.userLabel,
    required this.appVersion,
    this.protocolVersion = 1,
    this.sessionName,
    this.sessionId,
    this.pinCode,
  });

  static const int currentProtocolVersion = 1;

  @override
  String get type => 'hello';

  @override
  Map<String, dynamic> toJson() => {
        'role': role.wire,
        'character': character,
        'userLabel': userLabel,
        'appVersion': appVersion,
        'protocolVersion': protocolVersion,
        'sessionName': sessionName,
        'sessionId': sessionId,
        if (pinCode != null) 'pinCode': pinCode,
      };

  factory MpHello.fromJson(Map<String, dynamic> j) => MpHello(
        role: MpRoleWire.parse(j['role'] as String),
        character: j['character'] as String? ?? '',
        userLabel: j['userLabel'] as String? ?? 'Player',
        appVersion: j['appVersion'] as String? ?? '',
        protocolVersion: j['protocolVersion'] as int? ?? 1,
        sessionName: j['sessionName'] as String?,
        sessionId: j['sessionId'] as String?,
        pinCode: j['pinCode'] as String?,
      );
}

/// Full state of the sender's local player (names only) + shared
/// dungeon state (coolness/curse/shrines). Sent on every local
/// mutation after a small debounce.
final class MpSnapshot extends MpMessage {
  final String character;
  final List<String> gunNames;
  final List<String> itemNames;
  final double coolness;
  final double curse;
  final List<String> shrinesUsed;
  final int tsMs;

  const MpSnapshot({
    required this.character,
    required this.gunNames,
    required this.itemNames,
    required this.coolness,
    required this.curse,
    required this.shrinesUsed,
    required this.tsMs,
  });

  @override
  String get type => 'snapshot';

  @override
  Map<String, dynamic> toJson() => {
        'character': character,
        'guns': gunNames,
        'items': itemNames,
        'coolness': coolness,
        'curse': curse,
        'shrinesUsed': shrinesUsed,
        'ts': tsMs,
      };

  factory MpSnapshot.fromJson(Map<String, dynamic> j) => MpSnapshot(
        character: j['character'] as String? ?? '',
        gunNames: (j['guns'] as List?)?.cast<String>() ?? const [],
        itemNames: (j['items'] as List?)?.cast<String>() ?? const [],
        coolness: (j['coolness'] as num?)?.toDouble() ?? 0,
        curse: (j['curse'] as num?)?.toDouble() ?? 0,
        shrinesUsed:
            (j['shrinesUsed'] as List?)?.cast<String>() ?? const [],
        tsMs: (j['ts'] as num?)?.toInt() ?? 0,
      );
}

/// "I'm giving you this." Sender has already removed it from their own
/// local state; receiver should add it to their own. Best-effort; if
/// the connection drops mid-send the item is lost in transit. Users
/// can Add it back from the Browse tab if that happens.
final class MpGift extends MpMessage {
  final String kind; // 'gun' | 'item'
  final String name;

  const MpGift({required this.kind, required this.name});

  @override
  String get type => 'gift';

  @override
  Map<String, dynamic> toJson() => {'kind': kind, 'name': name};

  factory MpGift.fromJson(Map<String, dynamic> j) => MpGift(
        kind: j['kind'] as String? ?? '',
        name: j['name'] as String? ?? '',
      );
}

/// "Can I have this?" Fires a bottom-sheet on the recipient. They
/// approve → we additionally receive an [MpGift] message. They deny →
/// we get [MpRequestResp] with `approved: false` and a toast fires.
final class MpRequest extends MpMessage {
  final String reqId;
  final String kind;
  final String name;

  const MpRequest({
    required this.reqId,
    required this.kind,
    required this.name,
  });

  @override
  String get type => 'request';

  @override
  Map<String, dynamic> toJson() => {
        'reqId': reqId,
        'kind': kind,
        'name': name,
      };

  factory MpRequest.fromJson(Map<String, dynamic> j) => MpRequest(
        reqId: j['reqId'] as String? ?? '',
        kind: j['kind'] as String? ?? '',
        name: j['name'] as String? ?? '',
      );
}

final class MpRequestResp extends MpMessage {
  final String reqId;
  final bool approved;

  const MpRequestResp({required this.reqId, required this.approved});

  @override
  String get type => 'requestResp';

  @override
  Map<String, dynamic> toJson() => {
        'reqId': reqId,
        'approved': approved,
      };

  factory MpRequestResp.fromJson(Map<String, dynamic> j) => MpRequestResp(
        reqId: j['reqId'] as String? ?? '',
        approved: j['approved'] as bool? ?? false,
      );
}

/// Either player hit "End run" — both sides clear the run together so
/// summaries line up.
final class MpEndRun extends MpMessage {
  const MpEndRun();
  @override
  String get type => 'endRun';
  @override
  Map<String, dynamic> toJson() => const {};
}

/// Heartbeat. We send one every ~5s; miss 3 in a row and the session
/// flips to disconnected.
final class MpPing extends MpMessage {
  final int tsMs;
  final int? lastSeq;
  const MpPing(this.tsMs, {this.lastSeq});
  @override
  String get type => 'ping';
  @override
  Map<String, dynamic> toJson() => {'ts': tsMs, if (lastSeq != null) 'lastSeq': lastSeq};
  factory MpPing.fromJson(Map<String, dynamic> j) =>
      MpPing((j['ts'] as num?)?.toInt() ?? 0, lastSeq: (j['lastSeq'] as num?)?.toInt());
}

final class MpPong extends MpMessage {
  final int tsMs;
  final int? lastSeq;
  const MpPong(this.tsMs, {this.lastSeq});
  @override
  String get type => 'pong';
  @override
  Map<String, dynamic> toJson() => {'ts': tsMs, if (lastSeq != null) 'lastSeq': lastSeq};
  factory MpPong.fromJson(Map<String, dynamic> j) =>
      MpPong((j['ts'] as num?)?.toInt() ?? 0, lastSeq: (j['lastSeq'] as num?)?.toInt());
}

/// Dice Roll Challenge: Sent to initiate a dice challenge.
final class MpDiceChallenge extends MpMessage {
  final String challengerName;
  const MpDiceChallenge({required this.challengerName});
  @override
  String get type => 'diceChallenge';
  @override
  Map<String, dynamic> toJson() => {'challengerName': challengerName};
  factory MpDiceChallenge.fromJson(Map<String, dynamic> j) => MpDiceChallenge(
        challengerName: j['challengerName'] as String? ?? 'Challenger',
      );
}

/// Dice Roll Accept: Sent to accept the challenge.
final class MpDiceAccept extends MpMessage {
  const MpDiceAccept();
  @override
  String get type => 'diceAccept';
  @override
  Map<String, dynamic> toJson() => const {};
}

/// Dice Roll Result: Sent when the player rolls their dice.
final class MpDiceResult extends MpMessage {
  final int score;
  final List<int> dice;
  const MpDiceResult({required this.score, required this.dice});
  @override
  String get type => 'diceResult';
  @override
  Map<String, dynamic> toJson() => {'score': score, 'dice': dice};
  factory MpDiceResult.fromJson(Map<String, dynamic> j) => MpDiceResult(
        score: j['score'] as int? ?? 0,
        dice: (j['dice'] as List?)?.cast<int>() ?? const [],
      );
}
