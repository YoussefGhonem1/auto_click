import 'package:flutter/material.dart';
import '../../domain/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../config/task_configuration.dart';
import 'section_card.dart';
import 'task_option_item.dart';

class TasksSection extends StatelessWidget {
  final UserRole? currentUserRole;
  final Function(String) onTaskExecute;

  const TasksSection({
    super.key,
    required this.currentUserRole,
    required this.onTaskExecute,
  });

  @override
  Widget build(BuildContext context) {
    // Check if user has automation permission
    final hasAutomationPermission =
        currentUserRole?.hasPermission(Permission.executeAutomation) ?? false;

    if (!hasAutomationPermission) {
      return _buildNoPermissionWidget(context);
    }

    return _buildTasksWidget(context);
  }

  Widget _buildNoPermissionWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getErrorColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getErrorColor(context).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.lock, color: AppColors.getErrorColor(context), size: 40),
          const SizedBox(height: 16),
          Text(
            'You do not have permission to execute tasks',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.getErrorColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact your administrator to obtain the required permissions',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.getErrorColor(context).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksWidget(BuildContext context) {
    final reactionTasks = TaskConfiguration.getReactionTasks(
      onTaskExecute: onTaskExecute,
    );
    final communicationTasks = TaskConfiguration.getCommunicationTasks(
      onTaskExecute: onTaskExecute,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Interactions',
          icon: Icons.favorite,
          iconColor: AppColors.getReactionColor(context),
          children: reactionTasks
              .map(
                (task) => TaskOptionItem(
                  option: task,
                  color: AppColors.getReactionColor(context),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Communication',
          icon: Icons.message,
          iconColor: AppColors.getCommunicationColor(context),
          children: communicationTasks
              .map(
                (task) => TaskOptionItem(
                  option: task,
                  color: AppColors.getCommunicationColor(context),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
