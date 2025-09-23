import '../../domain/services/task_service.dart';
import '../../domain/services/server_management_service.dart';
import '../../domain/services/task_calculation_service.dart';
import '../../domain/models/task.dart';

class TaskController {
  final TaskService _taskService = TaskService();
  final ServerManagementService _serverService = ServerManagementService();
  bool _isCreatingTask = false;

  bool get isCreatingTask => _isCreatingTask;

  /// Get all available servers owned by current admin
  Future<List<String>> _getAllAvailableServers() async {
    try {
      final connectedServers = await _serverService.getAdminConnectedServers();
      if (connectedServers.isEmpty) {
        return [];
      }
      return connectedServers.map((server) => server.uid).toList();
    } catch (e) {
      return [];
    }
  }

  List<ServerDistribution> _distributeTasksAmongServers(
    List<String> servers,
    int totalCount,
    int? maxPerServer,
  ) {
    if (servers.isEmpty) return [];

    final distributions = <ServerDistribution>[];
    final serverCount = servers.length;
    final baseCount = totalCount ~/ serverCount;
    final remainder = totalCount % serverCount;

    for (int i = 0; i < serverCount; i++) {
      int count = baseCount;
      if (i < remainder) { // توزيع أكثر عدلاً للباقي
        count++;
      }
      if (maxPerServer != null && count > maxPerServer) {
        count = maxPerServer;
      }
      if (count > 0) {
        distributions.add(
          ServerDistribution(serverUid: servers[i], count: count),
        );
      }
    }

    return distributions;
  }

  /// Split tasks that exceed maxTaskDuration into smaller tasks
  List<TaskSplit> _splitTasksByDuration(
    String taskType,
    int totalCount,
    int maxOperationsPerTask,
  ) {
    final splits = <TaskSplit>[];
    int remainingCount = totalCount;

    while (remainingCount > 0) {
      final countForThisTask = remainingCount > maxOperationsPerTask
          ? maxOperationsPerTask
          : remainingCount;

      splits.add(TaskSplit(taskType: taskType, count: countForThisTask));

      remainingCount -= countForThisTask;
    }

    return splits;
  }

Future<List<String>> executeCommentTask(
    String videoUrl,
    List<String> comments,
  ) async {
    if (_isCreatingTask) return [];
    _isCreatingTask = true;
    try {
      final availableServers = await _getAllAvailableServers();
      if (availableServers.isEmpty) {
        throw Exception('No servers available at the moment');
      }

      final createdTaskIds = <String>[];
      final distributions = _distributeTasksAmongServers(
        availableServers,
        comments.length,
        8,
      );

      int commentIndex = 0;
      bool isFirstTaskInAction = true; // تعديل: متغير محلي
      for (final distribution in distributions) {
        final serverComments =
            comments.skip(commentIndex).take(distribution.count).toList();
        commentIndex += distribution.count;

        final task = Task(
          id: '',
          type: 'comment',
          data: {
            'videoUrl': videoUrl,
            'action': 'comment',
            'comments': serverComments,
          },
          createdAt: DateTime.now(),
          status: 'pending',
          priority: isFirstTaskInAction ? TaskPriority.high : TaskPriority.normal,
          assignedTo: distribution.serverUid,
        );
        isFirstTaskInAction = false; // يتم تعيينها false بعد أول مهمة
        final taskId = await _taskService.createTask(task);
        if (taskId != null) {
          createdTaskIds.add(taskId);
        } else {
          throw Exception('Failed to create task');
        }
      }
      return createdTaskIds;
    } finally {
      _isCreatingTask = false;
    }
  }


  Future<List<String>> executeWatchTask(
    String videoUrl,
    int numberOfWatches,
  ) async {
    if (_isCreatingTask) return [];
    _isCreatingTask = true;
    try {
      final availableServers = await _getAllAvailableServers();
      if (availableServers.isEmpty) {
        throw Exception('No servers available at the moment');
      }

      final maxOperationsPerTask =
          await TaskCalculationService.calculateMaxWatchOperations();
      final taskSplits = _splitTasksByDuration(
        'watch',
        numberOfWatches,
        maxOperationsPerTask,
      );

      final createdTaskIds = <String>[];
      bool isFirstTaskInAction = true; // تعديل: متغير محلي
      for (final split in taskSplits) {
        final distributions = _distributeTasksAmongServers(
          availableServers,
          split.count,
          null,
        );

        for (final distribution in distributions) {
          final task = Task(
            id: '',
            type: 'watch',
            data: {
              'videoUrl': videoUrl,
              'action': 'watch',
              'numberOfWatches': distribution.count,
            },
            createdAt: DateTime.now(),
            status: 'pending',
            priority: isFirstTaskInAction ? TaskPriority.high : TaskPriority.normal,
            assignedTo: distribution.serverUid,
          );
          isFirstTaskInAction = false; // يتم تعيينها false بعد أول مهمة
          final taskId = await _taskService.createTask(task);
          if (taskId != null) {
            createdTaskIds.add(taskId);
          } else {
            throw Exception('Failed to create task');
          }
        }
      }
      return createdTaskIds;
    } finally {
      _isCreatingTask = false;
    }
  }
   Future<List<String>> executeShareTask(
    String videoUrl,
    int numberOfShares,
  ) async {
    if (_isCreatingTask) return [];
    _isCreatingTask = true;
    try {
      final availableServers = await _getAllAvailableServers();
      if (availableServers.isEmpty) throw Exception('No servers available');

      final maxOperationsPerTask =
          await TaskCalculationService.calculateMaxShareOperations();
      final taskSplits =
          _splitTasksByDuration('share', numberOfShares, maxOperationsPerTask);

      final createdTaskIds = <String>[];
      bool isFirstTaskInAction = true; // تعديل
      for (final split in taskSplits) {
        final distributions =
            _distributeTasksAmongServers(availableServers, split.count, null);
        for (final distribution in distributions) {
          final task = Task(
            id: '', type: 'share',
            data: {
              'videoUrl': videoUrl,
              'action': 'share',
              'numberOfShares': distribution.count
            },
            createdAt: DateTime.now(), status: 'pending',
            priority: isFirstTaskInAction ? TaskPriority.high : TaskPriority.normal,
            assignedTo: distribution.serverUid,
          );
          isFirstTaskInAction = false; // تعديل
          final taskId = await _taskService.createTask(task);
          if (taskId != null) createdTaskIds.add(taskId);
        }
      }
      return createdTaskIds;
    } finally {
      _isCreatingTask = false;
    }
  }

