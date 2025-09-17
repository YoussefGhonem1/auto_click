import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'coordinate_field.dart';
import '../../utils/gesture_positions_utils.dart';

class PositionCard extends StatelessWidget {
  final String configKey;
  final Map<String, dynamic> position;
  final Function(String, String, String) onUpdate;

  const PositionCard({
    super.key,
    required this.configKey,
    required this.position,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  GesturePositionsUtils.getPositionIcon(configKey),
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    GesturePositionsUtils.getPositionDisplayName(configKey),
                    style: AppTextStyles.heading2.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CoordinateField(
                    label: 'X',
                    value: position['x']?.toString() ?? '0.0',
                    onChanged: (value) => onUpdate(configKey, 'x', value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CoordinateField(
                    label: 'Y',
                    value: position['y']?.toString() ?? '0.0',
                    onChanged: (value) => onUpdate(configKey, 'y', value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
