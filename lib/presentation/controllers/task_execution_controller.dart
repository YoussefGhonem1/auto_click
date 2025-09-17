import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../domain/models/task.dart';
import '../../domain/services/task_service.dart';
import '../../domain/services/task_execution_service.dart';
import '../../data/repositories/automation_repository.dart';

/// Enhanced task execution controller with improved error handling,
/// performance optimizations, and better code structure
class TaskExecutionController extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  late final TaskExecutionService _taskExecutionService;
  late final AutomationRepository _automationRepository;

  // Task execution state
  bool _isExecutingTasks = false;
  Task? _currentExecutingTask;
  String _executionStatus = 'In waiting for tasks';

  // Enhanced execution state tracking
  int _executionAttempts = 0;
  final int _maxRetryAttempts = 3;
  Timer? _executionTimer;
  Completer<void>? _executionCompleter;

  // Performance metrics
  DateTime? _executionStartTime;
  int _tasksExecutedCount = 0;
  int _tasksFailedCount = 0;

  // Getters
  bool get isExecutingTasks => _isExecutingTasks;
  Task? get currentExecutingTask => _currentExecutingTask;
  String get executionStatus => _executionStatus;
  bool get isCurrentlyExecuting => _currentExecutingTask != null;
  int get executionAttempts => _executionAttempts;
  int get tasksExecutedCount => _tasksExecutedCount;
  int get tasksFailedCount => _tasksFailedCount;
  Duration? get executionDuration => _executionStartTime != null
      ? DateTime.now().difference(_executionStartTime!)
      : null;

  // Callbacks
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
    _executionTimer?.cancel();
    _executionCompleter?.complete();
    super.dispose();
  }

  Future<void> toggleTaskExecution() async {
    if (_isExecutingTasks) {
      // If currently executing, stop execution
      _isExecutingTasks = false;
      _executionStatus = 'Stopped';
      _currentExecutingTask = null;
      notifyListeners();
      onShowMessage?.call('Task execution stopped', isError: false);
      return;
    }

    // If not executing, check overlay permission before starting
    final hasPermission = await _ensureOverlayPermission();
    if (!hasPermission) {
      // Permission denied, don't start execution
      return;
    }

    // Permission granted, start execution
    _isExecutingTasks = true;
    _executionStatus = 'Searching for tasks';
    notifyListeners();

    onShowMessage?.call('Task execution enabled', isError: false);
    // Trigger processing of existing tasks when execution is turned on
    onExecutionToggled?.call();
  }

  Future<void> resumeTaskExecution() async {
    if (!_isExecutingTasks) {
      // Check overlay permission before resuming
      final hasPermission = await _ensureOverlayPermission();
      if (!hasPermission) {
        // Permission denied, don't resume execution
        return;
      }

      _isExecutingTasks = true;
      _executionStatus = 'Searching for tasks';
      _currentExecutingTask = null;
      notifyListeners();

      onShowMessage?.call('Task execution resumed', isError: false);
      onExecutionToggled?.call();
    }
  }

  /// Enhanced task termination with proper cleanup
  Future<void> terminateCurrentTask() async {
    if (_isExecutingTasks && _currentExecutingTask != null) {
      final currentTask = _currentExecutingTask!;

      // Mark current task as cancelled
      await _updateTaskStatusSafely(currentTask.id, 'cancelled');

      // Stop execution
      _isExecutingTasks = false;
      _executionTimer?.cancel();
      _currentExecutingTask = null;

      // Complete any pending execution
      if (_executionCompleter != null && !_executionCompleter!.isCompleted) {
        _executionCompleter!.complete();
      }

      _updateExecutionStatus('Task terminated');
      onShowMessage?.call(
        'Task terminated: ${_getTaskTypeText(currentTask.type)}',
        isError: false,
      );
    }
  }

  /// Enhanced task queue processing with better error handling and performance
  Future<void> processTaskQueue(List<Task> tasks) async {
    if (!_isExecutingTasks || isCurrentlyExecuting) return;

    try {
      // Initialize execution metrics
      _executionStartTime = DateTime.now();
      _tasksExecutedCount = 0;
      _tasksFailedCount = 0;
      _executionAttempts = 0;

      // Check overlay permission before processing tasks
      final hasPermission = await _checkOverlayPermission();
      if (!hasPermission) {
        await _handlePermissionError();
        return;
      }

      // Filter and validate tasks
      final executableTasks = _filterExecutableTasks(tasks);
      if (executableTasks.isEmpty) {
        _updateExecutionStatus('No tasks to execute');
        return;
      }

      // Sort and optimize task order
      // final optimizedTasks = _optimizeTaskOrder(executableTasks);

      // Execute tasks with enhanced error handling
      await _executeTaskQueue(executableTasks);
    } catch (e) {
      await _handleQueueProcessingError(e);
    }
  }

  /// Filter tasks that are ready for execution with validation
  List<Task> _filterExecutableTasks(List<Task> tasks) {
    return tasks.where((task) {
      final status = task.status.toLowerCase();
      final isExecutable = status == 'assigned' || status == 'pending';
      final hasValidData = _validateTaskData(task);
      return isExecutable && hasValidData;
    }).toList()..sort((a, b) {
      // First sort by datetime (createdAt) - latest first
      final dateComparison = b.createdAt.compareTo(a.createdAt);
      if (dateComparison != 0) return dateComparison;

      // Then sort by inProgress status (false first, true last)
      return (a.inProgress ? 1 : 0).compareTo(b.inProgress ? 1 : 0);
    });
  }

  /// Validate task data integrity
  bool _validateTaskData(Task task) {
    try {
      final action = task.data['action'] as String?;
      if (action == null || action.isEmpty) return false;

      switch (action) {
        case 'watch':
          return task.data['videoUrl'] != null &&
              task.data['numberOfWatches'] != null;
        case 'like':
        case 'favorite':
        case 'share':
          return task.data['videoUrl'] != null;
        case 'comment':
          return task.data['videoUrl'] != null && task.data['comments'] != null;
        case 'direct_message':
          return task.data['usernames'] != null && task.data['message'] != null;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Task validation error: $e');
      return false;
    }
  }

  /// Enhanced task queue execution with continuous processing
  Future<void> _executeTaskQueue(List<Task> tasks) async {
    _executionCompleter = Completer<void>();

    try {
      // Create a working copy of tasks to avoid modifying the original list
      if (tasks.isEmpty || !_isExecutingTasks) {
        return;
      }

      final workingTasks = List<Task>.from(tasks);

      // Pre-process to identify and prioritize combinable watch tasks
      final nextTaskIndex = _findNextExecutableTaskIndex(workingTasks);

      if (nextTaskIndex == -1) {
        // No more executable tasks, break the loop
        return;
      }

      final task = workingTasks[nextTaskIndex];
      final success = await _executeSingleTaskWithRetry(task, workingTasks);

      if (success) {
        _tasksExecutedCount++;
        await _handleTaskSuccess(task, workingTasks);

        // Remove completed task from working list if it was fully completed
        if (await _isTaskFullyCompleted(task, workingTasks)) {
          workingTasks.removeAt(nextTaskIndex);
        }
      } else {
        _tasksFailedCount++;
        await _handleTaskFailure(task);
        // Remove failed task from working list to prevent infinite retry
        workingTasks.removeAt(nextTaskIndex);
      }

      // Add delay between tasks to prevent overwhelming the system
      if (workingTasks.isNotEmpty && _isExecutingTasks) {
        await _delayBetweenTasks();
      }

      await _handleQueueCompletion();
    } catch (e) {
      await _handleQueueExecutionError(e);
    } finally {
      _executionCompleter?.complete();
    }
  }

  /// Find the next executable task index in the list
  int _findNextExecutableTaskIndex(List<Task> tasks) {
    // First pass: look for tasks that are not in progress
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final status = task.status.toLowerCase();

      // Skip completed or failed tasks
      if (status == 'completed' || status == 'failed') continue;

      // Check if task is ready for execution and not in progress
      if ((status == 'pending' || status == 'assigned') && !task.inProgress) {
        return i;
      }
    }

    // Second pass: if no non-inProgress tasks found, look for any executable task
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final status = task.status.toLowerCase();

      // Skip completed or failed tasks
      if (status == 'completed' || status == 'failed') continue;

      // Check if task is ready for execution (including inProgress tasks)
      if (status == 'pending' || status == 'assigned') {
        return i;
      }
    }
    return -1; // No executable task found
  }

  /// Check if a task is fully completed (no remaining work)
  Future<bool> _isTaskFullyCompleted(Task task, List<Task> allTasks) async {
    // For watch tasks, check if there are remaining watches
    if (task.type == 'watch') {
      final watchCount = task.data['numberOfWatches'] as int? ?? 0;
      return watchCount <= 0;
    }

    // For other task types, they are completed after one execution
    return true;
  }

  /// Execute a single task with retry mechanism
  Future<bool> _executeSingleTaskWithRetry(
    Task task,
    List<Task> allTasks,
  ) async {
    _currentExecutingTask = task;
    _updateExecutionStatus('Executing: ${_getTaskTypeText(task.type)}');

    for (int attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        _executionAttempts = attempt;

        // Handle watch task combinations
        final TaskExecutionContext context = await _prepareTaskExecution(
          task,
          allTasks,
        );

        // Execute the task
        final success = await _executeTaskWithContext(context);

        if (success) {
          debugPrint(
            'Task ${task.id} executed successfully on attempt $attempt',
          );
          return true;
        }

        // If not the last attempt, wait before retrying
        if (attempt < _maxRetryAttempts) {
          await _delayBeforeRetry(attempt);
        }
      } catch (e) {
        debugPrint('Task execution attempt $attempt failed: $e');
        if (attempt == _maxRetryAttempts) {
          rethrow;
        }
      }
    }

    return false;
  }

  /// Prepare task execution context including watch task combinations
  Future<TaskExecutionContext> _prepareTaskExecution(
    Task task,
    List<Task> allTasks,
  ) async {
    Task? combinedTask;
    TaskWatchInfo? watchInfo;

    if (task.type == 'watch') {
      final watchResult = await _handleWatchTaskCombination(task, allTasks);
      combinedTask = watchResult.combinedTask;
      watchInfo = watchResult.watchInfo;
    }

    // Update task status to in_progress
    await _updateTaskStatusSafely(task.id, 'in_progress');
    if (combinedTask != null) {
      await _updateTaskStatusSafely(combinedTask.id, 'in_progress');
    }

    return TaskExecutionContext(
      primaryTask: task,
      combinedTask: combinedTask,
      watchInfo: watchInfo,
    );
  }

  /// Execute task with prepared context
  Future<bool> _executeTaskWithContext(TaskExecutionContext context) async {
    final primaryTask = context.primaryTask;
    final combinedTask = context.combinedTask;
    final watchInfo = context.watchInfo;

    // Prepare task data for execution
    final executionTask = watchInfo != null
        ? primaryTask.copyWith(
            data: {
              ...primaryTask.data,
              'numberOfWatches': watchInfo.primaryWatchCount,
            },
          )
        : primaryTask;

    final executionCombinedTask = combinedTask != null && watchInfo != null
        ? combinedTask.copyWith(
            data: {
              ...combinedTask.data,
              'numberOfWatches': watchInfo.combinedWatchCount,
            },
          )
        : combinedTask;

    // Execute the task
    return await _taskExecutionService.executeTask(
      executionTask,
      executionCombinedTask,
    );
  }

  /// Handle watch task combination logic
  Future<WatchTaskResult> _handleWatchTaskCombination(
    Task task,
    List<Task> allTasks,
  ) async {
    final otherWatchTask = _findFirstWatchTask(
      allTasks.where((t) => t.id != task.id).toList(),
      task.data['videoUrl'] as String,
    );

    if (otherWatchTask == null) {
      return WatchTaskResult(
        combinedTask: null,
        watchInfo: TaskWatchInfo(
          primaryWatchCount: task.data['numberOfWatches'] as int? ?? 1,
          combinedWatchCount: 0,
          remainingPrimaryWatches: 0,
          remainingCombinedWatches: 0,
        ),
      );
    }

    final currentWatches = task.data['numberOfWatches'] as int? ?? 1;
    final otherWatches = otherWatchTask.data['numberOfWatches'] as int? ?? 1;

    final watchInfo = _calculateWatchDistribution(currentWatches, otherWatches);

    // Update watch counts in database
    if (watchInfo.remainingPrimaryWatches > 0) {
      await _taskService.updateWatchCount(
        task.id,
        watchInfo.remainingPrimaryWatches,
      );
    }
    if (watchInfo.remainingCombinedWatches > 0) {
      await _taskService.updateWatchCount(
        otherWatchTask.id,
        watchInfo.remainingCombinedWatches,
      );
    }

    return WatchTaskResult(combinedTask: otherWatchTask, watchInfo: watchInfo);
  }

  /// Calculate optimal watch distribution between tasks
  TaskWatchInfo _calculateWatchDistribution(
    int primaryWatches,
    int combinedWatches,
  ) {
    final minWatches = min(primaryWatches, combinedWatches);

    return TaskWatchInfo(
      primaryWatchCount: minWatches,
      combinedWatchCount: minWatches,
      remainingPrimaryWatches: primaryWatches - minWatches,
      remainingCombinedWatches: combinedWatches - minWatches,
    );
  }

  /// Handle task execution success with improved status management
  Future<void> _handleTaskSuccess(Task task, List<Task> allTasks) async {
    // For watch tasks, we need to handle the watch count logic
    if (task.type == 'watch') {
      await _handleWatchTaskSuccess(task, allTasks);
    } else {
      // For non-watch tasks, simply mark as completed
      await _updateTaskStatusSafely(task.id, 'completed');
      // Update the task in the list
      final taskIndex = allTasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        allTasks[taskIndex] = task.copyWith(status: 'completed');
      }
    }

    onTaskCompleted?.call(task, true);
    onShowMessage?.call(
      'Task completed: ${_getTaskTypeText(task.type)}',
      isError: false,
    );
  }

  /// Handle watch task success with proper count management
  Future<void> _handleWatchTaskSuccess(Task task, List<Task> allTasks) async {
    final otherWatchTask = _findFirstWatchTask(
      allTasks
          .where(
            (t) =>
                t.id != task.id &&
                (t.status.toLowerCase() == 'pending' ||
                    t.status.toLowerCase() == 'assigned'),
          )
          .toList(),
      task.data['videoUrl'] as String,
    );

    if (otherWatchTask != null) {
      final currentWatches = task.data['numberOfWatches'] as int? ?? 1;
      final otherWatches = otherWatchTask.data['numberOfWatches'] as int? ?? 1;

      final minWatches = min(currentWatches, otherWatches);
      final remainingCurrent = currentWatches - minWatches;
      final remainingOther = otherWatches - minWatches;

      // Update current task
      if (remainingCurrent <= 0) {
        await _updateTaskStatusSafely(task.id, 'completed');
        final taskIndex = allTasks.indexWhere((t) => t.id == task.id);
        if (taskIndex != -1) {
          allTasks[taskIndex] = task.copyWith(status: 'completed');
        }
      } else {
        await _taskService.updateWatchCount(task.id, remainingCurrent);
        await _taskService.updateDateTask(
          task.id,
          DateTime.now().add(const Duration(days: 1)),
        );
        await _updateTaskStatusSafely(task.id, 'pending');
        final taskIndex = allTasks.indexWhere((t) => t.id == task.id);

        if (taskIndex != -1) {
          allTasks[taskIndex] = task.copyWith(
            status: 'pending',
            data: {...task.data, 'numberOfWatches': remainingCurrent},
          );
          allTasks.add(task);
          allTasks.removeAt(taskIndex);
        }
      }

      // Update other task
      if (remainingOther <= 0) {
        await _updateTaskStatusSafely(otherWatchTask.id, 'completed');
        final otherIndex = allTasks.indexWhere(
          (t) => t.id == otherWatchTask.id,
        );
        if (otherIndex != -1) {
          allTasks[otherIndex] = otherWatchTask.copyWith(status: 'completed');
        }
      } else {
        await _taskService.updateWatchCount(otherWatchTask.id, remainingOther);
        await _taskService.updateDateTask(
          otherWatchTask.id,
          DateTime.now().add(const Duration(days: 1)),
        );
        await _updateTaskStatusSafely(otherWatchTask.id, 'pending');
        final otherIndex = allTasks.indexWhere(
          (t) => t.id == otherWatchTask.id,
        );
        if (otherIndex != -1) {
          allTasks[otherIndex] = otherWatchTask.copyWith(
            status: 'pending',
            data: {...otherWatchTask.data, 'numberOfWatches': remainingOther},
          );
          allTasks.add(otherWatchTask);
          allTasks.removeAt(otherIndex);
        }
      }
    } else {
      // No other watch task, just complete this one
      await _updateTaskStatusSafely(task.id, 'completed');
      final taskIndex = allTasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        allTasks[taskIndex] = task.copyWith(status: 'completed');
      }
    }
  }

  /// Handle task execution failure
  Future<void> _handleTaskFailure(Task task) async {
    await _updateTaskStatusSafely(task.id, 'failed');
    onTaskCompleted?.call(task, false);
    onShowMessage?.call(
      'Task execution failed: ${_getTaskTypeText(task.type)} (Attempt $_executionAttempts/$_maxRetryAttempts)',
      isError: true,
    );
  }

  /// Handle queue completion
  Future<void> _handleQueueCompletion() async {
    _currentExecutingTask = null;
    final duration = executionDuration;
    final durationText = duration != null
        ? ' in ${duration.inSeconds} seconds'
        : '';

    _updateExecutionStatus('Tasks completed$durationText');

    final successMessage =
        '$_tasksExecutedCount tasks completed successfully'
        '${_tasksFailedCount > 0 ? ' and $_tasksFailedCount tasks failed' : ''}'
        '$durationText';

    onShowMessage?.call(successMessage, isError: _tasksFailedCount > 0);
  }

  /// Handle queue processing errors
  Future<void> _handleQueueProcessingError(dynamic error) async {
    debugPrint('Queue processing error: $error');
    _updateExecutionStatus('Error processing task queue');
    onShowMessage?.call(
      'Error processing task queue: ${error.toString()}',
      isError: true,
    );
  }

  /// Handle queue execution errors
  Future<void> _handleQueueExecutionError(dynamic error) async {
    debugPrint('Queue execution error: $error');
    _currentExecutingTask = null;
    _updateExecutionStatus('Error executing tasks');
    onShowMessage?.call(
      'Error executing tasks: ${error.toString()}',
      isError: true,
    );
  }

  /// Handle permission errors
  Future<void> _handlePermissionError() async {
    _isExecutingTasks = false;
    _updateExecutionStatus(
      'Task execution stopped - Requires overlay permission',
    );
    onShowMessage?.call(
      'Task execution stopped - Requires overlay permission to run',
      isError: true,
    );
  }

  /// Safely update task status with error handling
  Future<bool> _updateTaskStatusSafely(String taskId, String status) async {
    try {
      return await _taskService.updateTaskStatus(taskId, status);
    } catch (e) {
      debugPrint('Failed to update task status: $e');
      return false;
    }
  }

  /// Update execution status and notify listeners
  void _updateExecutionStatus(String status) {
    _executionStatus = status;
    notifyListeners();
  }

  /// Calculate delay between tasks based on task type and system load
  Future<void> _delayBetweenTasks() async {
    const baseDelay = Duration(milliseconds: 1500);

    // Add variable delay based on execution performance
    final additionalDelay = _tasksFailedCount > 0
        ? Duration(milliseconds: 500 * _tasksFailedCount)
        : Duration.zero;

    await Future.delayed(baseDelay + additionalDelay);
  }

  /// Calculate delay before retry based on attempt number
  Future<void> _delayBeforeRetry(int attempt) async {
    // Exponential backoff: 1s, 2s, 4s, etc.
    final delayMs = 1000 * (1 << (attempt - 1));
    await Future.delayed(Duration(milliseconds: delayMs));
  }

  /// Find first watch task in the list
  Task? _findFirstWatchTask(List<Task> tasks, String currentUrl) {
    try {
      return tasks.firstWhere(
        (task) =>
            task.type == 'watch' &&
            (task.status == 'pending' || task.status == 'assigned') &&
            task.data['videoUrl'] != currentUrl,
      );
    } catch (e) {
      return null;
    }
  }

  String _getTaskTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'watch':
        return 'Watch';
      case 'like':
        return 'Like';
      case 'comment':
        return 'Comment';
      case 'share':
        return 'Share';
      case 'favorite':
        return 'Favorite';
      case 'direct_message':
        return 'Direct Message';
      default:
        return type;
    }
  }

  // Public method to access task service for external controllers
  TaskService get taskService => _taskService;

  // Public method to access task execution service for external controllers
  TaskExecutionService get taskExecutionService => _taskExecutionService;

  /// Reload gesture configurations to ensure latest settings are used
  Future<void> reloadGestureConfigurations() async {
    try {
      await _taskExecutionService.reloadGestureConfigurations();
      onShowMessage?.call('Gesture configurations updated', isError: false);
    } catch (e) {
      onShowMessage?.call(
        'Failed to update gesture configurations: ${e.toString()}',
        isError: true,
      );
    }
  }

  // Overlay permission management
  Future<bool> _checkOverlayPermission() async {
    try {
      return await _automationRepository.checkOverlayPermission();
    } catch (e) {
      debugPrint('Error checking overlay permission: $e');
      return false;
    }
  }

  Future<bool> _requestOverlayPermission() async {
    try {
      return await _automationRepository.requestOverlayPermission();
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
      return false;
    }
  }

  Future<bool> _ensureOverlayPermission() async {
    // Check if overlay permission is granted
    final hasPermission = await _checkOverlayPermission();
    if (hasPermission) {
      return true;
    }

    // Request permission
    onShowMessage?.call(
      'Task execution requires overlay permission to run',
      isError: false,
    );
    final permissionGranted = await _requestOverlayPermission();

    if (!permissionGranted) {
      onShowMessage?.call(
        'Requires overlay permission to run tasks',
        isError: true,
      );
      return false;
    }

    onShowMessage?.call('Permission granted successfully', isError: false);
    return true;
  }
}

/// Task execution context for better organization
class TaskExecutionContext {
  final Task primaryTask;
  final Task? combinedTask;
  final TaskWatchInfo? watchInfo;

  const TaskExecutionContext({
    required this.primaryTask,
    this.combinedTask,
    this.watchInfo,
  });
}

/// Watch task information for managing watch counts
class TaskWatchInfo {
  final int primaryWatchCount;
  final int combinedWatchCount;
  final int remainingPrimaryWatches;
  final int remainingCombinedWatches;

  const TaskWatchInfo({
    required this.primaryWatchCount,
    required this.combinedWatchCount,
    required this.remainingPrimaryWatches,
    required this.remainingCombinedWatches,
  });
}

/// Result of watch task combination processing
class WatchTaskResult {
  final Task? combinedTask;
  final TaskWatchInfo watchInfo;

  const WatchTaskResult({this.combinedTask, required this.watchInfo});
}
