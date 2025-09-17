import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'duration_field.dart';
import '../../utils/gesture_positions_utils.dart';

class DurationCard extends StatelessWidget {
  final String configKey;
  final int duration;
  final Function(String, String) onUpdate;

  const DurationCard({
    super.key,
    required this.configKey,
    required this.duration,
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
                  GesturePositionsUtils.getDurationIcon(configKey),
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    GesturePositionsUtils.getDurationDisplayName(configKey),
                    style: AppTextStyles.subtitle(
                      context,
                    ).copyWith(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DurationField(
              value: duration.toString(),
              onChanged: (value) => onUpdate(configKey, value),
            ),
          ],
        ),
      ),
    );
  }
}