  Future<List<String>> executeLikeTask(
      String videoUrl, int numberOfLikes) async {
    if (_isCreatingTask) return [];
    _isCreatingTask = true;
    try {
      final availableServers = await _getAllAvailableServers();
      if (availableServers.isEmpty) throw Exception('No servers available');

      final createdTaskIds = <String>[];
      final distributions =
          _distributeTasksAmongServers(availableServers, numberOfLikes, 8);
      
      bool isFirstTaskInAction = true; // تعديل
      for (final distribution in distributions) {
        final task = Task(
            id: '', type: 'like',
            data: {
              'videoUrl': videoUrl,
              'action': 'like',
              'numberOfLikes': distribution.count
            },
            createdAt: DateTime.now(), status: 'pending',
            priority: isFirstTaskInAction ? TaskPriority.high : TaskPriority.normal,
            assignedTo: distribution.serverUid);
        isFirstTaskInAction = false; // تعديل
        final taskId = await _taskService.createTask(task);
        if (taskId != null) createdTaskIds.add(taskId);
      }
      return createdTaskIds;
    } finally {
      _isCreatingTask = false;
    }
  }

  Future<List<String>> executeFavoriteTask(
      String videoUrl, int numberOfFavorites) async {
    if (_isCreatingTask) return [];
    _isCreatingTask = true;
    try {
      final availableServers = await _getAllAvailableServers();
      if (availableServers.isEmpty) throw Exception('No servers available');

      final createdTaskIds = <String>[];
      final distributions =
          _distributeTasksAmongServers(availableServers, numberOfFavorites, 8);
      
      bool isFirstTaskInAction = true; // تعديل
      for (final distribution in distributions) {
        final task = Task(
            id: '', type: 'favorite',
            data: {
              'videoUrl': videoUrl,
              'action': 'favorite',
              'numberOfFavorites': distribution.count
            },
            createdAt: DateTime.now(), status: 'pending',
            priority: isFirstTaskInAction ? TaskPriority.high : TaskPriority.normal,
            assignedTo: distribution.serverUid);
        isFirstTaskInAction = false; // تعديل
        final taskId = await _taskService.createTask(task);
        if (taskId != null) createdTaskIds.add(taskId);
      }
      return createdTaskIds;
    } finally {
      _isCreatingTask = false;
    }
  }
  
  Future<List<String>> executeDirectMessageTask(
      List<String> usernames, String message, int numberOfAccounts) async {
    if (_isCreatingTask) return [];
    _isCreatingTask = true;
    try {
      final availableServers = await _getAllAvailableServers();
      if (availableServers.isEmpty) throw Exception('No servers available');

      final createdTaskIds = <String>[];
      final distributions =
          _distributeTasksAmongServers(availableServers, numberOfAccounts, 8);

      bool isFirstTaskInAction = true; // تعديل
      for (final distribution in distributions) {
        final task = Task(
            id: '', type: 'direct_message',
            data: {
              'action': 'direct_message',
              'usernames': usernames,
              'message': message,
              'numberOfAccounts': distribution.count,
            },
            createdAt: DateTime.now(), status: 'pending',
            priority: isFirstTaskInAction ? TaskPriority.high : TaskPriority.normal,
            assignedTo: distribution.serverUid);
        isFirstTaskInAction = false; // تعديل
        final taskId = await _taskService.createTask(task);
        if (taskId != null) createdTaskIds.add(taskId);
      }
      return createdTaskIds;
    } finally {
      _isCreatingTask = false;
    }
  }
}

/// Helper class for server distribution
class ServerDistribution {
  final String serverUid;
  final int count;

  ServerDistribution({required this.serverUid, required this.count});
}

/// Helper class for task splitting
class TaskSplit {
  final String taskType;
  final int count;

  TaskSplit({required this.taskType, required this.count});
}
