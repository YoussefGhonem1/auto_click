import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'task_execution_controller.dart';
import '../../data/repositories/automation_repository.dart';
import '../../domain/models/task.dart';

class TaskTerminationController extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.auto.tasks/overlay');

  final TaskExecutionController _executionController;
  final AutomationRepository _automationRepository;

  bool _isOverlayVisible = false;
  bool _isTerminating = false;
  Timer? _overlayTimer;
  Timer? _overlayCheckTimer;

  // Getters
  bool get isOverlayVisible => _isOverlayVisible;
  bool get isTerminating => _isTerminating;

  // Callbacks
  Function(String message, {bool isError})? onShowMessage;

  TaskTerminationController(
    this._executionController,
    this._automationRepository,
  ) {
    _setupMethodChannelHandler();
    _listenToExecutionChanges();
  }

  void _setupMethodChannelHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onTerminateButtonPressed':
          await _handleTerminateButtonPressed();
          break;
        case 'onOverlayDismissed':
          _handleOverlayDismissed();
          break;
        default:
          debugPrint('Unhandled method call: ${call.method}');
      }
    });
  }

  void _listenToExecutionChanges() {
    Task? previousTask = null;

    _executionController.addListener(() {
      final currentTask = _executionController.currentExecutingTask;
      final isExecuting = _executionController.isExecutingTasks;
      final isCurrentlyExecuting = _executionController.isCurrentlyExecuting;

      debugPrint(
        'Execution state changed: isExecuting=$isExecuting, currentTask=${currentTask?.id}, overlayVisible=$_isOverlayVisible',
      );

      // Check if the current task has changed
      final taskChanged = currentTask?.id != previousTask?.id;
      previousTask = currentTask;

      // Show overlay when task execution starts
      if (isCurrentlyExecuting && !_isOverlayVisible) {
        debugPrint('Showing overlay for new task execution');
        _showOverlay();
      }
      // Refresh overlay when task changes (hide and re-show with new task info)
      else if (isCurrentlyExecuting && _isOverlayVisible && taskChanged) {
        debugPrint('Task changed, refreshing overlay with new task info');
        _refreshOverlayForNewTask();
      }
      // Refresh timer if overlay is visible and task is still executing (same task)
      else if (isCurrentlyExecuting && _isOverlayVisible && !taskChanged) {
        debugPrint('Refreshing overlay timer for continuing task execution');
        _startOverlayTimer(); // Refresh the timer
      }
      // Only hide overlay when execution completely stops (not just between tasks)
      else if (!isExecuting && _isOverlayVisible) {
        debugPrint('Hiding overlay as execution completely stopped');
        _hideOverlay();
      }
    });
  }

  Future<void> _showOverlay() async {
    if (_isOverlayVisible) return;

    try {
      // Check overlay permission first
      final hasPermission = await _automationRepository
          .checkOverlayPermission();
      if (!hasPermission) {
        onShowMessage?.call(
          'Requires overlay permission for other applications',
          isError: true,
        );
        // Request permission
        await _automationRepository.requestOverlayPermission();
        return;
      }

      final taskType =
          _executionController.currentExecutingTask?.type ?? 'unknown';
      final taskId = _executionController.currentExecutingTask?.id ?? 'unknown';

      final result = await _automationRepository.showTerminationOverlay(
        taskType,
        taskId,
      );

      if (result == true) {
        _isOverlayVisible = true;
        _startOverlayTimer();
        _startOverlayCheck();
        notifyListeners();

        onShowMessage?.call(
          'Displayed stop button on other applications',
          isError: false,
        );
      } else {
        onShowMessage?.call('Failed to display stop button', isError: true);
      }
    } catch (e) {
      onShowMessage?.call(
        'Error displaying stop button: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<void> _hideOverlay() async {
    if (!_isOverlayVisible) return;

    try {
      await _automationRepository.hideTerminationOverlay();
      _isOverlayVisible = false;
      _stopOverlayTimer();
      _stopOverlayCheck();
      notifyListeners();
    } catch (e) {
      debugPrint('Error hiding overlay: $e');
    }
  }

  Future<void> _refreshOverlayForNewTask() async {
    try {
      // First hide the current overlay
      await _hideOverlay();

      // Small delay to ensure the overlay is properly hidden
      await Future.delayed(const Duration(milliseconds: 100));

      // Then show the overlay with the new task information
      await _showOverlay();

      debugPrint('Overlay refreshed for new task');
    } catch (e) {
      debugPrint('Error refreshing overlay for new task: $e');
    }
  }

  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    // Auto-hide overlay after 5 minutes if no interaction (longer duration)
    _overlayTimer = Timer(const Duration(minutes: 5), () {
      if (_isOverlayVisible && _executionController.isCurrentlyExecuting) {
        debugPrint('Auto-hiding overlay after 5 minutes timeout');
        _hideOverlay();
      }
    });
  }

  void _stopOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
  }

  void _startOverlayCheck() {
    _overlayCheckTimer?.cancel();
    // Check overlay visibility every 10 seconds and restore if needed
    _overlayCheckTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (_isOverlayVisible && _executionController.isCurrentlyExecuting) {
        final actuallyVisible = await _automationRepository.isOverlayVisible();
        if (!actuallyVisible) {
          debugPrint('Overlay disappeared unexpectedly, attempting to restore');
          await _showOverlay();
        }
      }
    });
  }

  void _stopOverlayCheck() {
    _overlayCheckTimer?.cancel();
    _overlayCheckTimer = null;
  }

  Future<void> _handleTerminateButtonPressed() async {
    if (_isTerminating) return;

    _isTerminating = true;
    notifyListeners();

    try {
      // Stop the current task execution
      await _terminateCurrentTask();

      // Hide the overlay
      await _hideOverlay();

      onShowMessage?.call('Terminated current task', isError: false);
    } catch (e) {
      onShowMessage?.call(
        'Error terminating task: ${e.toString()}',
        isError: true,
      );
    } finally {
      _isTerminating = false;
      notifyListeners();
    }
  }

  Future<void> _terminateCurrentTask() async {
    try {
      // Cancel any ongoing event sequence in the accessibility service
      await _cancelEventSequence();

      // Stop task execution in the controller
      _executionController.terminateCurrentTask();

      // Update current task status to cancelled if it exists
      if (_executionController.currentExecutingTask != null) {
        final currentTask = _executionController.currentExecutingTask!;
        await _updateTaskStatus(currentTask.id, 'cancelled');
      }

      debugPrint('Task termination completed successfully');
    } catch (e) {
      debugPrint('Error during task termination: $e');
      rethrow;
    }
  }

  Future<void> _cancelEventSequence() async {
    try {
      // Use the automation repository to cancel event sequence
      await _automationRepository.cancelEventSequence();
    } catch (e) {
      debugPrint('Error cancelling event sequence: $e');
    }
  }

  Future<void> _updateTaskStatus(String taskId, String status) async {
    try {
      // Use TaskService from execution controller to update task status
      await _executionController.taskService.updateTaskStatus(taskId, status);
    } catch (e) {
      debugPrint('Error updating task status: $e');
    }
  }

  void _handleOverlayDismissed() {
    _isOverlayVisible = false;
    _stopOverlayTimer();
    notifyListeners();
  }

  // Manual control methods
  Future<void> showOverlayManually() async {
    if (_executionController.isCurrentlyExecuting) {
      await _showOverlay();
    }
  }

  Future<void> hideOverlayManually() async {
    await _hideOverlay();
  }

  Future<void> terminateTaskManually() async {
    if (_executionController.isCurrentlyExecuting) {
      await _handleTerminateButtonPressed();
    }
  }

  @override
  void dispose() {
    _stopOverlayTimer();
    _stopOverlayCheck();
    _hideOverlay();
    super.dispose();
  }
}
