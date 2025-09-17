import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../../domain/models/task.dart';
import '../../utils/task_utils.dart';

class TaskSummaryCard extends StatelessWidget {
  final Task task;
  final bool isCurrentTask;
  final VoidCallback onTap;

  const TaskSummaryCard({
    super.key,
    required this.task,
    required this.isCurrentTask,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = TaskUtils.getStatusColor(task.status, context);
    final taskIcon = TaskUtils.getTaskIcon(task.type);
    final colorScheme = Theme.of(context).colorScheme;
    final operations = TaskUtils.countOperations(task.data);
    final theme = Theme.of(context);

    return Card(
      elevation: isCurrentTask ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentTask
            ? BorderSide(color: colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon, Type, and Status
              Row(
                children: [
                  Icon(
                    taskIcon,
                    color: isCurrentTask
                        ? colorScheme.primary
                        : colorScheme.primary.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      TaskUtils.getTaskTypeText(task.type),
                      style: AppTextStyles.heading2.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      TaskUtils.getStatusText(task.status),
                      style: AppTextStyles.subtitle(
                        context,
                      ).copyWith(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Operations Count
              if (operations.isNotEmpty && operations['total']! > 0)
                _buildOperationsCount(context, operations),

              // const Spacer(),

              // Footer: Time and Execution Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        TaskUtils.formatDateTime(task.createdAt),
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.getDeviceColor(context),
                        ),
                      ),
                    ],
                  ),
                  if (isCurrentTask)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Running',
                        style: AppTextStyles.body1.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationsCount(
    BuildContext context,
    Map<String, int> operations,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = operations['total'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total operations
        Row(
          children: [
            Icon(Icons.touch_app, size: 14, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              '$total operations',
              style: AppTextStyles.body1.copyWith(color: colorScheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
