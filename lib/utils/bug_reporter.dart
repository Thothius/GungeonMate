import 'dart:convert';
import 'dart:io';
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
  bool _isSending = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
    _searchController = TextEditingController();

    // Smart contextual pre-selection!
    final ctxLower = widget.sourceContext.toLowerCase();
    if (ctxLower.contains('detail view for:')) {
      _selectedCategory = BugCategory.gunItem;
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
        .take(5)
        .toList();

    setState(() {
      _suggestions = matched;
      _showSuggestions = matched.isNotEmpty;
    });
  }

  // Back-end HTTP POST transmission to Formspree
  Future<bool> _sendAnonymousReport(String category, String entity, String feedback) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    try {
      final request = await client.postUrl(Uri.parse('https://formspree.io/f/xykaqkov'));
      request.headers.set('content-type', 'application/json');
      request.headers.set('accept', 'application/json');

      final payload = {
        'category': category,
        'target_entity': entity,
        'launch_source': widget.sourceContext,
        'feedback': feedback,
        'app_version': 'v0.9.1',
        'environment': 'Android Sideloaded Release Build',
        '_subject': 'GungeonMate Bug [$category]${entity != 'N/A' ? ' - $entity' : ''}',
        'message': 'GungeonMate Anonymous Bug Report\n'
            '--------------------------------------------------\n'
            'Category: $category\n'
            'Target Entity: $entity\n'
            'Source Location: ${widget.sourceContext}\n'
            'Feedback details:\n$feedback\n'
            '--------------------------------------------------\n'
            'Metadata: App v0.9.1, P2P Sideloaded Build',
      };

      request.write(json.encode(payload));
      final response = await request.close();
      client.close();
      return response.statusCode == 200;
    } catch (_) {
      client.close();
      return false; // Returns false if offline or connection timeout/exception!
    }
  }

  // Opens traditional local mail client as offline backup outbox mode
  Future<void> _launchEmailBackup(String category, String entity, String feedback) async {
    final String emailBody = '[OFFLINE GUNGEONMATE BUG REPORT]\n'
        '==================================================\n'
        'CATEGORY: $category\n'
        'TARGET ENTITY: $entity\n'
        'LAUNCH SOURCE: ${widget.sourceContext}\n'
        '==================================================\n\n'
        'USER DETAILED DESCRIPTION:\n'
        '$feedback\n\n'
        '==================================================\n'
        'DIAGNOSTIC METADATA:\n'
        '• App Version: v0.9.1\n'
        '• Client Environment: Android Sideloaded Release Build\n'
        '==================================================';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'gungeonmate@gmail.com',
      queryParameters: {
        'subject': 'GungeonMate Bug [$category]${entity != 'N/A' ? ' - $entity' : ''} (Offline Backup)',
        'body': emailBody,
      },
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch email app: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.parentContext.read<RunProvider>();
    final allEntities = [
      ...provider.allGuns.map((g) => g.name),
      ...provider.allItems.map((i) => i.name),
    ]..sort();

    // Success Screen Render
    if (_isSuccess) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00E676), width: 2), // Success Green Border
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 64),
              const SizedBox(height: 16),
              const Text(
                'SUBMISSION SUCCESS!',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your report was sent completely anonymously to Bello\'s desk. Thank you for making GungeonMate better!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Haptics.heavy();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'CLOSE PANEL',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default Submission Form Render
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
          // Category Label
          const Text(
            'BUG CATEGORY',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 1.0),
          ),
          const SizedBox(height: 6),
          // Category Selector
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
                disabledHint: const Text('Loading...'),
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                onChanged: _isSending
                    ? null
                    : (BugCategory? value) {
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

          // Autocomplete search selector for guns/items
          if (_selectedCategory == BugCategory.gunItem) ...[
            const Text(
              'TARGET GUN OR ITEM',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 1.0),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _searchController,
              enabled: !_isSending,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search any gun or item (e.g. Casey)...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.white30),
                filled: true,
                fillColor: Colors.black26,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: _searchController.text.isNotEmpty && !_isSending
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

          // Feedback Description Label
          const Text(
            'BUG DESCRIPTION / DETAILS',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 1.0),
          ),
          const SizedBox(height: 4),
          const Text(
            'ℹ️ Sends completely anonymously! No email client opens, and your personal address is never exposed.',
            style: TextStyle(fontSize: 10, color: Colors.white38, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _feedbackController,
            maxLines: 5,
            enabled: !_isSending,
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
        onPressed: _isSending
            ? null
            : () {
                Haptics.heavy();
                Navigator.of(context).pop();
              },
        child: const Text(
          'CANCEL',
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.5),
        ),
      ),
      ElevatedButton(
        onPressed: _isSending
            ? null
            : () async {
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

                setState(() {
                  _isSending = true;
                });

                final String categoryLabel = _selectedCategory.label;
                final String entityName = _selectedEntity ?? 'N/A';

                // Try anonymous Web background sending!
                final bool success = await _sendAnonymousReport(
                  categoryLabel,
                  entityName,
                  bugText,
                );

                if (!mounted) return;

                setState(() {
                  _isSending = false;
                });

                if (success) {
                  Haptics.success();
                  setState(() {
                    _isSuccess = true;
                  });
                } else {
                  // Connection Failure / Offline Trigger!
                  Haptics.warning();
                  // Prompts user with elegant offline-fallback dialog
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext backupContext) {
                      return AlertDialog(
                        backgroundColor: const Color(0xFF1E1E22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.amberAccent, width: 2), // Warn Accent Border
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, color: Colors.amberAccent, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'OFFLINE DETECTED',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white, letterSpacing: 1.0),
                            ),
                          ],
                        ),
                        content: const Text(
                          'We couldn\'t send your report anonymously because you appear to be offline.\n\n'
                          'Would you like to compose an email instead? Your email app will queue it in your Outbox and send it automatically as soon as you reconnect to Wi-Fi!',
                          style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Haptics.heavy();
                              Navigator.of(backupContext).pop();
                            },
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(color: Colors.white30, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              Haptics.heavy();
                              Navigator.of(backupContext).pop(); // Close warnings
                              Navigator.of(context).pop(); // Close main panel
                              await _launchEmailBackup(categoryLabel, entityName, bugText);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.mail_rounded, size: 14),
                            label: const Text(
                              'SEND VIA EMAIL',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'SUBMIT',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.5),
                ),
        ),
      ],
    );
  }
}
