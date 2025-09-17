import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CommentDialog extends StatefulWidget {
  final String title;
  final String description;
  final Function(String videoUrl, List<String> comments) onConfirm;

  const CommentDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onConfirm,
  });

  @override
  State<CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<CommentDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final List<TextEditingController> _commentControllers = [
    TextEditingController(),
  ];
  bool _isValidUrl = false;
  bool _hasValidComments = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _urlController.dispose();
    for (var controller in _commentControllers) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  bool _validateTikTokUrl(String url) {
    if (url.isEmpty) return false;

    final tikTokPatterns = [
      RegExp(r'^https?://www\.tiktok\.com/@.+/video/\d+'),
      RegExp(r'^https?://vm\.tiktok\.com/.+'),
      RegExp(r'^https?://www\.tiktok\.com/t/.+'),
      RegExp(r'^https?://tiktok\.com/@.+/video/\d+'),
      RegExp(r'^https?://vt\.tiktok\.com/.+'),
      RegExp(r'^https?://m\.tiktok\.com/@.+/video/\d+'),
    ];

    return tikTokPatterns.any((pattern) => pattern.hasMatch(url));
  }

  bool _validateComment(String comment) {
    return comment.trim().isNotEmpty && comment.trim().length >= 2;
  }

  void _onUrlChanged(String value) {
    setState(() {
      _isValidUrl = _validateTikTokUrl(value);
    });
  }

  void _onCommentChanged() {
    setState(() {
      _hasValidComments = _commentControllers.any(
        (controller) => _validateComment(controller.text),
      );
    });
  }

  void _addCommentField() {
    setState(() {
      _commentControllers.add(TextEditingController());
    });
  }

  void _removeCommentField(int index) {
    if (_commentControllers.length > 1) {
      setState(() {
        _commentControllers[index].dispose();
        _commentControllers.removeAt(index);
        _onCommentChanged();
      });
    }
  }

  bool get _canSubmit => _isValidUrl && _hasValidComments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              elevation: 24,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(colorScheme),
                      const SizedBox(height: 24),
                      _buildDescription(theme),
                      const SizedBox(height: 24),
                      _buildUrlInput(theme, colorScheme),
                      const SizedBox(height: 24),
                      _buildCommentsInput(theme, colorScheme),
                      const SizedBox(height: 32),
                      _buildActions(theme, colorScheme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.comment_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.description,
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInput(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.link_rounded, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Video Link',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _urlController,
          onChanged: _onUrlChanged,
          decoration: InputDecoration(
            hintText: 'https://www.tiktok.com/@username/video/...',
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isValidUrl
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.video_library_rounded,
                color: _isValidUrl
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                size: 18,
              ),
            ),
            suffixIcon: _urlController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _urlController.clear();
                      _onUrlChanged('');
                    },
                    icon: Icon(
                      Icons.clear_rounded,
                      color: colorScheme.onSurface,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            errorText: !_isValidUrl && _urlController.text.isNotEmpty
                ? 'Please enter a valid TikTok URL'
                : null,
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          maxLines: 2,
          minLines: 1,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildCommentsInput(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Comment Texts',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addCommentField,
              icon: Icon(Icons.add, size: 18),
              label: Text('Add Comment'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _commentControllers.length,
          itemBuilder: (context, index) {
            final controller = _commentControllers[index];
            final isValid = _validateComment(controller.text);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: controller,
                onChanged: (_) => _onCommentChanged(),
                decoration: InputDecoration(
                  hintText: 'Write comment ${index + 1}...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isValid
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isValid
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            controller.clear();
                            _onCommentChanged();
                          },
                          icon: Icon(
                            Icons.clear_rounded,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      if (_commentControllers.length > 1)
                        IconButton(
                          onPressed: () => _removeCommentField(index),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.error, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.error, width: 2),
                  ),
                  errorText: !isValid && controller.text.isNotEmpty
                      ? 'Please enter a valid comment (minimum 2 characters)'
                      : null,
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                maxLines: 3,
                minLines: 2,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                textInputAction: TextInputAction.newline,
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enter the comments you want to send',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              Text(
                '${_commentControllers.length} comments',
                style: TextStyle(
                  fontSize: 10,
                  color: _hasValidComments
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: _hasValidComments
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: _canSubmit
                ? () {
                    final url = _urlController.text.trim();
                    final comments = _commentControllers
                        .map((controller) => controller.text.trim())
                        .where((comment) => comment.isNotEmpty)
                        .toList();
                    widget.onConfirm(url, comments);
                    Navigator.of(context).pop();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canSubmit
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              foregroundColor: _canSubmit
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _canSubmit ? 4 : 0,
              shadowColor: colorScheme.primary.withOpacity(0.3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_canSubmit) ...[
                  Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  'Send Comment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
