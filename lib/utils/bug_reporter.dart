import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/run_provider.dart';
import '../services/haptics.dart';

enum BugCategory {
  uiUx,
  multiplayer,
  gunItem,
  other,
}

extension BugCategoryExtension on BugCategory {
  String get label {
    switch (this) {
      case BugCategory.uiUx:
        return 'UI/UX';
      case BugCategory.multiplayer:
        return 'Multiplayer';
      case BugCategory.gunItem:
        return 'Gun/Item';
      case BugCategory.other:
        return 'Other';
    }
  }
}

class BugReporter {
  static void show(BuildContext context, String sourceContext) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // Non-dismissable
      builder: (BuildContext dialogContext) {
        return _BugReportDialogContent(
          sourceContext: sourceContext,
          parentContext: context,
        );
      },
    );
  }
}

class _BugReportDialogContent extends StatefulWidget {
  final String sourceContext;
  final BuildContext parentContext;

  const _BugReportDialogContent({
    required this.sourceContext,
    required this.parentContext,
  });

  @override
  State<_BugReportDialogContent> createState() => _BugReportDialogContentState();
}

class _BugReportDialogContentState extends State<_BugReportDialogContent> {
  late BugCategory _selectedCategory;
  late TextEditingController _feedbackController;
  late TextEditingController _searchController;
  String? _selectedEntity;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
    _searchController = TextEditingController();

    // Smart contextual pre-selection!
    final ctxLower = widget.sourceContext.toLowerCase();
    if (ctxLower.contains('detail view for:')) {
      _selectedCategory = BugCategory.gunItem;
      // Extract specific gun/item name
      final prefix = 'detail view for:';
      final startIdx = ctxLower.indexOf(prefix);
      if (startIdx != -1) {
        final extracted = widget.sourceContext.substring(startIdx + prefix.length).trim();
        _selectedEntity = extracted;
        _searchController.text = extracted;
      }
    } else if (ctxLower.contains('multiplayer') || ctxLower.contains('mp')) {
      _selectedCategory = BugCategory.multiplayer;
    } else if (ctxLower.contains('dashboard') || ctxLower.contains('inventory')) {
      _selectedCategory = BugCategory.uiUx;
    } else {
      _selectedCategory = BugCategory.other;
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateSuggestions(String query, List<String> allEntities) {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final matched = allEntities
        .where((e) => e.toLowerCase().contains(lowerQuery))
        .take(5) // Limit to top 5 suggestions
        .toList();

    setState(() {
      _suggestions = matched;
      _showSuggestions = matched.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access master database of guns/items from RunProvider
    final provider = widget.parentContext.read<RunProvider>();
    final allEntities = [
      ...provider.allGuns.map((g) => g.name),
      ...provider.allItems.map((i) => i.name),
    ]..sort();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      title: const Row(
        children: [
          Icon(Icons.bug_report_rounded, color: Colors.redAccent, size: 24),
          SizedBox(width: 10),
          Text(
            'REPORT A BUG',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Dropdown Label
            const Text(
              'BUG CATEGORY',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: Colors.redAccent,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            // Category Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BugCategory>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF1E1E22),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                  isExpanded: true,
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                  onChanged: (BugCategory? value) {
                    if (value != null) {
                      Haptics.selection();
                      setState(() {
                        _selectedCategory = value;
                        if (value != BugCategory.gunItem) {
                          _selectedEntity = null;
                          _searchController.clear();
                          _showSuggestions = false;
                        }
                      });
                    }
                  },
                  items: BugCategory.values.map((BugCategory category) {
                    return DropdownMenuItem<BugCategory>(
                      value: category,
                      child: Text(category.label),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Condition input: if Gun/Item category is selected, show target search autocomplete!
            if (_selectedCategory == BugCategory.gunItem) ...[
              const Text(
                'TARGET GUN OR ITEM',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.redAccent,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search any gun or item (e.g. Casey)...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.white30),
                  filled: true,
                  fillColor: Colors.black26,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: Colors.white38),
                          onPressed: () {
                            Haptics.selection();
                            setState(() {
                              _searchController.clear();
                              _selectedEntity = null;
                              _suggestions = [];
                              _showSuggestions = false;
                            });
                          },
                        )
                      : null,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white12, width: 1.0),
                  ),
                ),
                onChanged: (val) {
                  _updateSuggestions(val, allEntities);
                },
              ),
              if (_showSuggestions) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      return InkWell(
                        onTap: () {
                          Haptics.selection();
                          setState(() {
                            _selectedEntity = item;
                            _searchController.text = item;
                            _showSuggestions = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.widgets_rounded, size: 14, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],

            // Custom Feedback Input
            const Text(
              'BUG DESCRIPTION / DETAILS',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: Colors.redAccent,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe what went wrong or how to reproduce it...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.white30),
                filled: true,
                fillColor: Colors.black26,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white12, width: 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () {
            Haptics.heavy();
            Navigator.of(context).pop();
          },
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Haptics.heavy();
            final String bugText = _feedbackController.text.trim();
            if (bugText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter some text before submitting!'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            // Enforce picking an item if they have selected Gun/Item category but haven't selected any item!
            if (_selectedCategory == BugCategory.gunItem && _selectedEntity == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please search and select a specific Gun/Item from the list!'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            // Construct beautifully structured, parseable email message body!
            final String emailBody = '[GUNGEONMATE BUG REPORT]\n'
                '==================================================\n'
                'CATEGORY: ${_selectedCategory.label.toUpperCase()}\n'
                'TARGET ENTITY: ${_selectedEntity ?? 'N/A'}\n'
                'LAUNCH SOURCE: ${widget.sourceContext}\n'
                '==================================================\n\n'
                'USER DETAILED DESCRIPTION:\n'
                '$bugText\n\n'
                '==================================================\n'
                'DIAGNOSTIC METADATA:\n'
                '• App Version: v0.9.1\n'
                '• Client Environment: Android Sideloaded Release Build\n'
                '==================================================';

            final Uri emailUri = Uri(
              scheme: 'mailto',
              path: 'gungeonmate@gmail.com',
              queryParameters: {
                'subject': 'GungeonMate Bug [${_selectedCategory.label.toUpperCase()}]${_selectedEntity != null ? ' - $_selectedEntity' : ''}',
                'body': emailBody,
              },
            );

            try {
              await launchUrl(emailUri, mode: LaunchMode.externalApplication);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open email client: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'SUBMIT',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }
}
