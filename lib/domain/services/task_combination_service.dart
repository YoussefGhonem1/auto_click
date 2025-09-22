import '../models/task.dart';

/// Service for handling task combination logic and calculations
class TaskCombinationService {
  /// Calculate combination result for two watch tasks
  CombinationResult calculate(Task primaryTask, Task? partnerTask) {
    if (partnerTask == null || primaryTask.type != 'watch' || partnerTask.type != 'watch') {
      // No combination - single task execution
      return CombinationResult(
        completedTask: primaryTask,
        partialTask: null,
        hasRemainder: false,
        remainderCount: 0,
      );
    }

    final primaryWatches = primaryTask.data['numberOfWatches'] as int? ?? 1;
    final partnerWatches = partnerTask.data['numberOfWatches'] as int? ?? 1;
    final minWatches = primaryWatches < partnerWatches ? primaryWatches : partnerWatches;
    
    // Calculate remainder
    final primaryRemainder = primaryWatches - minWatches;
    final partnerRemainder = partnerWatches - minWatches;
    
    // Determine which task has the remainder
    Task? taskWithRemainder;
    int remainderCount = 0;
    
    if (primaryRemainder > 0) {
      taskWithRemainder = primaryTask;
      remainderCount = primaryRemainder;
    } else if (partnerRemainder > 0) {
      taskWithRemainder = partnerTask;
      remainderCount = partnerRemainder;
    }

    return CombinationResult(
      completedTask: primaryTask,
      partialTask: partnerTask,
      hasRemainder: remainderCount > 0,
      remainderCount: remainderCount,
      taskWithRemainder: taskWithRemainder,
    );
  }
}

/// Result of task combination calculation
class CombinationResult {
  final Task completedTask;
  final Task? partialTask;
  final bool hasRemainder;
  final int remainderCount;
  final Task? taskWithRemainder;

  const CombinationResult({
    required this.completedTask,
    this.partialTask,
    required this.hasRemainder,
    required this.remainderCount,
    this.taskWithRemainder,
  });
}