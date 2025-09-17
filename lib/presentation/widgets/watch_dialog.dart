import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/tiktok_links_page.dart';

class WatchDialog extends StatefulWidget {
  final String title;
  final String description;
  final Function(String videoUrl, int numberOfWatches) onConfirm;

  const WatchDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onConfirm,
  });

  @override
  State<WatchDialog> createState() => _WatchDialogState();
}

class _WatchDialogState extends State<WatchDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _watchesController = TextEditingController();
  bool _isValidUrl = false;
  bool _isValidWatches = true;
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
    _watchesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _validateTikTokUrl(String url) {
    if (url.isEmpty) return false;

    final tikTokPatterns = [
      RegExp(r'^https?://www\.tiktok\.com/@.+/video/\d+'),
      RegExp(r'^https?://vm\.tiktok\.com/.+'),
      RegExp(r'^https?://www\.tiktok\.com/t/.+'),
      RegExp(r'^https?://vt\.tiktok\.com/.+'),
      RegExp(r'^https?://tiktok\.com/@.+/video/\d+'),
      RegExp(r'^https?://m\.tiktok\.com/@.+/video/\d+'),
    ];

    return tikTokPatterns.any((pattern) => pattern.hasMatch(url));
  }

  bool _validateWatches(String watches) {
    if (watches.isEmpty) return false;
    final parsed = int.tryParse(watches);
    return parsed != null && parsed > 0;
  }

  void _onUrlChanged(String value) {
    setState(() {
      _isValidUrl = _validateTikTokUrl(value);
    });
  }

  void _onWatchesChanged(String value) {
    setState(() {
      _isValidWatches = _validateWatches(value);
    });
  }

  bool get _canSubmit => _isValidUrl && _isValidWatches;

  void _navigateToTikTokLinks() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TikTokLinksPage()));
  }

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
                  padding: const EdgeInsets.all(20),
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
                      _buildWatchesInput(theme, colorScheme),
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
            Icons.play_circle_filled,
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
        // TikTok Links Navigation Icon
        Container(
          margin: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: _navigateToTikTokLinks,
            tooltip: 'Manage TikTok Links',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.link,
                color: colorScheme.onTertiaryContainer,
                size: 20,
              ),
            ),
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
                ? 'Please enter a valid TikTok link'
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

  Widget _buildWatchesInput(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.visibility_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Number of Views',
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
          controller: _watchesController,
          onChanged: _onWatchesChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Number of Views',
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isValidWatches
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.numbers_rounded,
                color: _isValidWatches
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                size: 18,
              ),
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
            errorText: !_isValidWatches && _watchesController.text.isNotEmpty
                ? 'Please enter a number greater than zero'
                : null,
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 16),
          child: Text(
            'Enter the number of views required (greater than zero)',
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
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
                    final watches = int.parse(_watchesController.text.trim());
                    widget.onConfirm(url, watches);
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
                  Icon(Icons.play_arrow_rounded, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  'Start Watching',
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
