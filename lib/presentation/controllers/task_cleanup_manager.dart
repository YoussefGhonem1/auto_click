import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/task.dart';
import '../../domain/services/task_service.dart';
import '../../domain/services/auth_service.dart';

class TaskCleanupManager {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  Timer? _cleanupTimer;
  bool _isTimerPaused = false;

  // Cleanup configuration
  static const Duration _completedTaskRetentionDuration = Duration(minutes: 4);
  static const Duration _cleanupInterval = Duration(minutes: 2);

  // Getters
  Duration get cleanupInterval => _cleanupInterval;
  Duration get retentionDuration => _completedTaskRetentionDuration;
  bool get isTimerActive => _cleanupTimer != null && !_isTimerPaused;

  // Callbacks
  Function(String message, {bool isError})? onShowMessage;

  void startCleanupTimer() {
    if (_cleanupTimer != null) return; // Already started

    _isTimerPaused = false;
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      if (!_isTimerPaused) {
        _performPeriodicCleanup();
      }
    });
  }

  void stopCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _isTimerPaused = false;
  }

  void pauseCleanupTimer() {
    _isTimerPaused = true;
  }

  void resumeCleanupTimer() {
    _isTimerPaused = false;
    // If timer was completely stopped, restart it
    if (_cleanupTimer == null) {
      startCleanupTimer();
    }
  }

  Future<void> _performPeriodicCleanup() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      // Get all tasks for the user
      final tasks = await _taskService
          .getTasksByUserStream(currentUser.uid)
          .first;
      cleanupCompletedTasks(tasks);
    } catch (e) {
      // Log error but don't show to user for background cleanup
      debugPrint('Cleanup error: $e');
    }
  }

  void cleanupCompletedTasks(List<Task> tasks) {
    final now = DateTime.now();

    // Clean up completed tasks
    final completedTasks = tasks
        .where(
          (task) =>
              task.status.toLowerCase() == 'completed' &&
              now.difference(task.createdAt) > _completedTaskRetentionDuration,
        )
        .toList();

    for (final task in completedTasks) {
      _taskService.deleteTask(task.id);
    }

    // Clean up failed tasks
    final failedTasks = tasks
        .where(
          (task) =>
              task.status.toLowerCase() == 'failed' &&
              now.difference(task.createdAt) > _completedTaskRetentionDuration,
        )
        .toList();

    for (final task in failedTasks) {
      _taskService.deleteTask(task.id);
    }
  }

  Future<void> performManualCleanup() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      // Get all tasks for the user
      final tasks = await _taskService
          .getTasksByUserStream(currentUser.uid)
          .first;

      // Perform cleanup with immediate effect (no retention period for manual cleanup)
      final tasksToDelete = tasks
          .where(
            (task) =>
                task.status.toLowerCase() == 'completed' ||
                task.status.toLowerCase() == 'failed',
          )
          .toList();

      int deletedCount = 0;
      for (final task in tasksToDelete) {
        final success = await _taskService.deleteTask(task.id);
        if (success) deletedCount++;
      }

      if (deletedCount > 0) {
        onShowMessage?.call(
          'Deleted $deletedCount completed and failed tasks',
          isError: false,
        );
      } else {
        onShowMessage?.call(
          'No completed or failed tasks to delete',
          isError: false,
        );
      }
    } catch (e) {
      onShowMessage?.call(
        'Error cleaning up tasks: ${e.toString()}',
        isError: true,
      );
    }
  }

  void dispose() {
    stopCleanupTimer();
  }
}
