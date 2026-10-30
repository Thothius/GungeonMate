import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../models/multiplayer_messages.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../services/mp_session.dart';
import '../../utils/responsive.dart';
import '../../services/app_theme.dart';
import 'avatar_frame.dart';
import 'emote_sprite_catalog.dart';

/// Paradox chat — bottom sheet with message history and a composer
/// supporting inline `:sprite_key:` emotes. The wire payload stays
/// pure text; sprites resolve locally via [EmoteSpriteCatalog] so both
/// devices render identically. Messages typed while disconnected are
/// queued by [MpSession] and flushed on reconnect.
Future<void> showParadoxChatSheet(BuildContext context) {
  Haptics.selection();
  final session = context.read<MpSession>();
  session.markChatRead();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12081F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.62,
            child: const ParadoxChatSheet(),
          ),
        ),
  );
}

class ParadoxChatSheet extends StatefulWidget {
  const ParadoxChatSheet({super.key});

  @override
  State<ParadoxChatSheet> createState() => _ParadoxChatSheetState();
}

class _ParadoxChatSheetState extends State<ParadoxChatSheet> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  List<EmoteSprite> _suggestions = [];
  bool _catalogReady = false;

  @override
  void initState() {
    super.initState();
    // Open at the latest message, not the top of the history.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
    EmoteSpriteCatalog.ensureLoaded().then((_) {
      if (mounted) setState(() => _catalogReady = true);
    });
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// `:partial` at the caret → show matching sprites in a strip.
  void _onTextChanged() {
    final text = _ctrl.text;
    final sel = _ctrl.selection;
    if (!sel.isValid || sel.start < 0) return;
    final before = text.substring(0, sel.start);
    final m = RegExp(r':([a-z0-9_]{1,30})$').firstMatch(before);
    if (m == null) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    final results = EmoteSpriteCatalog.search(m.group(1)!);
    setState(() => _suggestions = results);
  }

  void _applySuggestion(EmoteSprite s) {
    final text = _ctrl.text;
    final sel = _ctrl.selection;
    final before = text.substring(0, sel.start);
    final m = RegExp(r':([a-z0-9_]{1,30})$').firstMatch(before);
    if (m == null) return;
    final replaced = '${before.substring(0, m.start)}:${s.key}:';
    final after = text.substring(sel.end);
    _ctrl.text = '$replaced$after';
    _ctrl.selection = TextSelection.collapsed(offset: replaced.length);
    setState(() => _suggestions = []);
    Haptics.selection();
  }

  void _send() {
    final session = context.read<MpSession>();
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    session.sendChatMessage(text);
    _ctrl.clear();
    setState(() => _suggestions = []);
    Haptics.light();
    // Scroll to the newest line.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final session = context.watch<MpSession>();
    final connected = session.phase == MpPhase.connected;

    return Column(
      children: [
        // Header
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        GoopText(
          'CHAT',
          style: TextStyle(
            fontSize: 11 * sf,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: const Color(0xFFB388FF).withValues(alpha: 0.8),
          ),
        ),
        // History
        Expanded(
          child:
              session.sessionEvents.isEmpty
                  ? Center(
                    child: GoopText(
                      'No messages yet.\nType below — or try :heart or :gun_',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13 * sf,
                        color: Colors.white.withValues(alpha: 0.35),
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  )
                  : ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14 * sf,
                      vertical: 8,
                    ),
                    itemCount: session.sessionEvents.length,
                    itemBuilder:
                        (_, i) =>
                            _ConvoRow(e: session.sessionEvents[i], sf: sf),
                  ),
        ),
        // Autocomplete strip
        if (_suggestions.isNotEmpty)
          SizedBox(
            height: 52 * sf,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 10 * sf),
              children: [
                for (final s in _suggestions)
                  _SuggestionChip(
                    sprite: s,
                    onTap: () => _applySuggestion(s),
                    sf: sf,
                  ),
              ],
            ),
          ),
        // Composer
        Container(
          padding: EdgeInsets.fromLTRB(10 * sf, 6 * sf, 10 * sf, 10 * sf),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Pick a Gungeon icon',
                icon: Icon(
                  Icons.grid_view_rounded,
                  size: 22 * sf,
                  color:
                      _catalogReady ? const Color(0xFFB388FF) : Colors.white24,
                ),
                onPressed: _catalogReady ? _openSpritePicker : null,
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  maxLength: 500,
                  maxLines: null,
                  style: TextStyle(fontSize: 14 * sf),
                  decoration: InputDecoration(
                    hintText:
                        connected
                            ? 'Message… (: for icons)'
                            : 'Offline — messages send on reconnect',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 13 * sf,
                    ),
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12 * sf,
                      vertical: 10 * sf,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB388FF)),
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              SizedBox(width: 6 * sf),
              IconButton(
                tooltip: 'Send',
                icon: Icon(
                  Icons.send_rounded,
                  size: 22 * sf,
                  color: const Color(0xFF00E676),
                ),
                onPressed: _send,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openSpritePicker() async {
    final picked = await showModalBottomSheet<EmoteSprite>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF140B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder:
          (_) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const _SpritePickerSheet(),
          ),
    );
    if (picked != null && mounted) {
      final text = _ctrl.text;
      final sel = _ctrl.selection.isValid ? _ctrl.selection.start : text.length;
      final inserted = ':${picked.key}:';
      _ctrl.text = text.substring(0, sel) + inserted + text.substring(sel);
      _ctrl.selection = TextSelection.collapsed(offset: sel + inserted.length);
      _focus.requestFocus();
    }
  }
}

