import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../radar_animation.dart';

class NoTasksEmptyState extends StatelessWidget {
  const NoTasksEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Radar Animation
            RadarAnimation(
              size: 240,
              primaryColor: Theme.of(context).colorScheme.primary,
              secondaryColor: Theme.of(context).colorScheme.secondary,
              duration: const Duration(seconds: 4),
            ),
            const SizedBox(height: 32),
            Text(
              'No Assigned Tasks',
              style: AppTextStyles.heading1.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No tasks have been assigned to this account yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle(context).copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Tasks will appear here once assigned by the administrator',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(context).copyWith(fontSize: 14),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.task_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting for tasks',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
