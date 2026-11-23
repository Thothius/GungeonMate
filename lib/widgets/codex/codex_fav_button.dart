import 'package:flutter/material.dart';

import '../../services/codex_prefs.dart';
import '../../services/haptics.dart';

/// Codex favorite toggle — bookmark icon (distinct from the loadout
/// heart favourite on item/gun headers). Persists via [CodexPrefs] and
/// feeds the Ammonomicon overview FAVORITES shelf.
///
/// [section] must match `AmmonomiconSection.name` ('guns', 'items',
/// 'synergies', 'enemies', ...) so overview resolution finds the entry.
class CodexFavButton extends StatelessWidget {
  final String section;
  final String name;

  const CodexFavButton({
    super.key,
    required this.section,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: CodexPrefs.favorites,
      builder: (_, favs, _) {
        final key = CodexPrefs.keyFor(section, name);
        final on = favs.contains(key);
        return IconButton(
          tooltip: on ? 'Remove from codex favorites' : 'Save to codex',
          icon: Icon(
            on ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: 22,
            color:
                on
                    ? const Color(0xFFFF6E8A)
                    : Theme.of(context).colorScheme.outline,
          ),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () {
            Haptics.selection();
            CodexPrefs.toggleFavorite(key);
          },
        );
      },
    );
  }
}
