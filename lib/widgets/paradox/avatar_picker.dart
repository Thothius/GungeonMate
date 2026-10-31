import 'package:flutter/material.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';
import '../../utils/asset_paths.dart';
import '../../utils/responsive.dart';
import '../scale_button.dart';
import 'avatar_frame.dart';
import '../skeuo/skeuo_tokens.dart';

Future<String?> showAvatarPicker(BuildContext context, String selected) {
  return showDialog<String>(
    context: context,
    builder: (_) => _AvatarPickerDialog(selected: selected),
  );
}

class _AvatarPickerDialog extends StatefulWidget {
  final String selected;
  const _AvatarPickerDialog({required this.selected});

  @override
  State<_AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<_AvatarPickerDialog> {
  static const int _perPage = 9; // 3 cols × 3 rows per sheet
  late final PageController _pageCtrl;
  int _page = 0;
  late String _picked = widget.selected;
  bool _frameStage = false; // step 2: dedicated frame preview

  int get _pageCount => (kAvatarIds.length + _perPage - 1) ~/ _perPage;

  @override
  void initState() {
    super.initState();
    // Open on the sheet containing the current pick (base id).
    final idx = kAvatarIds.indexOf(avatarBaseId(widget.selected));
    _page = idx < 0 ? 0 : idx ~/ _perPage;
    _pageCtrl = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  /// Replace the frame suffix, keeping the base portrait.
  void _pickFrame(String frameId) {
    Haptics.selection();
    final base = avatarBaseId(_picked);
    setState(() => _picked = frameId.isEmpty ? base : '$base:$frameId');
  }

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    return Dialog(
      backgroundColor: Skeuo.collapse(Color(0xFF12081F)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Skeuo.collapse(Color(0xFF7C4DFF)).withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * sf),
        child: _frameStage ? _buildFrameStage(sf) : _buildGridStage(sf),
      ),
    );
  }

  /// Step 2 — dedicated frame preview: the picked portrait large, every
  /// frame style rendered live around it (specials animate for real).
  Widget _buildFrameStage(double sf) {
    final frame = avatarFrameId(_picked);
    final styles = [...kAvatarFrames, ...kSpecialFrames];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _frameStage = false),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16 * sf,
                    color: Skeuo.collapse(Color(0xFFB388FF)),
                  ),
                  SizedBox(width: 4 * sf),
                  GoopText(
                    'BACK',
                    style: TextStyle(
                      fontSize: 12 * sf,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Skeuo.collapse(Color(0xFFB388FF)),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            GoopText(
              'PICK A FRAME',
              style: TextStyle(
                fontSize: 13 * sf,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: Skeuo.collapse(Color(0xFFB388FF)),
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * sf),
        FramedAvatar(id: _picked, size: 130 * sf, radius: 16),
        SizedBox(height: 6 * sf),
        GoopText(
          (avatarFrameStyleOf(frame)?.label ?? 'NONE').toUpperCase(),
          style: TextStyle(
            fontSize: 12 * sf,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Skeuo.collapse(Colors.white).withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: 14 * sf),
        // Every style previewed live on the actual portrait — specials
        // animate because FramedAvatar renders the real painter.
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final f in styles)
              GestureDetector(
                onTap: () => _pickFrame(f.id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        FramedAvatar(
                          id:
                              f.id.isEmpty
                                  ? avatarBaseId(_picked)
                                  : '${avatarBaseId(_picked)}:${f.id}',
                          size: 52 * sf,
                          radius: 10,
                        ),
                        if (frame == f.id)
                          Container(
                            width: 52 * sf,
                            height: 52 * sf,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Skeuo.collapse(Colors.white),
                                width: 2.5,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Skeuo.collapse(Color(0xFFB388FF)),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.check,
                                  size: 12 * sf,
                                  color: Skeuo.collapse(Colors.black),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 3 * sf),
                    GoopText(
                      f.label,
                      style: TextStyle(
                        fontSize: 8.5 * sf,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color:
                            frame == f.id
                                ? Skeuo.collapse(Color(0xFFB388FF))
                                : Skeuo.collapse(
                                  Colors.white,
                                ).withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: 16 * sf),
        _confirmButton(sf),
      ],
    );
  }

  Widget _confirmButton(double sf) {
    return ScaleButton(
      onTap: () => Navigator.pop(context, _picked),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12 * sf),
        decoration: BoxDecoration(
          color: Skeuo.collapse(Color(0xFF7C4DFF)).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Skeuo.collapse(Color(0xFFB388FF)).withValues(alpha: 0.6),
          ),
        ),
        child: Center(
          child: GoopText(
            'CONFIRM',
            style: TextStyle(
              fontSize: 14 * sf,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: Skeuo.collapse(Color(0xFFB388FF)),
            ),
          ),
        ),
      ),
    );
  }

  /// Step 1 — the paged portrait grid (12 per sheet).
  Widget _buildGridStage(double sf) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GoopText(
              'PAGE ${_page + 1}/$_pageCount',
              style: TextStyle(
                fontSize: 13 * sf,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: Skeuo.collapse(Color(0xFFB388FF)),
              ),
            ),
            // Live preview of the composite pick.
            FramedAvatar(id: _picked, size: 40 * sf, radius: 9),
          ],
        ),
        SizedBox(height: 12 * sf),
        SizedBox(
          height: 330 * sf,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _pageCount,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder:
                (_, page) => GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: List.generate(_perPage, (i) {
                    final idx = page * _perPage + i;
                    // Empty slot on the last partial sheet.
                    if (idx >= kAvatarIds.length) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Skeuo.collapse(
                              Colors.white,
                            ).withValues(alpha: 0.05),
                          ),
                        ),
                      );
                    }
                    final id = kAvatarIds[idx];
                    final isSel = id == avatarBaseId(_picked);
                    return GestureDetector(
                      onTap: () {
                        Haptics.selection();
                        final frame = avatarFrameId(_picked);
                        setState(() {
                          _picked = frame.isEmpty ? id : '$id:$frame';
                          _frameStage = true; // → dedicated frame stage
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSel
                                    ? Skeuo.collapse(Color(0xFFB388FF))
                                    : Skeuo.collapse(
                                      Colors.white,
                                    ).withValues(alpha: 0.15),
                            width: isSel ? 2.5 : 1.2,
                          ),
                          boxShadow:
                              isSel
                                  ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF7C4DFF,
                                      ).withValues(alpha: 0.35),
                                      blurRadius: 14,
                                    ),
                                  ]
                                  : null,
                        ),
                        child: ClipRect(
                          // Overscale bleeds off the 1-2px white
                          // gridline edges on sliced grid portraits.
                          child: Transform.scale(
                            scale: 1.20,
                            alignment: Alignment.center,
                            child: Image.asset(
                              avatarPath(id),
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.none,
                              errorBuilder:
                                  (_, _, _) => Icon(
                                    Icons.person,
                                    size: 36,
                                    color: Skeuo.collapse(Colors.white38),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
          ),
        ),
        SizedBox(height: 8 * sf),
        GoopText(
          'swipe sheets · tap a portrait for frames',
          style: TextStyle(
            fontSize: 11 * sf,
            color: Skeuo.collapse(Colors.white).withValues(alpha: 0.35),
          ),
        ),
        SizedBox(height: 10 * sf),
        _confirmButton(sf),
      ],
    );
  }
}
