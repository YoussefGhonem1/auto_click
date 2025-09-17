import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BulkAddTikTokLinksDialog extends StatefulWidget {
  final Function(String text) onAdd;

  const BulkAddTikTokLinksDialog({super.key, required this.onAdd});

  @override
  State<BulkAddTikTokLinksDialog> createState() =>
      _BulkAddTikTokLinksDialogState();
}

class _BulkAddTikTokLinksDialogState extends State<BulkAddTikTokLinksDialog> {
  final _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    await widget.onAdd(_textController.text);

    setState(() {
      _isLoading = false;
    });
  }

  int _countValidLines() {
    final lines = _textController.text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    int validCount = 0;
    for (final line in lines) {
      String url;
      if (line.contains('|')) {
        url = line.split('|')[0].trim();
      } else {
        url = line.trim();
      }

      if (url.contains('tiktok.com') || url.contains('vm.tiktok.com')) {
        validCount++;
      }
    }

    return validCount;
  }

  @override
  Widget build(BuildContext context) {
    final validCount = _countValidLines();
    final totalLines = _textController.text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;

    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Bulk Add TikTok Links'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How to format your links:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• One link per line\n'
                      '• Format: URL or URL | Custom Title\n'
                      '• Example:\n'
                      '  https://www.tiktok.com/@user/video/123\n'
                      '  https://vm.tiktok.com/xyz | Funny Video',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Text area
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText:
                      'Enter TikTok links (one per line or use | to separate title)',
                  hintText:
                      'Example:\nhttps://www.tiktok.com/@user1/video/123\nhttps://www.tiktok.com/@user2/video/456|Custom Title',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                minLines: 5,
                onChanged: (value) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // Status info
              if (_textController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: validCount > 0
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: validCount > 0
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        validCount > 0 ? Icons.check_circle : Icons.warning,
                        size: 16,
                        color: validCount > 0
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          validCount > 0
                              ? '$validCount valid TikTok link${validCount == 1 ? '' : 's'} found'
                              : totalLines > 0
                              ? 'No valid TikTok links found'
                              : 'Enter some links to see validation',
                          style: TextStyle(
                            fontSize: 12,
                            color: validCount > 0
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (totalLines > validCount && validCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${totalLines - validCount} invalid link${totalLines - validCount == 1 ? '' : 's'} will be skipped',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || validCount == 0 ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Add Links'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
