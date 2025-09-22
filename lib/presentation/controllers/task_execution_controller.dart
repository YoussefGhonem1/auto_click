// lib/presentation/controllers/task_execution_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/task.dart';
import '../../domain/services/task_service.dart';
import '../../domain/services/task_execution_service.dart';
import '../../data/repositories/automation_repository.dart';
import '../../domain/services/task_combination_service.dart';

class TaskExecutionController extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  late final TaskExecutionService _taskExecutionService;
  late final AutomationRepository _automationRepository;

  // State properties
  bool _isExecutingTasks = false;
  Task? _currentExecutingTask;
  String _executionStatus = 'In waiting for tasks';
  Completer<void>? _executionCompleter;

  // Metrics
  int _tasksExecutedCount = 0;
  int _tasksFailedCount = 0;

  // Getters for UI
  bool get isExecutingTasks => _isExecutingTasks;
  Task? get currentExecutingTask => _currentExecutingTask;
  String get executionStatus => _executionStatus;
  bool get isCurrentlyExecuting => _currentExecutingTask != null;
  TaskService get taskService => _taskService;


  // Callbacks for interacting with the UI
  Function(String message, {bool isError})? onShowMessage;
  Function()? onExecutionToggled;
  Function(Task task, bool success)? onTaskCompleted;

  TaskExecutionController() {
    _initializeServices();
  }

  void _initializeServices() {
    _automationRepository = AutomationRepository();
    _taskExecutionService = TaskExecutionService(_automationRepository);
  }

  @override
  void dispose() {
    _executionCompleter?.complete();
    super.dispose();
  }

  Future<void> toggleTaskExecution() async {
    if (_isExecutingTasks) {
      _isExecutingTasks = false;
      _updateExecutionStatus('Stopped');
      onShowMessage?.call('Task execution stopped', isError: false);
      return;
    }

    final hasPermission = await _ensureOverlayPermission();
    if (!hasPermission) return;

    _isExecutingTasks = true;
    _updateExecutionStatus('Searching for tasks');
    onShowMessage?.call('Task execution enabled', isError: false);
    onExecutionToggled?.call();
  }
  
  Future<void> resumeTaskExecution() async {
    if (!_isExecutingTasks) {
     await toggleTaskExecution();
    }
  }

  Future<void> terminateCurrentTask() async {
    if (_isExecutingTasks && _currentExecutingTask != null) {
      final taskToCancel = _currentExecutingTask!;
      await updateTaskStatusSafely(taskToCancel.id, 'cancelled');
      _isExecutingTasks = false;
      _currentExecutingTask = null;

      if (_executionCompleter != null && !_executionCompleter!.isCompleted) {
        _executionCompleter!.complete();
      }

      _updateExecutionStatus('Task terminated');
      onShowMessage?.call(
        'Task terminated: ${_getTaskTypeText(taskToCancel.type)}',
        isError: false,
      );
      notifyListeners();
    }
  }

  Future<void> reloadGestureConfigurations() async {
    try {
      await _taskExecutionService.reloadGestureConfigurations();
      onShowMessage?.call('Gesture configurations updated', isError: false);
    } catch (e) {
      onShowMessage?.call('Failed to update gesture configurations: ${e.toString()}', isError: true);
    }
  }

  Future<void> processTaskQueue(List<Task> tasks) async {
    if (!_isExecutingTasks || isCurrentlyExecuting) return;

    final executableTasks = _filterAndSortTasks(tasks);
    if (executableTasks.isEmpty) {
      _updateExecutionStatus('No tasks to execute');
      return;
    }

    await _executeTaskQueue(executableTasks);
  }

  List<Task> _filterAndSortTasks(List<Task> tasks) {
    return tasks
        .where((task) =>
            (task.status.toLowerCase() == 'assigned' || task.status.toLowerCase() == 'pending'))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Oldest first is correct
  }

  /// **(FINAL & CORRECTED)** Executes the queue with the new "Smart Swap" combination logic.
  Future<void> _executeTaskQueue(List<Task> tasks) async {
    _executionCompleter = Completer<void>();
    _tasksExecutedCount = 0;
    _tasksFailedCount = 0;
    try {
      final workingTasks = List<Task>.from(tasks);

      while (workingTasks.isNotEmpty && _isExecutingTasks) {
        final firstTask = workingTasks.first;
        Task? partnerTask;

         // **SMART SWAP COMBINATION LOGIC**
         if (firstTask.type == 'watch') {
           // Start searching for a partner from the task that comes *after* the first one.
           for (final potentialPartner in workingTasks) {
             if (potentialPartner.id == firstTask.id) continue; // Skip the task itself.

             // The partner must be a watch task.
             if (potentialPartner.type == 'watch') {
               // **SMART SWAP RULE**: The video URL must be DIFFERENT for Smart Swap optimization
               if (potentialPartner.data['videoUrl'] != firstTask.data['videoUrl']) {
                 partnerTask = potentialPartner;
                 break; // Found the first suitable partner, stop searching.
               }
             }
           }
         }

        final success = await _executeSingleTaskWithRetry(firstTask, partnerTask);

        if (success) {
          await _handleTaskSuccess(firstTask, partnerTask);
        } else {
          await _handleTaskFailure(firstTask, partnerTask);
        }

        workingTasks.removeWhere((t) =>
            t.id == firstTask.id || (partnerTask != null && t.id == partnerTask.id));

        if (workingTasks.isNotEmpty && _isExecutingTasks) {
          await _delayBetweenTasks();
        }
      }
    } catch (e) {
      await _handleQueueExecutionError(e);
    } finally {
      _currentExecutingTask = null;
      if (!(_executionCompleter?.isCompleted ?? true)) {
        _executionCompleter?.complete();
      }
      await _handleQueueCompletion();
    }
  }

  Future<bool> _executeSingleTaskWithRetry(Task task, Task? otherTask) async {
    _currentExecutingTask = task;
    _updateExecutionStatus('Executing: ${_getTaskTypeText(task.type)}${otherTask != null ? ' (and another)' : ''}');

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await updateTaskStatusSafely(task.id, 'in_progress');
        if (otherTask != null) {
          await updateTaskStatusSafely(otherTask.id, 'in_progress');
        }

        final success = await _taskExecutionService.executeTask(task, otherTask);
        if (success) return true;

        if (attempt < 3) await _delayBeforeRetry(attempt);
      } catch (e) {
        debugPrint('Task execution attempt $attempt failed: $e');
      }
    }
    return false;
  }

   Future<void> _handleTaskSuccess(Task task, Task? otherTask) async {
     if (otherTask != null) {
       // Combined execution (Smart Swap)
       final combinationService = TaskCombinationService();
       final result = combinationService.calculate(task, otherTask);

       // Mark both tasks as completed
       await updateTaskStatusSafely(task.id, 'completed');
       await updateTaskStatusSafely(otherTask.id, 'completed');

       // Create remainder task if needed
       if (result.hasRemainder && result.taskWithRemainder != null) {
         await _taskService.createRemainderTask(
           originalTask: result.taskWithRemainder!,
           remainingCount: result.remainderCount,
         );
       }

       _tasksExecutedCount += 2;
       onTaskCompleted?.call(task, true);
       onTaskCompleted?.call(otherTask, true);
       
       onShowMessage?.call(
         'Smart Swap completed: ${_getTaskTypeText(task.type)} + ${_getTaskTypeText(otherTask.type)}', 
         isError: false
       );
     } else {
       // Single task execution
       await updateTaskStatusSafely(task.id, 'completed');
       _tasksExecutedCount++;
       onTaskCompleted?.call(task, true);
       
       onShowMessage?.call(
         'Task completed: ${_getTaskTypeText(task.type)}', 
         isError: false
       );
     }
   }

  Future<void> _handleTaskFailure(Task task, [Task? otherTask]) async {
    await updateTaskStatusSafely(task.id, 'failed');
    if (otherTask != null) {
        await updateTaskStatusSafely(otherTask.id, 'failed');
    }
    _tasksFailedCount++;
    
    onTaskCompleted?.call(task, false);
    if(otherTask != null) onTaskCompleted?.call(otherTask, false);
    
    onShowMessage?.call(
      'Task execution failed: ${_getTaskTypeText(task.type)}',
      isError: true,
    );
  }
  
  Future<bool> updateTaskStatusSafely(String taskId, String status) async {
    try {
      return await _taskService.updateTaskStatus(taskId, status);
    } catch (e) {
      debugPrint('Failed to update task status: $e');
      return false;
    }
  }

  void _updateExecutionStatus(String status) {
    _executionStatus = status;
    notifyListeners();
  }

  Future<void> _delayBetweenTasks() async {
    await Future.delayed(const Duration(milliseconds: 1500));
  }

  Future<void> _delayBeforeRetry(int attempt) async {
    final delayMs = 1000 * (1 << (attempt - 1));
    await Future.delayed(Duration(milliseconds: delayMs));
  }

  Future<void> _handleQueueCompletion() async {
    _currentExecutingTask = null;
    final message = 'Finished. Waiting for new tasks... ($_tasksExecutedCount succeeded, $_tasksFailedCount failed)';
    _updateExecutionStatus(message);
  }

  Future<void> _handleQueueExecutionError(dynamic error) async {
    debugPrint('Queue execution error: $error');
    _currentExecutingTask = null;
    _updateExecutionStatus('Error executing tasks');
    onShowMessage?.call('Error executing tasks: ${error.toString()}', isError: true);
  }

  String _getTaskTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'watch': return 'Watch';
      case 'like': return 'Like';
      case 'comment': return 'Comment';
      case 'share': return 'Share';
      case 'favorite': return 'Favorite';
      case 'direct_message': return 'Direct Message';
      default: return type;
    }
  }

  Future<bool> _ensureOverlayPermission() async {
    final hasPermission = await _automationRepository.checkOverlayPermission();
    if (hasPermission) return true;

    onShowMessage?.call('Task execution requires overlay permission', isError: false);
    final permissionGranted = await _automationRepository.requestOverlayPermission();

    if (!permissionGranted) {
      onShowMessage?.call('Overlay permission is required to run tasks', isError: true);
      return false;
    }
    return true;
  }
}