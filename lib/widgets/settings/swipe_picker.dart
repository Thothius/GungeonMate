import 'package:flutter/material.dart';
import '../../services/haptics.dart';

class SwipePicker<T> extends StatefulWidget {
  final List<T> items;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;
  final Widget Function(T item, bool isSelected) itemBuilder;

  const SwipePicker({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.height,
    required this.itemBuilder,
  });

  @override
  State<SwipePicker<T>> createState() => _SwipePickerState<T>();
}

class _SwipePickerState<T> extends State<SwipePicker<T>> {
  late final PageController _pc;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.items.indexOf(widget.value);
    if (_index < 0) _index = 0;
    _pc = PageController(initialPage: _index, viewportFraction: 0.38);
  }

  @override
  void didUpdateWidget(SwipePicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIdx = widget.items.indexOf(widget.value);
    if (newIdx >= 0 && newIdx != _index) {
      _index = newIdx;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pc.hasClients) _pc.animateToPage(newIdx, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      });
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pc,
        itemCount: widget.items.length,
        onPageChanged: (i) {
          setState(() => _index = i);
          widget.onChanged(widget.items[i]);
          Haptics.selection();
        },
        itemBuilder: (context, i) {
          final item = widget.items[i];
          final isSelected = item == widget.value;
          final isFocused = i == _index;
          return AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isFocused ? 1.0 : 0.92,
            curve: Curves.easeOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: widget.itemBuilder(item, isSelected || isFocused),
            ),
          );
        },
      ),
    );
  }
}
