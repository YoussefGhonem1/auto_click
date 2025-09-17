import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DialogHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? statusText;
  final Color? statusColor;
  final Color? statusBackgroundColor;

  const DialogHeader({
    super.key,
    required this.title,
    required this.icon,
    this.statusText,
    this.statusColor,
    this.statusBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (statusText != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        statusBackgroundColor ?? colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText!,
                    style: AppTextStyles.subtitle(context).copyWith(
                      color: statusColor ?? colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
