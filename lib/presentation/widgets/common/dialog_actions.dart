import 'package:flutter/material.dart';

class DialogActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final String cancelText;
  final String confirmText;
  final IconData? confirmIcon;
  final bool isEnabled;

  const DialogActions({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    this.cancelText = 'Cancel',
    this.confirmText = 'Confirm',
    this.confirmIcon,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            cancelText,
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
            onPressed: isEnabled ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              foregroundColor: isEnabled
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isEnabled ? 4 : 0,
              shadowColor: colorScheme.primary.withOpacity(0.3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEnabled && confirmIcon != null) ...[
                  Icon(confirmIcon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  confirmText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
