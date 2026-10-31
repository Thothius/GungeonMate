import 'package:flutter/material.dart';
import '../skeuo/skeuo_tokens.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Skeuo.collapse(Color(0xFFE8E4D9)).withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      ),
    );
  }
}
