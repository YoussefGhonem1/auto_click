import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'common/animated_dialog.dart';
import 'common/dialog_header.dart';
import 'common/dialog_description.dart';
import 'common/dialog_actions.dart';
import 'common/form_text_field.dart';
import 'common/validation_mixin.dart';

class FavoriteDialog extends StatefulWidget {
  final String title;
  final String description;
  final Function(String videoUrl, int numberOfFavorites) onConfirm;

  const FavoriteDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onConfirm,
  });

  @override
  State<FavoriteDialog> createState() => _FavoriteDialogState();
}

class _FavoriteDialogState extends State<FavoriteDialog> with ValidationMixin {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _favoritesController = TextEditingController();
  bool _isValidUrl = false;
  bool _isValidFavorites = true;

  @override
  void dispose() {
    _urlController.dispose();
    _favoritesController.dispose();
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

  bool _validateFavorites(String favorites) {
    if (favorites.isEmpty) return false;
    final parsed = int.tryParse(favorites);
    return parsed != null && parsed > 0;
  }

  void _onUrlChanged(String value) {
    setState(() {
      _isValidUrl = _validateTikTokUrl(value);
    });
  }

  void _onFavoritesChanged(String value) {
    setState(() {
      _isValidFavorites = _validateFavorites(value);
    });
  }

  void _handleConfirm() {
    final url = _urlController.text.trim();
    final favorites = int.parse(_favoritesController.text.trim());
    widget.onConfirm(url, favorites);
    Navigator.of(context).pop();
  }

  bool get _canSubmit => _isValidUrl && _isValidFavorites;

  @override
  Widget build(BuildContext context) {
    return AnimatedDialog(
      maxWidth: 600,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogHeader(
            title: widget.title,
            icon: Icons.star_rounded,
            statusText: 'Required',
          ),
          const SizedBox(height: 24),
          DialogDescription(description: widget.description),
          const SizedBox(height: 24),
          _buildUrlInput(),
          const SizedBox(height: 24),
          _buildFavoritesInput(),
          const SizedBox(height: 32),
          DialogActions(
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: _handleConfirm,
            confirmText: 'Add to Favorites',
            confirmIcon: Icons.star_rounded,
            isEnabled: _canSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInput() {
    final colorScheme = Theme.of(context).colorScheme;

    return FormFieldContainer(
      icon: Icon(Icons.link_rounded, size: 18, color: colorScheme.primary),
      title: 'Video Link',
      isRequired: true,
      child: FormTextField(
        controller: _urlController,
        hintText: 'https://www.tiktok.com/@username/video/...',
        onChanged: _onUrlChanged,
        errorText: !_isValidUrl && _urlController.text.isNotEmpty
            ? 'Please enter a valid TikTok link'
            : null,
        isValid: _isValidUrl,
        maxLines: 2,
        keyboardType: TextInputType.url,
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
        onClear: () {
          _urlController.clear();
          _onUrlChanged('');
        },
      ),
    );
  }

  Widget _buildFavoritesInput() {
    final colorScheme = Theme.of(context).colorScheme;

    return FormFieldContainer(
      icon: Icon(Icons.star_rounded, size: 18, color: colorScheme.primary),
      title: 'Number of Favorites',
      isRequired: true,
      helperText: 'Enter the number of favorites required',
      child: FormTextField(
        controller: _favoritesController,
        hintText: 'Number of Favorites',
        onChanged: _onFavoritesChanged,
        errorText: !_isValidFavorites && _favoritesController.text.isNotEmpty
            ? 'Please enter a number greater than zero'
            : null,
        isValid: _isValidFavorites,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isValidFavorites
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.numbers_rounded,
            color: _isValidFavorites
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            size: 18,
          ),
        ),
        suffixActions: [],
      ),
    );
  }
}
