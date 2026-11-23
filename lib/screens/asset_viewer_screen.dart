import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_theme.dart';
import '../services/asset_votes.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../utils/responsive.dart';
import '../widgets/scale_button.dart';

/// Asset Viewer — the feedback workbench. Browses every bundled font,
/// background, and avatar with stable ID numbers; long-press an asset
/// to cast a YAY/NAY vote. EXPORT writes a JSON manifest (all assets +
/// verdicts, `nay` = removal candidates) and hands it to the share
/// sheet so it can be saved to the phone.
class AssetViewerScreen extends StatefulWidget {
  const AssetViewerScreen({super.key});

  @override
  State<AssetViewerScreen> createState() => _AssetViewerScreenState();
}

class _AssetViewerScreenState extends State<AssetViewerScreen> {
  final _votes = AssetVotes();
  String _category = 'font';
  bool _exporting = false;

  static const _cats = [
    ('font', 'FONTS', Icons.text_fields_rounded),
    ('bg', 'BACKGROUNDS', Icons.wallpaper_rounded),
    ('avatar', 'AVATARS', Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _votes.load();
  }

  List<AssetEntry> get _entries =>
      AssetVotes.catalog().where((e) => e.category == _category).toList();

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final json = const JsonEncoder.withIndent('  ').convert(
        _votes.toExportJson(),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/gungeonmate_asset_votes.json');
      await file.writeAsString(json);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'GungeonMate asset votes',
          text:
              'Asset feedback export — yay/nay/unrated per asset. '
              'NAY entries are removal candidates.',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: GoopText('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _voteDialog(AssetEntry e) async {
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E22),
            title: GoopText(
              e.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            content: GoopText(
              '${e.detail}\nID: ${e.id}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'clear'),
                child: const GoopText('CLEAR'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'nay'),
                child: const GoopText(
                  'NAY',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'yay'),
                child: const GoopText('YAY'),
              ),
            ],
          ),
    );
    if (result == null) return;
    Haptics.selection();
    await _votes.setVote(e.id, result == 'clear' ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final entries = _entries;
    // Per-category display numbering (F-01, B-07, A-12 …).
    final prefix = switch (_category) {
      'font' => 'F',
      'bg' => 'B',
      'avatar' => 'A',
      _ => '#',
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Menubar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: GoopText(
                      'ASSET VIEWER',
                      style: TextStyle(
                        fontSize: 17 * sf,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                        color: AppTheme.flair.primary,
                      ),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _votes,
                    builder: (_, _) {
                      if (_votes.yayCount + _votes.nayCount == 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GoopText(
                          '${_votes.yayCount}▲ ${_votes.nayCount}▼',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      );
                    },
                  ),
                  ScaleButton(
                    onTap: _exporting ? null : _export,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.flair.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.flair.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: GoopText(
                        _exporting ? 'EXPORTING…' : 'EXPORT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppTheme.flair.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Category chips ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  for (final (key, label, icon) in _cats) ...[
                    _CatChip(
                      label: label,
                      icon: icon,
                      selected: _category == key,
                      count: AssetVotes.catalog()
                          .where((e) => e.category == key)
                          .length,
                      onTap: () {
                        Haptics.selection();
                        setState(() => _category = key);
                      },
                    ),
                    if (key != 'avatar') const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            // ── Grid ──
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width < 560 ? 3 : 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  final num = '$prefix-${(i + 1).toString().padLeft(2, '0')}';
                  return _AssetTile(
                    entry: e,
                    num: num,
                    vote: _votes.voteFor(e.id),
                    onLongPress: () => _voteDialog(e),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final int count;
  final VoidCallback onTap;
  const _CatChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.flair.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.8) : Colors.white24,
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? accent : Colors.white60),
            const SizedBox(width: 5),
            GoopText(
              '$label ($count)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: selected ? accent : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  final AssetEntry entry;
  final String num;
  final String? vote;
  final VoidCallback onLongPress;
  const _AssetTile({
    required this.entry,
    required this.num,
    required this.vote,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final voted = vote != null;
    final borderColor = switch (vote) {
      'yay' => Colors.greenAccent,
      'nay' => Colors.redAccent,
      _ => Colors.white24,
    };
    return GestureDetector(
      onLongPress: () {
        Haptics.medium();
        onLongPress();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: voted ? borderColor.withValues(alpha: 0.8) : borderColor,
            width: voted ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: _preview(context),
              ),
            ),
            // Label strip
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GoopText(
                        num,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppTheme.flair.primary.withValues(alpha: 0.9),
                        ),
                      ),
                      const Spacer(),
                      if (voted)
                        GoopText(
                          vote == 'yay' ? 'YAY' : 'NAY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: borderColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  GoopText(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    if (entry.fontFamily != null) {
      // Font specimen — the whole point of the picker.
      return Container(
        color: const Color(0xFF16141A),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: GoopText(
            'Ag',
            style: TextStyle(
              fontFamily: entry.fontFamily,
              fontSize: 44,
              height: 1.0,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    return Image.asset(
      entry.imagePath!,
      fit: BoxFit.cover,
      errorBuilder:
          (_, _, _) => Container(
            color: const Color(0xFF16141A),
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              color: Colors.white24,
            ),
          ),
    );
  }
}
