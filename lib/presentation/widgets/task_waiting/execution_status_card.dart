import 'package:flutter/material.dart';
import '../../../domain/models/task.dart';
import '../../../core/theme/app_theme.dart';
import '../../utils/task_utils.dart';

class ExecutionStatusCard extends StatelessWidget {
  final bool isExecutingTasks;
  final Task? currentExecutingTask;
  final String executionStatus;
  final Duration cleanupInterval;
  final Future<void> Function() onToggleExecution;
  final bool isOverlayVisible;
  final bool isTerminating;
  final VoidCallback onShowOverlay;
  final VoidCallback onHideOverlay;
  final VoidCallback onTerminateTask;

  const ExecutionStatusCard({
    super.key,
    required this.isExecutingTasks,
    required this.currentExecutingTask,
    required this.executionStatus,
    required this.cleanupInterval,
    required this.onToggleExecution,
    this.isOverlayVisible = false,
    this.isTerminating = false,
    required this.onShowOverlay,
    required this.onHideOverlay,
    required this.onTerminateTask,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getExecutionStatusColor(context).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getExecutionStatusIcon(),
              color: _getExecutionStatusColor(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  executionStatus,
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (currentExecutingTask != null)
                  Text(
                    'Executing: ${TaskUtils.getTaskTypeText(currentExecutingTask!.type)}',
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                if (isExecutingTasks && currentExecutingTask == null)
                  Text(
                    'Auto-cleanup every ${cleanupInterval.inMinutes} minutes',
                    style: AppTextStyles.caption(context).copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                if (isOverlayVisible)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getErrorColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stop_circle,
                          size: 12,
                          color: AppColors.getErrorColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stop button is visible',
                          style: AppTextStyles.caption(context).copyWith(
                            color: AppColors.getErrorColor(context),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Action Buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Execution Toggle
              Switch(
                value: isExecutingTasks,
                onChanged: (value) async => await onToggleExecution(),
                activeColor: colorScheme.primary,
              ),
              // Termination Controls (only when executing)
              if (isExecutingTasks && currentExecutingTask != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show/Hide Overlay Button
                    IconButton(
                      onPressed: isOverlayVisible
                          ? onHideOverlay
                          : onShowOverlay,
                      icon: Icon(
                        isOverlayVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 18,
                      ),
                      tooltip: isOverlayVisible
                          ? 'Hide stop button'
                          : 'Show stop button',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.onSurface,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Terminate Task Button
                    IconButton(
                      onPressed: isTerminating ? null : onTerminateTask,
                      icon: isTerminating
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.error,
                                ),
                              ),
                            )
                          : const Icon(Icons.stop, size: 18),
                      tooltip: 'Terminate current task',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getExecutionStatusColor(BuildContext context) {
    if (isExecutingTasks) {
      return currentExecutingTask != null
          ? AppColors.getSuccessColor(context)
          : AppColors.getInfoColor(context);
    }
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
  }

  IconData _getExecutionStatusIcon() {
    if (isExecutingTasks) {
      return currentExecutingTask != null ? Icons.play_arrow : Icons.pause;
    }
    return Icons.stop;
  }
}
