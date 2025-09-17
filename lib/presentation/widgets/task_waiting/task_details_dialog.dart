import 'package:flutter/material.dart';
import '../../../domain/models/task.dart';
import '../../../domain/services/task_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../utils/task_utils.dart';

class TaskDetailsDialog extends StatefulWidget {
  final Task task;

  const TaskDetailsDialog({super.key, required this.task});

  @override
  State<TaskDetailsDialog> createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends State<TaskDetailsDialog> {
  final TaskService _taskService = TaskService();
  bool _isRefreshing = false;

  Future<void> _refreshTaskToPending() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final success = await _taskService.updateTaskStatus(
        widget.task.id,
        'pending',
      );

      if (success) {
        if (mounted) {
          SnackbarUtils.showSuccess(
            context,
            'Task status updated to "Pending" successfully',
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          SnackbarUtils.showError(context, 'Failed to update task status');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'An error occurred while updating the task: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            TaskUtils.getTaskIcon(widget.task.type),
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            TaskUtils.getTaskTypeText(widget.task.type),
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Identifier', widget.task.id),
            _buildDetailRow(
              'Status',
              TaskUtils.getStatusText(widget.task.status),
            ),
            _buildDetailRow(
              'Creation Date',
              TaskUtils.formatDateTime(widget.task.createdAt),
            ),
            if (widget.task.data.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Task Data:',
                style: AppTextStyles.heading2.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Show operation counts if available
              _buildOperationsSection(context),

              // Show other data
              ...widget.task.data.entries
                  .where((entry) => !_isOperationKey(entry.key))
                  .map(
                    (entry) =>
                        _buildDetailRow(entry.key, entry.value.toString()),
                  ),
            ],
          ],
        ),
      ),
      actions: [
        // Show refresh button only for failed tasks
        if (widget.task.status.toLowerCase() == 'failed')
          TextButton.icon(
            onPressed: _isRefreshing ? null : _refreshTaskToPending,
            icon: _isRefreshing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.getWarningColor(context),
                      ),
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: AppColors.getWarningColor(context),
                  ),
            label: Text(
              _isRefreshing ? 'Refreshing...' : 'Refresh to Pending',
              style: TextStyle(color: AppColors.getWarningColor(context)),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close', style: TextStyle(color: colorScheme.onSurface)),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.subtitle(context).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(': ', style: TextStyle(color: colorScheme.onSurface)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body1.copyWith(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsSection(BuildContext context) {
    final operations = TaskUtils.countOperations(widget.task.data);
    final colorScheme = Theme.of(context).colorScheme;

    if (operations.isEmpty || operations['total'] == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total operations
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Total Operations: ${operations['total']}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Individual operations
        Text(
          'Operation Details:',
          style: AppTextStyles.subtitle(context).copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: operations.entries
              .where((entry) => entry.key != 'total' && entry.value > 0)
              .map(
                (entry) =>
                    _buildOperationDetailChip(context, entry.key, entry.value),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOperationDetailChip(
    BuildContext context,
    String operation,
    int count,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getOperationIcon(operation),
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${TaskUtils.getOperationText(operation)}: $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getOperationIcon(String operation) {
    switch (operation.toLowerCase()) {
      case 'likes':
        return Icons.favorite;
      case 'watches':
        return Icons.visibility;
      case 'comments':
        return Icons.comment;
      case 'shares':
        return Icons.share;
      case 'favorites':
        return Icons.bookmark;
      case 'directmessages':
        return Icons.message;
      default:
        return Icons.touch_app;
    }
  }

  bool _isOperationKey(String key) {
    final operationKeys = [
      'likes',
      'watches',
      'comments',
      'shares',
      'favorites',
      'directMessages',
    ];
    return operationKeys.contains(key.toLowerCase());
  }
}
