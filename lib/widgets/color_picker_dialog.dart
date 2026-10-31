import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';
import '../services/haptics.dart';

/// A compact HSV color picker dialog for custom theme palette editing.
///
/// Shows a 2D saturation-value panel + a vertical hue slider, a hex input,
/// and a live preview swatch. Returns the selected [Color] or null if
/// cancelled.
Future<Color?> showColorPickerDialog(
  BuildContext context, {
  required Color initialColor,
  String title = 'Pick Color',
}) {
  return showDialog<Color?>(
    context: context,
    builder:
        (_) => _ColorPickerDialog(initialColor: initialColor, title: title),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final String title;

  const _ColorPickerDialog({required this.initialColor, required this.title});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv;
  late TextEditingController _hexCtrl;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
    _hexCtrl = TextEditingController(text: _toHex(widget.initialColor));
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  String _toHex(Color c) {
    final a = c.toARGB32();
    return '#${(a & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Color get _currentColor => _hsv.toColor();

  void _updateFromHex(String value) {
    var hex = value.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        setState(() {
          _hsv = HSVColor.fromColor(Color(0xFF000000 | parsed));
        });
      }
    }
  }

  void _handleSV(Offset localPos, Size size) {
    Haptics.selection();
    setState(() {
      final dx = (localPos.dx / size.width).clamp(0.0, 1.0);
      final dy = (localPos.dy / size.height).clamp(0.0, 1.0);
      _hsv = _hsv.withSaturation(dx).withValue(1.0 - dy);
      _hexCtrl.text = _toHex(_currentColor);
    });
  }

  void _handleHue(Offset localPos, Size size) {
    Haptics.selection();
    setState(() {
      final hue = (localPos.dy / size.height).clamp(0.0, 1.0) * 360;
      _hsv = _hsv.withHue(hue);
      _hexCtrl.text = _toHex(_currentColor);
    });
  }

  @override
  Widget build(BuildContext context) {
    final flair = Theme.of(context).colorScheme;
    final color = _currentColor;

    return AlertDialog(
      backgroundColor: flair.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radii.lg)),
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: FontSizes.titleSmall,
          fontWeight: FontWeight.w900,
          color: flair.primary,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── SV panel + hue slider ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2D Saturation-Value panel
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = Size(
                              constraints.maxWidth,
                              constraints.maxWidth,
                            );
                            return GestureDetector(
                              onPanDown:
                                  (d) => _handleSV(d.localPosition, size),
                              onPanUpdate:
                                  (d) => _handleSV(d.localPosition, size),
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: _SVPainter(_hsv),
                                  size: size,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radii.sm),
                                      border: Border.all(
                                        color: flair.onSurface.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Vertical hue slider — fixed height matching the SV panel
                  SizedBox(
                    width: 28,
                    height: 240,
                    child: GestureDetector(
                      onPanDown:
                          (d) =>
                              _handleHue(d.localPosition, const Size(28, 240)),
                      onPanUpdate:
                          (d) =>
                              _handleHue(d.localPosition, const Size(28, 240)),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _HuePainter(_hsv.hue),
                          size: const Size(28, 240),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radii.sm),
                              border: Border.all(
                                color: flair.onSurface.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Preview swatch + hex input ──
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.all(Radii.sm),
                      border: Border.all(
                        color: flair.onSurface.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HEX',
                          style: TextStyle(
                            fontSize: FontSizes.labelSmall,
                            fontWeight: FontWeight.w700,
                            color: flair.onSurface.withValues(alpha: 0.5),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _hexCtrl,
                          style: TextStyle(
                            color: flair.onSurface,
                            fontSize: FontSizes.bodyMedium,
                            fontFamily: 'monospace',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9a-fA-F#]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: flair.onSurface.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radii.sm),
                              borderSide: BorderSide(
                                color: flair.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radii.sm),
                              borderSide: BorderSide(
                                color: flair.primary.withValues(alpha: 0.7),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          onChanged: _updateFromHex,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'CANCEL',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w700,
              color: flair.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: flair.primary,
            foregroundColor:
                flair.primary.computeLuminance() > 0.5
                    ? Colors.black87
                    : Colors.white,
          ),
          onPressed: () {
            Haptics.selection();
            Navigator.of(context).pop(_currentColor);
          },
          child: const Text(
            'DONE',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints the 2D saturation-value panel: horizontal = saturation,
/// vertical = value (top = full value, bottom = black).
class _SVPainter extends CustomPainter {
  final HSVColor hsv;

  _SVPainter(this.hsv);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base hue color at full sat/value
    final hueColor = HSVColor.fromAHSV(1.0, hsv.hue, 1.0, 1.0).toColor();

    // Horizontal gradient: white → hue color
    final satPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.white, hueColor],
          ).createShader(rect);
    canvas.drawRect(rect, satPaint);

    // Vertical gradient: transparent → black
    final valPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black],
          ).createShader(rect);
    canvas.drawRect(rect, valPaint);

    // Cursor
    final cx = hsv.saturation * size.width;
    final cy = (1.0 - hsv.value) * size.height;
    final cursorPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), 10, cursorPaint);
    final innerPaint =
        Paint()
          ..color = hsv.toColor()
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 8, innerPaint);
  }

  @override
  bool shouldRepaint(_SVPainter old) => old.hsv != hsv;
}

/// Paints a vertical rainbow hue strip with a cursor at the current hue.
class _HuePainter extends CustomPainter {
  final double hue;

  _HuePainter(this.hue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const HSVColor.fromAHSV(1.0, 0, 1.0, 1.0).toColor(),
              const HSVColor.fromAHSV(1.0, 60, 1.0, 1.0).toColor(),
              const HSVColor.fromAHSV(1.0, 120, 1.0, 1.0).toColor(),
              const HSVColor.fromAHSV(1.0, 180, 1.0, 1.0).toColor(),
              const HSVColor.fromAHSV(1.0, 240, 1.0, 1.0).toColor(),
              const HSVColor.fromAHSV(1.0, 300, 1.0, 1.0).toColor(),
              const HSVColor.fromAHSV(1.0, 360, 1.0, 1.0).toColor(),
            ],
          ).createShader(rect);
    canvas.drawRect(rect, paint);

    // Cursor
    final cy = (hue / 360.0) * size.height;
    final cursorPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, cy),
          width: size.width,
          height: 6,
        ),
        const Radius.circular(3),
      ),
      cursorPaint,
    );
  }

  @override
  bool shouldRepaint(_HuePainter old) => old.hue != hue;
}
