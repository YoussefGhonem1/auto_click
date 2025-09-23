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

////////////////////////////////////////////////////////////////

  List<Task> _planNextExecutionBatch(List<Task> availableTasks) {
    final executable = availableTasks
        .where((t) => t.status.toLowerCase() == 'pending' || t.status.toLowerCase() == 'assigned')
        .toList();

    if (executable.isEmpty) return [];

    final highPriorityTasks = executable
        .where((t) => t.priority == TaskPriority.high)
        .toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final normalPriorityTasks = executable
        .where((t) => t.priority == TaskPriority.normal)
        .toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
    List<Task> _findCombinablePair(List<Task> list1, [List<Task>? list2]) {
      final searchList = list2 ?? list1;
      for (int i = 0; i < list1.length; i++) {
        final a = list1[i];
        if (a.type != 'watch' || a.data['videoUrl'] == null) continue;
        
        final startIndex = (list1 == searchList) ? i + 1 : 0;
        for (int j = startIndex; j < searchList.length; j++) {
          final b = searchList[j];
          if (b.type != 'watch' || b.data['videoUrl'] == null) continue;
          
          if (a.data['videoUrl'] != b.data['videoUrl']) {
            return [a, b];
          }
        }
      }
      return [];
    }

    // --- بداية المنطق الاستراتيجي ---

    // الحالة (أ): هناك مهمتان عاجلتان أو أكثر
    if (highPriorityTasks.length >= 2) {
      final pair = _findCombinablePair(highPriorityTasks);
      if (pair.isNotEmpty) return pair;
    }

    // الحالة (ب): هناك مهمة عاجلة واحدة فقط
    if (highPriorityTasks.isNotEmpty) {
      final hpTask = highPriorityTasks.first;
      final pair = _findCombinablePair([hpTask], normalPriorityTasks);
      if (pair.isNotEmpty) return pair; // دمج (عاجل + عادي)
      return [hpTask]; // تنفيذ المهمة العاجلة بمفردها
    }

    // الحالة (ج): لا توجد أي مهام عاجلة - **استخدام المنطق الجديد القوي**
    if (normalPriorityTasks.isNotEmpty) {
        // 1. تجميع المهام حسب رابط الفيديو
        final tasksByUrl = <String, List<Task>>{};
        for (final task in normalPriorityTasks) {
            final url = task.data['videoUrl'];
            if (url != null && url is String) {
                (tasksByUrl[url] ??= []).add(task);
            }
        }

        // 2. اتخاذ القرار بناءً على عدد المجموعات
        if (tasksByUrl.keys.length >= 2) {
            // هناك فيديوهات مختلفة، قم بالدمج
            final firstVideoTasks = tasksByUrl.values.first;
            final secondVideoTasks = tasksByUrl.values.elementAt(1);
            return [firstVideoTasks.first, secondVideoTasks.first];
        } else if (tasksByUrl.isNotEmpty) {
            // كل المهام المتبقية لنفس الفيديو، نفذ أقدم واحدة
            return [tasksByUrl.values.first.first];
        }
    }

    // الحالة (د): لا يوجد شيء لتنفيذه
    return [];
  }


  /// **(جديد ومبسط)**
  // في ملف: lib/presentation/controllers/task_execution_controller.dart

  /// **(مُعدلة)**: لم تعد تستقبل قائمة مهام، بل تبدأ العملية فقط.
  Future<void> processTaskQueue() async {
    // هذه الدالة الآن وظيفتها فقط بدء حلقة التنفيذ
    if (!_isExecutingTasks || isCurrentlyExecuting) return;
    await _executeTaskQueue();
  }

  /// **(النسخة النهائية والمصححة)**
  /// حلقة التنفيذ الرئيسية: تجلب أحدث المهام في كل دورة لتجنب مشكلة البيانات القديمة.
  Future<void> _executeTaskQueue() async {
    _executionCompleter = Completer<void>();
    _tasksExecutedCount = 0;
    _tasksFailedCount = 0;

    try {
      // الحلقة تستمر طالما أن المنفذ في وضع التشغيل
      while (_isExecutingTasks) {
        // --- التعديل الجوهري ---
        // 1. احصل على أحدث قائمة مهام من قاعدة البيانات في بداية كل دورة
        final currentTasks = await _taskService.getAllTasks();

        // تحقق مرة أخرى بعد استدعاء الشبكة الطويل، فقد يكون المستخدم أوقف التنفيذ
        if (!_isExecutingTasks) break;

        // 2. خطط للخطوة التالية بناءً على أحدث البيانات
        final batchToExecute = _planNextExecutionBatch(currentTasks);

        // إذا لم يكن هناك مهام مناسبة حاليًا
        if (batchToExecute.isEmpty) {
          _updateExecutionStatus('No suitable tasks to execute, waiting...');
          // انتظر قليلاً ثم ابدأ دورة جديدة للبحث عن مهام مرة أخرى
          await Future.delayed(const Duration(seconds: 5)); 
          continue; // يعود إلى بداية الـ while loop
        }

        // 3. تنفيذ خطة العمل
        final success = await _executeBatchWithRetry(batchToExecute);
        
        // 4. تحديث حالة المهام بعد التنفيذ
        if (success) {
          await _handleBatchSuccess(batchToExecute);
        } else {
          await _handleBatchFailure(batchToExecute);
        }
        
        // لم نعد بحاجة لإزالة المهام يدويًا من قائمة محلية
        // فالدورة التالية ستحصل على قائمة جديدة ونظيفة من قاعدة البيانات
        
        await _delayBetweenTasks();
      }
    } catch (e, s) {
      debugPrint('Queue execution error: $e\n$s');
      await _handleQueueExecutionError(e);
    } finally {
      _currentExecutingTask = null; // تأكد من إعادة تعيين المهمة الحالية
      if (!(_executionCompleter?.isCompleted ?? true)) {
        _executionCompleter?.complete();
      }
      await _handleQueueCompletion();
    }
  }
  /// ينفذ دفعة من المهام (واحدة أو اثنتين) مع محاولات إعادة
  Future<bool> _executeBatchWithRetry(List<Task> batch) async {
    _currentExecutingTask = batch.first;
    _updateExecutionStatus(
      'Executing: ${_getTaskTypeText(batch.first.type)}'
      '${batch.length > 1 ? ' (and another)' : ''}'
    );

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        // -- تعديل مهم: تحديث الحالة والأولوية قبل البدء --
        for (final task in batch) {
          await _taskService.updateTask(task.id, status: 'in_progress', priority: TaskPriority.normal);
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

  /// يتعامل مع فشل دفعة من المهام
  Future<void> _handleBatchFailure(List<Task> batch) async {
    for (final task in batch) {
      await _taskService.updateTask(task.id, status: 'failed');
      _tasksFailedCount++;
      onTaskCompleted?.call(task, false);
    }
    onShowMessage?.call(
      'Task execution failed for: ${_getTaskTypeText(batch.first.type)}',
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