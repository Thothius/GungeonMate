part of '../paradox_flow_screen.dart';

class _RoleStage extends StatelessWidget {
  final MpRole role;
  final void Function(MpRole) onPick;
  final VoidCallback onDemo;
  final String? error;
  final double sf;
  const _RoleStage({
    super.key,
    required this.role,
    required this.onPick,
    required this.onDemo,
    this.error,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20 * sf),
      child: Column(
        children: [
          if (error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
              child: GoopText(
                error!,
                style: TextStyle(
                  fontSize: 12 * sf,
                  color: Colors.redAccent.shade100,
                ),
              ),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _BigCard(
                  title: 'MAIN',
                  subtitle: 'The Paradox\nHosts the run',
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF7C4DFF),
                  onTap: () => onPick(MpRole.main),
                  sf: sf,
                ),
              ),
              SizedBox(width: 14 * sf),
              Expanded(
                child: _BigCard(
                  title: 'SIDEKICK',
                  subtitle: 'The Cultist\nJoins the run',
                  icon: Icons.group_rounded,
                  color: const Color(0xFF26C6DA),
                  onTap: () => onPick(MpRole.sidekick),
                  sf: sf,
                ),
              ),
            ],
          ),
          SizedBox(height: 18 * sf),
          // Testing mode demoted to a low-prominence text link — it's a
          // dev tool, not a real play path.
          Center(
            child: TextButton.icon(
              onPressed: onDemo,
              icon: Icon(
                Icons.science_outlined,
                size: 14,
                color: Colors.white.withValues(alpha: 0.35),
              ),
              label: GoopText(
                'Testing mode — solo demo, no second phone',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double sf;
  const _BigCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 30 * sf, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.8),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 24),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 44 * sf, color: color),
              SizedBox(height: 12 * sf),
              GoopText(
                title,
                style: TextStyle(
                  fontSize: FontSizes.titleMedium * sf,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8 * sf),
              GoopText(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12 * sf,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact avatar stage — shows the current pick; tapping opens the
/// paged popup picker (12 per sheet, swipe between sheets).
class _AvatarStage extends StatelessWidget {
  final String selected;
  final void Function(String) onPick;
  final double sf;
  const _AvatarStage({
    super.key,
    required this.selected,
    required this.onPick,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final picked = await showAvatarPicker(context, selected);
          if (picked != null) onPick(picked);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150 * sf,
              height: 150 * sf,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFB388FF).withValues(alpha: 0.7),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: FramedAvatar(id: selected, size: 150 * sf, radius: 17),
            ),
            SizedBox(height: 18 * sf),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 18 * sf,
                vertical: 10 * sf,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFB388FF).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    size: 16 * sf,
                    color: const Color(0xFFB388FF),
                  ),
                  SizedBox(width: 8 * sf),
                  GoopText(
                    'PICK AVATAR',
                    style: TextStyle(
                      fontSize: 13 * sf,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: const Color(0xFFB388FF),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8 * sf),
            GoopText(
              '${kAvatarIds.length} avatars · swipe sheets',
              style: TextStyle(
                fontSize: 11 * sf,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      backgroundColor: const Color(0xFF12081F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: const Color(0xFF7C4DFF).withValues(alpha: 0.4)),
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
                    color: const Color(0xFFB388FF),
                  ),
                  SizedBox(width: 4 * sf),
                  GoopText(
                    'BACK',
                    style: TextStyle(
                      fontSize: 12 * sf,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: const Color(0xFFB388FF),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GoopText(
              'PICK A FRAME',
              style: TextStyle(
                fontSize: 13 * sf,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: const Color(0xFFB388FF),
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
            color: Colors.white.withValues(alpha: 0.6),
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
                                color: Colors.white,
                                width: 2.5,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFB388FF),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.check,
                                  size: 12 * sf,
                                  color: Colors.black,
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
                                ? const Color(0xFFB388FF)
                                : Colors.white.withValues(alpha: 0.45),
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
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFB388FF).withValues(alpha: 0.6),
          ),
        ),
        child: Center(
          child: GoopText(
            'CONFIRM',
            style: TextStyle(
              fontSize: 14 * sf,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: const Color(0xFFB388FF),
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
                color: const Color(0xFFB388FF),
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
                            color: Colors.white.withValues(alpha: 0.05),
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
                                    ? const Color(0xFFB388FF)
                                    : Colors.white.withValues(alpha: 0.15),
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
                                  (_, _, _) => const Icon(
                                    Icons.person,
                                    size: 36,
                                    color: Colors.white38,
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
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
        SizedBox(height: 10 * sf),
        _confirmButton(sf),
      ],
    );
  }
}
