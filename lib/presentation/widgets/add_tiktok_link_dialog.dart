import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AddTikTokLinkDialog extends StatefulWidget {
  final Function(String url, String title) onAdd;
  final String? initialUrl;
  final String? initialTitle;
  final bool isEditing;

  const AddTikTokLinkDialog({
    super.key,
    required this.onAdd,
    this.initialUrl,
    this.initialTitle,
    this.isEditing = false,
  });

  @override
  State<AddTikTokLinkDialog> createState() => _AddTikTokLinkDialogState();
}

class _AddTikTokLinkDialogState extends State<AddTikTokLinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.initialUrl ?? '';
    _titleController.text = widget.initialTitle ?? '';
  }

  bool _isValidTikTokUrl(String url) {
    return url.contains('tiktok.com') || url.contains('vm.tiktok.com');
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await widget.onAdd(
      _urlController.text.trim(),
      _titleController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        widget.isEditing ? 'Edit TikTok Link' : 'Add TikTok Link',
        style: AppTextStyles.heading1.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL field
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'TikTok Link *',
                hintText: 'https://www.tiktok.com/@username/video/...',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the link';
                }
                if (!_isValidTikTokUrl(value.trim())) {
                  return 'Please enter a valid TikTok link';
                }
                return null;
              },
              maxLines: 2,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
            ),

            const SizedBox(height: 16),

            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (Optional)',
                hintText: 'Enter a custom title for this link',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Help text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Valid TikTok URLs include:\n'
                      '• https://www.tiktok.com/@username/video/...\n'
                      '• https://vm.tiktok.com/...',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}
