import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DeviceItem extends StatelessWidget {
  final String name;
  final bool isConnected;
  final VoidCallback? onSetupTap;

  const DeviceItem({
    super.key,
    required this.name,
    required this.isConnected,
    this.onSetupTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.getConnectedBackgroundColor(context)
            : AppColors.getDisconnectedBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected
              ? AppColors.getConnectedBorderColor(context)
              : AppColors.getDisconnectedBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.error,
            color: isConnected
                ? AppColors.getConnectedColor(context)
                : AppColors.getDisconnectedColor(context),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (!isConnected && onSetupTap != null)
            TextButton(
              onPressed: onSetupTap,
              child: Text(
                'Setup',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}
