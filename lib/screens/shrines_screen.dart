import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/shrine.dart';

class ShrinesScreen extends StatelessWidget {
  const ShrinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final runProvider = context.watch<RunProvider>();
    final shrines = runProvider.allShrines;
    final hasActiveRun = runProvider.runState.selectedCharacter != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Shrines')),
      body: shrines.isEmpty
          ? const Center(
              child: Text(
                'No shrine data',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: shrines.length,
              itemBuilder: (c, i) {
                final s = shrines[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: s.icon.startsWith('assets/')
                          ? Image.asset(
                              s.icon,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.temple_buddhist_outlined),
                            )
                          : s.icon.startsWith('http')
                              ? Image.network(
                                  s.icon,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.temple_buddhist_outlined),
                                )
                              : const Icon(Icons.temple_buddhist_outlined),
                    ),
                    title: Text(
                      s.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Wrap(
                      spacing: 6,
                      children: [
                        if (s.curse != 0)
                          _MiniTag(
                            text: 'curse ${s.curse > 0 ? '+' : ''}${s.curse}',
                            color: Colors.deepOrange,
                          ),
                        if (s.coolness != 0)
                          _MiniTag(
                            text:
                                'cool ${s.coolness > 0 ? '+' : ''}${s.coolness}',
                            color: Colors.lightBlue,
                          ),
                      ],
                    ),
                    children: [
                      if (s.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            s.description,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      Text(
                        s.effect,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                      if (s.message.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          '"${s.message}"',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                      if (hasActiveRun && (s.curse != 0 || s.coolness != 0)) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.check, size: 16),
                            label: Text(_applyLabel(s)),
                            onPressed: () {
                              final r = runProvider.applyShrine(s);
                              final parts = <String>[
                                if (r.applied.isNotEmpty)
                                  r.applied.join(' · '),
                                if (r.manual.isNotEmpty) r.manual.first,
                              ];
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(parts.isEmpty
                                      ? 'Applied ${s.name}'
                                      : '${s.name}: ${parts.join(' · ')}'),
                                  duration:
                                      const Duration(milliseconds: 1800),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _applyLabel(Shrine s) {
    final parts = <String>[];
    if (s.curse != 0) parts.add('curse ${s.curse > 0 ? '+' : ''}${s.curse}');
    if (s.coolness != 0) parts.add('cool ${s.coolness > 0 ? '+' : ''}${s.coolness}');
    return 'Apply (${parts.join(', ')})';
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniTag({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}
