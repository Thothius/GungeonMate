import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart' show Color;

/// Wire protocol for local multiplayer. Every message is a compact JSON
/// object sent as a single bytes payload over `nearby_connections`.
///
/// Design notes:
/// * We send **name-only** gun/item references, not full entities.
///   Both phones ship identical asset JSON with the build, so the
///   receiver re-resolves names against its own master data — that
///   keeps payloads small (a typical snapshot is ~300 bytes) and makes
///   stats consistent with whatever asset version each phone has.
/// * Shared dungeon state (coolness/curse/shrines) is
///   **Main-authoritative**: the Main Player's snapshot is the source
///   of truth. The Sidekick sends [MpSharedStateDelta] messages when
///   it modifies shared state; Main applies the delta and re-broadcasts
///   via snapshot. This eliminates lost-write races.
/// * `reqId` on requests is a short random token so the responder can
///   tie `requestResp` back to the original ask without needing a full
///   correlation framework.

/// Semantic colors for MP UI states. These are intentionally NOT
/// theme-bound — "connected" should always be green regardless of the
/// active theme, just like a system status LED.
class MpColors {
  const MpColors._();
  /// Connected / success state — used for checkmarks, link icons,
  /// "Connection restored" snackbars, and the connected portrait pair.
  static const Color connected = Color(0xFF00E676);

  /// Reconnecting / warning state — used for the reconnect banner,
  /// dialog border, spinner, and persistent banner text.
  static const Color reconnecting = Color(0xFFFFC107);

  /// Danger / cancel state — used for "Cancel Run" buttons and
  /// destructive MP actions.
  static const Color danger = Color(0xFFFF5252);
}

enum MpRole { main, sidekick }

/// Which multiplayer flow a session belongs to. Classic = the original
/// lobby flow; Paradox = the v3.0 avatar/lobby/pause flow. Cross-mode
/// pairing is impossible because each mode uses a different Nearby
/// Connections serviceId — this field is belt-and-suspenders.
enum MpMode { classic, paradox }

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

extension MpModeWire on MpMode {
  String get wire => switch (this) {
    MpMode.classic => 'classic',
    MpMode.paradox => 'paradox',
  };

  static MpMode parse(String? s) => switch (s) {
    'paradox' => MpMode.paradox,
    _ => MpMode.classic,
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
      'diceDecline' => const MpDiceDecline(),
      'diceCancel' => const MpDiceCancel(),
      'diceResult' => MpDiceResult.fromJson(map),
      'emote' => MpEmote.fromJson(map),
      'sharedStateDelta' => MpSharedStateDelta.fromJson(map),
      'startRun' => const MpStartRun(),
      'pause' => const MpPause(),
      'resume' => const MpResume(),
      'chat' => MpChat.fromJson(map),
      'surprise' => MpSurprise.fromJson(map),
      'peerEdit' => MpPeerEdit.fromJson(map),
      'sessionMeta' => MpSessionMeta.fromJson(map),
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
  final MpMode mode; // classic | paradox
  final String avatarId; // cosmetic avatar id ('' = none)
  final String runTitle; // Paradox RNG run name ('' = not generated)
  final int sessionNumber; // Paradox session counter (0-based)

  const MpHello({
    required this.role,
    required this.character,
    required this.userLabel,
    required this.appVersion,
    this.protocolVersion = 3,
    this.mode = MpMode.classic,
    this.avatarId = '',
    this.runTitle = '',
    this.sessionNumber = 0,
  });

  static const int currentProtocolVersion = 3;

  @override
  String get type => 'hello';

  @override
  Map<String, dynamic> toJson() => {
    'role': role.wire,
    'character': character,
    'userLabel': userLabel,
    'appVersion': appVersion,
    'protocolVersion': protocolVersion,
    if (mode != MpMode.classic) 'mode': mode.wire,
    if (avatarId.isNotEmpty) 'avatarId': avatarId,
    if (runTitle.isNotEmpty) 'runTitle': runTitle,
    if (sessionNumber != 0) 'sessionNumber': sessionNumber,
  };

  factory MpHello.fromJson(Map<String, dynamic> j) => MpHello(
    role: MpRoleWire.parse(j['role'] as String),
    character: j['character'] as String? ?? '',
    userLabel: j['userLabel'] as String? ?? 'Player',
    appVersion: j['appVersion'] as String? ?? '',
    protocolVersion: j['protocolVersion'] as int? ?? 3,
    mode: MpModeWire.parse(j['mode'] as String?),
    avatarId: j['avatarId'] as String? ?? '',
    runTitle: j['runTitle'] as String? ?? '',
    sessionNumber: (j['sessionNumber'] as num?)?.toInt() ?? 0,
  );
}

/// Full state of the sender's local player (names only) + shared
/// dungeon state (coolness/curse/shrines). Sent on every local
/// mutation after a small debounce.
///
/// Shared state is **Main-authoritative**: only the Main Player's
/// snapshot carries authoritative coolness/curse/shrines. The
/// Sidekick's snapshot fields are ignored by Main. The Sidekick
/// sends [MpSharedStateDelta] messages instead, which Main applies
/// and then re-broadcasts via its own snapshot.
final class MpSnapshot extends MpMessage {
  final String character;
  final List<String> gunNames;
  final List<String> itemNames;
  final double coolness;
  final double curse;
  final List<String> shrinesUsed;

