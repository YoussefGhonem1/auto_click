import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'coordinate_field.dart';
import '../../utils/gesture_positions_utils.dart';

class GestureCard extends StatelessWidget {
  final String configKey;
  final Map<String, dynamic> gesture;
  final Function(String, String, String, String) onUpdate;

  const GestureCard({
    super.key,
    required this.configKey,
    required this.gesture,
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
                  Icons.gesture,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    GesturePositionsUtils.getPositionDisplayName(configKey),
                    style: AppTextStyles.subtitle(
                      context,
                    ).copyWith(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Start Point',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CoordinateField(
                    label: 'X',
                    value: gesture['start']?['x']?.toString() ?? '0.0',
                    onChanged: (value) =>
                        onUpdate(configKey, 'start', 'x', value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CoordinateField(
                    label: 'Y',
                    value: gesture['start']?['y']?.toString() ?? '0.0',
                    onChanged: (value) =>
                        onUpdate(configKey, 'start', 'y', value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'End Point',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CoordinateField(
                    label: 'X',
                    value: gesture['end']?['x']?.toString() ?? '0.0',
                    onChanged: (value) =>
                        onUpdate(configKey, 'end', 'x', value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CoordinateField(
                    label: 'Y',
                    value: gesture['end']?['y']?.toString() ?? '0.0',
                    onChanged: (value) =>
                        onUpdate(configKey, 'end', 'y', value),
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