// ── Chat bubble with inline sprite rendering ─────────────────────

class _ConvoRow extends StatelessWidget {
  final MpEvent e;
  final double sf;
  const _ConvoRow({required this.e, required this.sf});

  static final _tokenRe = RegExp(r':([a-z]+_[a-z0-9_]+):');

  @override
  Widget build(BuildContext context) {
    final session = context.read<MpSession>();
    final flair = AppTheme.flair;
    if (e.kind != 'chat') {
      final icon = switch (e.kind) {
        'transfer' => Icons.swap_horiz_rounded,
        'surprise' => Icons.auto_awesome_rounded,
        'emote' => Icons.emoji_emotions_rounded,
        _ => Icons.info_outline_rounded,
      };
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.symmetric(horizontal: 10 * sf, vertical: 5 * sf),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13 * sf,
                color: flair.primary.withValues(alpha: 0.7),
              ),
              SizedBox(width: 6 * sf),
              GoopText(
                e.kind == 'transfer' || e.kind == 'surprise'
                    ? e.text
                    : '${e.from} · ${e.text}',
                style: TextStyle(
                  fontSize: 11 * sf,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final mine = e.mine;
    final avatarId = mine ? session.avatarId : session.peerAvatarId;
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: EdgeInsets.symmetric(horizontal: 12 * sf, vertical: 8 * sf),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.68,
      ),
      decoration: BoxDecoration(
        color: mine ? flair.primary.withValues(alpha: 0.25) : flair.card,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(mine ? 14 : 4),
          bottomRight: Radius.circular(mine ? 4 : 14),
        ),
        border:
            mine
                ? Border.all(color: flair.primary.withValues(alpha: 0.3))
                : null,
      ),
      child: Text.rich(
        _buildContent(e.text, sf),
        style: TextStyle(
          fontSize: 13.5 * sf,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
    final avatar = Column(
      children: [
        FramedAvatar(id: avatarId, size: 22 * sf, radius: 6),
        SizedBox(height: 2),
        GoopText(
          mine ? 'You' : e.from,
          style: TextStyle(
            fontSize: 8 * sf,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color:
                mine ? flair.primary : flair.secondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            mine
                ? [bubble, SizedBox(width: 6 * sf), avatar]
                : [avatar, SizedBox(width: 6 * sf), bubble],
      ),
    );
  }

  /// Splits `:key:` tokens out of text and renders them as inline
  /// sprite images; unknown tokens render as literal text.
  TextSpan _buildContent(String text, double sf) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _tokenRe.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final sprite = EmoteSpriteCatalog.byKey(m.group(1)!);
      if (sprite != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Tooltip(
                message: sprite.label,
                child: Image.asset(
                  sprite.assetPath,
                  width: 52 * sf,
                  height: 52 * sf,
                  filterQuality: FilterQuality.none,
                  errorBuilder:
                      (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        size: 18 * sf,
                        color: Colors.white24,
                      ),
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: m.group(0)));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(children: spans);
  }
}

// ── Autocomplete chip ────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final EmoteSprite sprite;
  final VoidCallback onTap;
  final double sf;
  const _SuggestionChip({
    required this.sprite,
    required this.onTap,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8 * sf, vertical: 4 * sf),
          decoration: BoxDecoration(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFB388FF).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                sprite.assetPath,
                width: 20 * sf,
                height: 20 * sf,
                filterQuality: FilterQuality.none,
                errorBuilder:
                    (_, _, _) => const Icon(Icons.extension, size: 16),
              ),
              SizedBox(width: 5 * sf),
              GoopText(
                sprite.label,
                style: TextStyle(
                  fontSize: 10.5 * sf,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sprite picker sheet ──────────────────────────────────────────

class _SpritePickerSheet extends StatefulWidget {
  const _SpritePickerSheet();

  @override
  State<_SpritePickerSheet> createState() => _SpritePickerSheetState();
}

class _SpritePickerSheetState extends State<_SpritePickerSheet> {
  final _search = TextEditingController();
  String? _kind;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final results = EmoteSpriteCatalog.search(
      _search.text,
      kind: _kind,
      limit: 9999,
    );
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * sf),
            child: TextField(
              controller: _search,
              autofocus: true,
              style: TextStyle(fontSize: 14 * sf),
              decoration: InputDecoration(
                hintText: 'Search icons…',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Colors.white38,
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(height: 8 * sf),
          SizedBox(
            height: 34 * sf,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 14 * sf),
              children: [
                for (final (label, kind) in const [
                  ('All', null),
                  ('Guns', 'gun'),
                  ('Items', 'item'),
                  ('Objects', 'object'),
                  ('Pickups', 'pickup'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: GoopText(
                        label,
                        style: TextStyle(fontSize: 11 * sf),
                      ),
                      selected: _kind == kind,
                      onSelected: (_) => setState(() => _kind = kind),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 6 * sf),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(12 * sf),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: results.length,
              itemBuilder: (_, i) {
                final s = results[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(s),
                  child: Tooltip(
                    message: s.label,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Image.asset(
                        s.assetPath,
                        filterQuality: FilterQuality.none,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, _, _) => const Icon(
                              Icons.extension,
                              color: Colors.white38,
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Surprise sheet ───────────────────────────────────────────────

class SurpriseSheet extends StatelessWidget {
  const SurpriseSheet({super.key});

  static const _presets = <(String, String, IconData)>[
    ('love', 'LOVE', Icons.favorite_rounded),
    ('slap', 'SLAP', Icons.back_hand_rounded),
    ('blank', 'BLANK', Icons.brightness_7_rounded),
    ('mimic', 'MIMIC', Icons.warning_amber_rounded),
    ('heal', 'HEAL', Icons.healing_rounded),
    ('gungeon', 'GUNGEON', Icons.gps_fixed_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final session = context.read<MpSession>();
    return Padding(
      padding: EdgeInsets.all(18 * sf),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoopText(
            'SURPRISE',
            style: TextStyle(
              fontSize: 11 * sf,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.amberAccent.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 14 * sf),
          Wrap(
            spacing: 10 * sf,
            runSpacing: 10 * sf,
            alignment: WrapAlignment.center,
            children: [
              for (final (preset, label, icon) in _presets)
                _SurprisePreset(
                  preset: preset,
                  label: label,
                  icon: icon,
                  sf: sf,
                  onTap: () {
                    Haptics.medium();
                    session.sendSurprise(preset: preset);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          SizedBox(height: 14 * sf),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const GoopText('CUSTOM…'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB388FF),
              side: BorderSide(
                color: const Color(0xFFB388FF).withValues(alpha: 0.5),
              ),
            ),
            onPressed: () => _customSurprise(context, session),
          ),
        ],
      ),
    );
  }

  void _customSurprise(BuildContext context, MpSession session) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder:
          (dctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E122E),
            title: const GoopText('Custom surprise'),
            content: TextField(
              controller: ctrl,
              maxLength: 30,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Up to 30 chars + optional :icon:',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dctx).pop(),
                child: const GoopText('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  final text = ctrl.text.trim();
                  if (text.isNotEmpty) {
                    session.sendSurprise(preset: 'custom', text: text);
                  }
                  Navigator.of(dctx).pop();
                  Navigator.of(context).maybePop();
                },
                child: const GoopText(
                  'SEND',
                  style: TextStyle(color: Colors.amberAccent),
                ),
              ),
            ],
          ),
    );
  }
}

class _SurprisePreset extends StatelessWidget {
  final String preset;
  final String label;
  final IconData icon;
  final double sf;
  final VoidCallback onTap;
  const _SurprisePreset({
    required this.preset,
    required this.label,
    required this.icon,
    required this.sf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * sf, vertical: 12 * sf),
        decoration: BoxDecoration(
          color: Colors.amberAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.amberAccent, size: 26 * sf),
            SizedBox(height: 4 * sf),
            GoopText(
              label,
              style: TextStyle(
                fontSize: 10 * sf,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.amberAccent.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
