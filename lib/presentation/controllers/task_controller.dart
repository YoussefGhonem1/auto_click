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

  /// Distribute tasks among servers with consideration for max operations per task
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
      if (i == 0) {
        count += remainder;
      }
      // Respect maxPerServer if specified
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

  /// Create and distribute comment tasks among servers
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

      final List<String> createdTaskIds = [];

      // Distribute comments among servers
      final distributions = _distributeTasksAmongServers(
        availableServers,
        comments.length,
        8, // Max 8 comments per server
      );

      int commentIndex = 0;
      for (final distribution in distributions) {
        final serverComments = comments
            .skip(commentIndex)
            .take(distribution.count)
            .toList();
        commentIndex += distribution.count;

        final task = Task(
          id: '', // Firestore will generate the ID
          type: 'comment',
          data: {
            'videoUrl': videoUrl,
            'action': 'comment',
            'comments': serverComments,
          },
          createdAt: DateTime.now(),
          status: 'pending',
          assignedTo: distribution.serverUid,
        );

        final taskId = await _taskService.createTask(task);
        if (taskId != null) {
          createdTaskIds.add(taskId);
        } else {
          throw Exception('Failed to create task');
        }
      }

      return createdTaskIds;
    } catch (e) {
      rethrow;
    } finally {
      _isCreatingTask = false;
    }
  }

  /// Create and distribute watch tasks among servers with duration consideration
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

      // Get max operations per task for watches
      final maxOperationsPerTask =
          await TaskCalculationService.calculateMaxWatchOperations();

      // Split tasks if they exceed maxTaskDuration
      final taskSplits = _splitTasksByDuration(
        'watch',
        numberOfWatches,
        maxOperationsPerTask,
      );

      final List<String> createdTaskIds = [];

      for (final split in taskSplits) {
        // Distribute this split among servers
        final distributions = _distributeTasksAmongServers(
          availableServers,
          split.count,
          null, // No max limit for watches
        );

        for (final distribution in distributions) {
          final task = Task(
            id: '', // Firestore will generate the ID
            type: 'watch',
            data: {
              'videoUrl': videoUrl,
              'action': 'watch',
              'numberOfWatches': distribution.count,
            },
            createdAt: DateTime.now(),
            status: 'pending',
            assignedTo: distribution.serverUid,
          );

          final taskId = await _taskService.createTask(task);
          if (taskId != null) {
            createdTaskIds.add(taskId);
          } else {
            throw Exception('Failed to create task');
          }
        }
      }

      return createdTaskIds;
    } catch (e) {
      rethrow;
    } finally {
      _isCreatingTask = false;
    }
  }

  /// Create and distribute share tasks among servers with duration consideration
  Future<List<String>> executeShareTask(
    String videoUrl,
    int numberOfShares,
  ) async {
    if (_isCreatingTask) return [];

    _isCreatingTask = true;

    try {
      final availableServers = await _getAllAvailableServers();
      if (availableServers.isEmpty) {
        throw Exception('No servers available at the moment');
      }

      // Get max operations per task for shares
      final maxOperationsPerTask =
          await TaskCalculationService.calculateMaxShareOperations();

      // Split tasks if they exceed maxTaskDuration
      final taskSplits = _splitTasksByDuration(
        'share',
        numberOfShares,
        maxOperationsPerTask,
      );

      final List<String> createdTaskIds = [];

      for (final split in taskSplits) {
        // Distribute this split among servers
        final distributions = _distributeTasksAmongServers(
          availableServers,
          split.count,
          null, // No max limit for shares
        );

        for (final distribution in distributions) {
          final task = Task(
            id: '', // Firestore will generate the ID
            type: 'share',
            data: {
              'videoUrl': videoUrl,
              'action': 'share',
              'numberOfShares': distribution.count,
            },
            createdAt: DateTime.now(),
            status: 'pending',
            assignedTo: distribution.serverUid,
          );

          final taskId = await _taskService.createTask(task);
          if (taskId != null) {
            createdTaskIds.add(taskId);
          } else {
            throw Exception('Failed to create task');
          }
        }
      }

      return createdTaskIds;
    } catch (e) {
      rethrow;
    } finally {
      _isCreatingTask = false;
    }
  }

  /// Create and distribute like tasks among servers
  Future<List<String>> executeLikeTask(
    String videoUrl,
    int numberOfLikes,
  ) async {
    if (_isCreatingTask) return [];

    _isCreatingTask = true;

    try {
      final availableServers = await _getAllAvailableServers();
      if (availableServers.isEmpty) {
        throw Exception('No servers available at the moment');
      }

      final List<String> createdTaskIds = [];

      // Distribute likes among servers
      final distributions = _distributeTasksAmongServers(
        availableServers,
        numberOfLikes,
        8, // Max 8 likes per server
      );

      for (final distribution in distributions) {
        final task = Task(
          id: '', // Firestore will generate the ID
          type: 'like',
          data: {
            'videoUrl': videoUrl,
            'action': 'like',
            'numberOfLikes': distribution.count,
          },
          createdAt: DateTime.now(),
          status: 'pending',
          assignedTo: distribution.serverUid,
        );

        final taskId = await _taskService.createTask(task);
        if (taskId != null) {
          createdTaskIds.add(taskId);
        } else {
          throw Exception('Failed to create task');
        }
      }

      return createdTaskIds;
    } catch (e) {
      rethrow;
    } finally {
      _isCreatingTask = false;
    }
  }

  /// Create and distribute favorite tasks among servers
  Future<List<String>> executeFavoriteTask(
    String videoUrl,
    int numberOfFavorites,
  ) async {
    if (_isCreatingTask) return [];

    _isCreatingTask = true;

    try {
      final availableServers = await _getAllAvailableServers();
      if (availableServers.isEmpty) {
        throw Exception('No servers available at the moment');
      }

      final List<String> createdTaskIds = [];

      // Distribute favorites among servers
      final distributions = _distributeTasksAmongServers(
        availableServers,
        numberOfFavorites,
        8, // Max 8 favorites per server
      );

      for (final distribution in distributions) {
        final task = Task(
          id: '', // Firestore will generate the ID
          type: 'favorite',
          data: {
            'videoUrl': videoUrl,
            'action': 'favorite',
            'numberOfFavorites': distribution.count,
          },
          createdAt: DateTime.now(),
          status: 'pending',
          assignedTo: distribution.serverUid,
        );

        final taskId = await _taskService.createTask(task);
        if (taskId != null) {
          createdTaskIds.add(taskId);
        } else {
          throw Exception('Failed to create task');
        }
      }

      return createdTaskIds;
    } catch (e) {
      rethrow;
    } finally {
      _isCreatingTask = false;
    }
  }

  /// Create and distribute direct message tasks among servers
  Future<List<String>> executeDirectMessageTask(
    List<String> usernames,
    String message,
    int numberOfAccounts,
  ) async {
    if (_isCreatingTask) return [];

    _isCreatingTask = true;

    try {
      final availableServers = await _getAllAvailableServers();
      if (availableServers.isEmpty) {
        throw Exception('No servers available at the moment');
      }

      final List<String> createdTaskIds = [];

      // Distribute accounts among servers
      final distributions = _distributeTasksAmongServers(
        availableServers,
        numberOfAccounts,
        8, // Max 8 accounts per server
      );

      for (final distribution in distributions) {
        final task = Task(
          id: '', // Firestore will generate the ID
          type: 'direct_message',
          data: {
            'action': 'direct_message',
            'usernames': usernames,
            'message': message,
            'numberOfAccounts': distribution.count,
          },
          createdAt: DateTime.now(),
          status: 'pending',
          assignedTo: distribution.serverUid,
        );

        final taskId = await _taskService.createTask(task);
        if (taskId != null) {
          createdTaskIds.add(taskId);
        } else {
          throw Exception('Failed to create task');
        }
      }

      return createdTaskIds;
    } catch (e) {
      rethrow;
    } finally {
      _isCreatingTask = false;
    }
  }

  /// Create simple URL-based tasks for all available servers
  Future<List<String>> executeTaskWithUrl(
    String taskType,
    String videoUrl,
  ) async {
    if (_isCreatingTask) return [];

    _isCreatingTask = true;

    try {
      final availableServers = await _getAllAvailableServers();
      if (availableServers.isEmpty) {
        throw Exception('No servers available at the moment');
      }

      final List<String> createdTaskIds = [];

      // Create one task per server for simple URL-based tasks
      for (final serverUid in availableServers) {
        final task = Task(
          id: '',
          type: taskType,
          data: {'videoUrl': videoUrl, 'action': taskType},
          createdAt: DateTime.now(),
          status: 'pending',
          assignedTo: serverUid,
        );

        final taskId = await _taskService.createTask(task);
        if (taskId != null) {
          createdTaskIds.add(taskId);
        } else {
          throw Exception('Failed to create task');
        }
      }

      return createdTaskIds;
    } catch (e) {
      rethrow;
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