  const MpSnapshot({
    required this.character,
    required this.gunNames,
    required this.itemNames,
    required this.coolness,
    required this.curse,
    required this.shrinesUsed,
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
  };

  factory MpSnapshot.fromJson(Map<String, dynamic> j) => MpSnapshot(
    character: j['character'] as String? ?? '',
    gunNames: (j['guns'] as List?)?.cast<String>() ?? const [],
    itemNames: (j['items'] as List?)?.cast<String>() ?? const [],
    coolness: (j['coolness'] as num?)?.toDouble() ?? 0,
    curse: (j['curse'] as num?)?.toDouble() ?? 0,
    shrinesUsed: (j['shrinesUsed'] as List?)?.cast<String>() ?? const [],
  );
}

/// "I'm giving you this." Sender has already removed it from their own
/// local state; receiver should add it to their own. Best-effort; if
/// the connection drops mid-send the item is lost in transit. Users
/// can Add it back from the Browse tab if that happens.
final class MpGift extends MpMessage {
  final String kind; // 'gun' | 'item'
  final String name;
  final String giftId; // dedup key

  const MpGift({required this.kind, required this.name, required this.giftId});

  @override
  String get type => 'gift';

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'name': name,
    'giftId': giftId,
  };

  factory MpGift.fromJson(Map<String, dynamic> j) => MpGift(
    kind: j['kind'] as String? ?? '',
    name: j['name'] as String? ?? '',
    giftId: j['giftId'] as String? ?? '',
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
  Map<String, dynamic> toJson() => {'reqId': reqId, 'kind': kind, 'name': name};

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
  Map<String, dynamic> toJson() => {'reqId': reqId, 'approved': approved};

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

/// Heartbeat. Sent every 5s; if no message from peer within 25s the
/// session flips to disconnected.
final class MpPing extends MpMessage {
  final int tsMs;
  const MpPing(this.tsMs);
  @override
  String get type => 'ping';
  @override
  Map<String, dynamic> toJson() => {'ts': tsMs};
  factory MpPing.fromJson(Map<String, dynamic> j) =>
    MpPing((j['ts'] as num?)?.toInt() ?? 0);
}

final class MpPong extends MpMessage {
  final int tsMs;
  const MpPong(this.tsMs);
  @override
  String get type => 'pong';
  @override
  Map<String, dynamic> toJson() => {'ts': tsMs};
  factory MpPong.fromJson(Map<String, dynamic> j) =>
    MpPong((j['ts'] as num?)?.toInt() ?? 0);
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

/// Dice Roll Decline: Sent to decline the challenge.
final class MpDiceDecline extends MpMessage {
  const MpDiceDecline();
  @override
  String get type => 'diceDecline';
  @override
  Map<String, dynamic> toJson() => const {};
}

/// Dice Roll Cancel: Sent by the challenger to withdraw a pending challenge.
final class MpDiceCancel extends MpMessage {
  const MpDiceCancel();
  @override
  String get type => 'diceCancel';
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

/// Lightweight player-to-player emote (kiss, slap, etc.). Purely visual —
/// no gameplay effect. The receiver shows a floating overlay animation.
/// `action` discriminates the visual; `from` is the sender's nickname.
final class MpEmote extends MpMessage {
  final String from;
  final String action; // 'kiss' | 'slap' | future emotes

  const MpEmote({required this.from, required this.action});

  @override
  String get type => 'emote';

  @override
  Map<String, dynamic> toJson() => {'from': from, 'action': action};

  factory MpEmote.fromJson(Map<String, dynamic> j) => MpEmote(
    from: j['from'] as String? ?? 'Player',
    action: j['action'] as String? ?? 'kiss',
  );
}

/// Shared-state delta — sent by the Sidekick when it modifies
/// coolness, curse, or shrine usage. Only the Main Player processes
/// this: it applies the delta to its own RunProvider (which triggers
/// a snapshot broadcast back to both sides). This is the
/// Main-authoritative model — it eliminates lost-write races that
/// occurred when both sides sent full shared-state snapshots
/// simultaneously.
///
/// `coolnessDelta` / `curseDelta` are signed deltas (e.g. +1 for
/// smoking a cigarette, -1 for removing a cursed item). `shrineName`
/// is set when a shrine is used (additive — shrines are a list, not
/// a counter).
final class MpSharedStateDelta extends MpMessage {
  final double coolnessDelta;
  final double curseDelta;
  final String? shrineName;

  const MpSharedStateDelta({
    this.coolnessDelta = 0,
    this.curseDelta = 0,
    this.shrineName,
  });

  @override
  String get type => 'sharedStateDelta';

  @override
  Map<String, dynamic> toJson() => {
    'coolnessDelta': coolnessDelta,
    'curseDelta': curseDelta,
    if (shrineName != null) 'shrineName': shrineName,
  };

  factory MpSharedStateDelta.fromJson(Map<String, dynamic> j) =>
    MpSharedStateDelta(
      coolnessDelta: (j['coolnessDelta'] as num?)?.toDouble() ?? 0,
      curseDelta: (j['curseDelta'] as num?)?.toDouble() ?? 0,
      shrineName: j['shrineName'] as String?,
    );
}

// =============================================================================
// Protocol v3 — Paradox Mode messages
// =============================================================================

/// Main → Sidekick: the lobby "START RUN" button was pressed. Both sides
/// leave the pre-run lobby and enter the run view.
final class MpStartRun extends MpMessage {
  const MpStartRun();
  @override
  String get type => 'startRun';
  @override
  Map<String, dynamic> toJson() => const {};
}

/// Either player paused the session. Idempotent — receivers already
/// paused just ignore it. The authoritative paused flag also rides on
/// [MpSessionMeta] so late-joining reconnects land on the right state.
final class MpPause extends MpMessage {
  const MpPause();
  @override
  String get type => 'pause';
  @override
  Map<String, dynamic> toJson() => const {};
}

/// Either player resumed the session. Idempotent, same semantics as
/// [MpPause].
final class MpResume extends MpMessage {
  const MpResume();
  @override
  String get type => 'resume';
  @override
  Map<String, dynamic> toJson() => const {};
}

/// Session metadata — sent by the Main Player after every hello and
/// whenever any field changes. **Main-authoritative**: the Sidekick
/// adopts these values verbatim. This is how a peer that reconnects
/// after missing an edge message (pause/resume) still lands on the
/// correct session state.
final class MpSessionMeta extends MpMessage {
  final String runTitle;
  final int sessionNumber;
  final bool paused;

  const MpSessionMeta({
    this.runTitle = '',
    this.sessionNumber = 0,
    this.paused = false,
  });

  @override
  String get type => 'sessionMeta';

  @override
  Map<String, dynamic> toJson() => {
    'runTitle': runTitle,
    'sessionNumber': sessionNumber,
    'paused': paused,
  };

  factory MpSessionMeta.fromJson(Map<String, dynamic> j) => MpSessionMeta(
    runTitle: j['runTitle'] as String? ?? '',
    sessionNumber: (j['sessionNumber'] as num?)?.toInt() ?? 0,
    paused: j['paused'] as bool? ?? false,
  );
}

/// Peer-to-peer chat line. `text` may embed `:sprite_key:` tokens —
/// resolved against the local emote sprite catalog at render time, so
/// the wire payload stays pure text. `id` dedupes replays.
final class MpChat extends MpMessage {
  final String id;
  final String from;
  final String text;

  const MpChat({required this.id, required this.from, required this.text});

  @override
  String get type => 'chat';

  @override
  Map<String, dynamic> toJson() => {'id': id, 'from': from, 'text': text};

  factory MpChat.fromJson(Map<String, dynamic> j) => MpChat(
    id: j['id'] as String? ?? '',
    from: j['from'] as String? ?? 'Player',
    text: j['text'] as String? ?? '',
  );
}

/// A "Surprise" — a big floating card shown on the peer's screen.
/// `preset` names a built-in surprise ('love' | 'goodjob' | 'meow' |
/// 'gungeon' | 'ohshit'); when `preset` is 'custom', `text` (≤30 chars)
/// and `spriteKey` carry the user-built content.
final class MpSurprise extends MpMessage {
  final String preset;
  final String text;
  final String spriteKey;
  /// Extra fullscreen effect — 'bulletrain' | 'heartsburst' | 'explosion'
  /// (empty = preset's own fx). Wire-additive: old peers ignore it.
  final String fx;

  const MpSurprise({
    required this.preset,
    this.text = '',
    this.spriteKey = '',
    this.fx = '',
  });

  @override
  String get type => 'surprise';

  @override
  Map<String, dynamic> toJson() => {
        'preset': preset,
        if (text.isNotEmpty) 'text': text,
        if (spriteKey.isNotEmpty) 'spriteKey': spriteKey,
        if (fx.isNotEmpty) 'fx': fx,
      };

  factory MpSurprise.fromJson(Map<String, dynamic> j) => MpSurprise(
    preset: j['preset'] as String? ?? 'custom',
    text: j['text'] as String? ?? '',
    spriteKey:
        (j['spriteKey'] ?? j['sprite']) as String? ?? '',
    fx: j['fx'] as String? ?? '',
  );
}

/// Direct edit on the peer's inventory — the co-op trust model where
/// both players can modify both inventories. `op` is 'add' | 'remove' |
/// 'clear'. Receiver applies it to *its own* slot with `force: true`
/// and rebroadcasts a snapshot so both sides converge.
final class MpPeerEdit extends MpMessage {
  final String op; // 'add' | 'remove' | 'clear'
  final String kind; // 'gun' | 'item'
  final String name;

  const MpPeerEdit({
    required this.op,
    this.kind = '',
    this.name = '',
  });

  @override
  String get type => 'peerEdit';

  @override
  Map<String, dynamic> toJson() => {
    'op': op,
    if (kind.isNotEmpty) 'kind': kind,
    if (name.isNotEmpty) 'name': name,
  };

  factory MpPeerEdit.fromJson(Map<String, dynamic> j) => MpPeerEdit(
    op: j['op'] as String? ?? '',
    kind: j['kind'] as String? ?? '',
    name: j['name'] as String? ?? '',
  );
}


/// A logged activity entry for the messages panel — chat, surprise,
/// emote, transfer, or connect/disconnect note.
class MpEvent {
  final String kind; // 'chat' | 'surprise' | 'emote' | 'transfer' | 'system'
  final String from;
  final String text;
  final bool mine;
  final DateTime ts;

  MpEvent._(this.kind, this.from, this.text, this.mine)
      : ts = DateTime.now();

  factory MpEvent.chat(
          {required String from, required String text, required bool mine}) =>
      MpEvent._('chat', from, text, mine);
  factory MpEvent.event(
          {required String kind,
          required String from,
          required String text,
          required bool mine}) =>
      MpEvent._(kind, from, text, mine);
}
