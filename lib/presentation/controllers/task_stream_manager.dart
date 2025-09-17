import 'dart:async';
import '../../domain/models/task.dart';
import '../../domain/services/task_service.dart';
import '../../domain/services/auth_service.dart';

class TaskStreamManager {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  StreamSubscription<List<Task>>? _taskStreamSubscription;

  // Callbacks
  Function(List<Task> tasks)? onTasksReceived;

  Stream<List<Task>> getUserTasksStream() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    return _taskService.getTasksByUserStream(currentUser.uid);
  }

  void setupTaskStreamListener() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Cancel previous subscription if exists
    _taskStreamSubscription?.cancel();

    _taskStreamSubscription = _taskService
        .getTasksByUserStream(currentUser.uid)
        .listen((tasks) {
          onTasksReceived?.call(tasks);
        });
  }

  void reconnectTaskStream() {
    // Force reconnection by cancelling and re-establishing the stream
    cancelTaskStreamListener();

    // Add a small delay to allow cleanup
    Future.delayed(const Duration(milliseconds: 500), () {
      setupTaskStreamListener();
    });
  }

  void cancelTaskStreamListener() {
    _taskStreamSubscription?.cancel();
    _taskStreamSubscription = null;
  }

  bool get hasActiveStream => _taskStreamSubscription != null;

  List<Task> sortTasksByCreationDate(List<Task> tasks) {
    // Sort tasks by creation date (oldest first)
    final sortedTasks = List<Task>.from(tasks);
    sortedTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sortedTasks;
  }

  void dispose() {
    cancelTaskStreamListener();
  }
}
