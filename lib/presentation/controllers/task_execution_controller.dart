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
    bool _isProcessingBatch = false; 
      bool _isLoopActive = false;
      bool _isRunning = false;
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
    bool get isCurrentlyExecuting => _isProcessingBatch;
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

////////////////////////////////////////////////////////////////
/// ===================================================================
 List<Task> _planNextExecutionBatch(List<Task> availableTasks) {
  final executable = availableTasks
      .where((t) => t.status.toLowerCase() == 'pending' || t.status.toLowerCase() == 'assigned')
      .toList();

  if (executable.isEmpty) return [];

  // فصل المهام
  final highPriorityTasks = executable
    .where((t) => t.priority == TaskPriority.high)
    .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final normalPriorityTasks = executable
    .where((t) => t.priority == TaskPriority.normal)
    .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Task? findPartnerFor(Task primaryTask, List<Task> candidates) {
    if (primaryTask.type != 'watch' || primaryTask.data['videoUrl'] == null) return null;
    for (final candidate in candidates) {
      if (candidate.id != primaryTask.id &&
          candidate.type == 'watch' &&
          candidate.data['videoUrl'] != null &&
          candidate.data['videoUrl'] != primaryTask.data['videoUrl']) {
        return candidate;
      }
    }
    return null;
  }

  // الأولوية: High
  if (highPriorityTasks.isNotEmpty) {
    final primaryTask = highPriorityTasks.first;
    var partner = findPartnerFor(primaryTask, highPriorityTasks);
    partner ??= findPartnerFor(primaryTask, normalPriorityTasks);

    if (partner != null) {
      // تحقق من تطابق عدد المشاهدات
      final count1 = primaryTask.data['count'] ?? 0;
      final count2 = partner.data['count'] ?? 0;

      if (count1 == count2) {
        return [primaryTask, partner];
      } else {
        // نفذ الأصغر واعمل Task جديدة بالباقي
        final bigger = count1 > count2 ? primaryTask : partner;
        final smaller = count1 > count2 ? partner : primaryTask;
        final remainder = (count1 - count2).abs();

        return [smaller, bigger.copyWith(data: {...bigger.data, 'count': count2}, priority: bigger.priority)];
        // بعد النجاح هيتعمل Remainder Task جديدة Normal بالـ remainder
      }
    }
    return [primaryTask];
  }

  // مفيش High → اشتغل على Normal
  if (normalPriorityTasks.isNotEmpty) {
    final oldestTask = normalPriorityTasks.first;
    final partner = findPartnerFor(oldestTask, normalPriorityTasks);
    if (partner != null) {
      final count1 = oldestTask.data['count'] ?? 0;
      final count2 = partner.data['count'] ?? 0;

      if (count1 == count2) {
        return [oldestTask, partner];
      } else {
        final bigger = count1 > count2 ? oldestTask : partner;
        final smaller = count1 > count2 ? partner : oldestTask;
        final remainder = (count1 - count2).abs();

        return [smaller, bigger.copyWith(data: {...bigger.data, 'count': count2}, priority: bigger.priority)];
        // الباقي هيبقى Task جديدة Normal
      }
    }
    return [oldestTask];
  }

  return [];
}

  /// **(جديد ومبسط)**
  // في ملف: lib/presentation/controllers/task_execution_controller.dart

  /// **(مُعدلة)**: لم تعد تستقبل قائمة مهام، بل تبدأ العملية فقط.
 void processTaskQueue() {
  // لو فيه لوب أو دفعة شغالة أو مش مفعل التنفيذ → اخرج
  if (_isLoopActive || _isProcessingBatch || !_isExecutingTasks) {
    return;
  }

  // قفل البوابة
  _isLoopActive = true;
  _updateExecutionStatus('Searching for tasks...');

  // شغّل اللوب الجديد
  _executeTaskQueue().whenComplete(() {
    // بعد ما اللوب كله يخلص أو يحصل خطأ
    _isLoopActive = false;
    _handleQueueCompletion();
  });
}

  
  /// **(النسخة النهائية والمصححة)**
  /// حلقة التنفيذ الرئيسية: تجلب أحدث المهام في كل دورة لتجنب مشكلة البيانات القديمة.
 Future<void> _executeTaskQueue() async {
  if (_isProcessingBatch) return; // تأكد مفيش دفعة شغالة
  _isProcessingBatch = true;

  _executionCompleter = Completer<void>();
  _tasksExecutedCount = 0;
  _tasksFailedCount = 0;

  try {
    while (_isExecutingTasks) {
      final currentTasks = await _taskService.getAllTasks();
      if (!_isExecutingTasks) break;

      // خطط للدفعة الجاية
      final batchToExecute = _planNextExecutionBatch(currentTasks);

      if (batchToExecute.isEmpty) {
        _updateExecutionStatus('No suitable tasks to execute, waiting...');
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }

      _currentExecutingTask = batchToExecute.first;
      notifyListeners();

      final success = await _executeBatchWithRetry(batchToExecute);

      if (success) {
        await _handleBatchSuccess(batchToExecute);
      } else {
        await _handleBatchFailure(batchToExecute);
      }

      _currentExecutingTask = null;
      notifyListeners();

      await _delayBetweenTasks();
    }
  } catch (e, s) {
    debugPrint('Queue execution error: $e\n$s');
    await _handleQueueExecutionError(e);
  } finally {
    _currentExecutingTask = null;
    if (!(_executionCompleter?.isCompleted ?? true)) {
      _executionCompleter?.complete();
    }
    await _handleQueueCompletion();
    _isProcessingBatch = false;
    notifyListeners();
  }
}

 Future<bool> _executeBatchWithRetry(List<Task> batch) async {
  _currentExecutingTask = batch.first;
  _updateExecutionStatus(
    'Executing: ${_getTaskTypeText(batch.first.type)}'
    '${batch.length > 1 ? ' (merged)' : ''}'
  );

  for (int attempt = 1; attempt <= 3; attempt++) {
    try {
      for (final task in batch) {
        await _taskService.updateTask(task.id, status: 'in_progress');
      }

      final success = await _taskExecutionService.executeTask(
        batch.first,
        batch.length > 1 ? batch.last : null,
      );

      if (success) return true;
      if (attempt < 3) await _delayBeforeRetry(attempt);

    } catch (e) {
      debugPrint('Task execution attempt $attempt failed: $e');
    }
  }
  return false;
}

   /// يتعامل مع نجاح دفعة من المهام
   Future<void> _handleBatchSuccess(List<Task> batch) async {
     if (batch.length > 1) {
       // حالة الدمج
       final task1 = batch[0];
       final task2 = batch[1];
       
       final combinationService = TaskCombinationService();
       final result = combinationService.calculate(task1, task2);

       await _taskService.updateTask(task1.id, status: 'completed');
       await _taskService.updateTask(task2.id, status: 'completed');

       if (result.hasRemainder && result.taskWithRemainder != null) {
         await _taskService.createRemainderTask(
           originalTask: result.taskWithRemainder!,
           remainingCount: result.remainderCount,
         );
       }
       
       _tasksExecutedCount += 2;
       onTaskCompleted?.call(task1, true);
       onTaskCompleted?.call(task2, true);
       onShowMessage?.call('Smart Swap completed!', isError: false);

     } else {
       // حالة المهمة المنفردة
       final task = batch.first;
       await _taskService.updateTask(task.id, status: 'completed');
       _tasksExecutedCount++;
       onTaskCompleted?.call(task, true);
       onShowMessage?.call('Task completed: ${_getTaskTypeText(task.type)}', isError: false);
     }
   }

 Future<void> _handleBatchFailure(List<Task> batch) async {
    for (final task in batch) {
      // تعديل: أرجع الحالة إلى pending بدلاً من failed
      await _taskService.updateTask(task.id, status: 'pending');
      _tasksFailedCount++;
      onTaskCompleted?.call(task, false);
    }
    onShowMessage?.call(
      'Task execution failed for: ${_getTaskTypeText(batch.first.type)}. Re-scheduling.',
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