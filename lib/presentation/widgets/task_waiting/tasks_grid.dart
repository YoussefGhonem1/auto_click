import 'package:flutter/material.dart';
import '../../../domain/models/task.dart';
import '../../../core/theme/app_theme.dart';
import 'task_summary_card.dart';

class TasksGrid extends StatelessWidget {
  final List<Task> tasks;
  final Task? currentExecutingTask;
  final Animation<Offset> slideAnimation;
  final Function(Task) onTaskTap;

  const TasksGrid({
    super.key,
    required this.tasks,
    required this.currentExecutingTask,
    required this.slideAnimation,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: Column(
        children: [
          // Header with tasks count
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned Tasks',
                  style: AppTextStyles.heading2.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length} tasks',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tasks grid
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isCurrentTask = currentExecutingTask?.id == task.id;

                return TaskSummaryCard(
                  task: task,
                  isCurrentTask: isCurrentTask,
                  onTap: () => onTaskTap(task),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
