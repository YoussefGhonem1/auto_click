import '../../domain/services/task_calculation_service.dart';

/// Controller for validating task operation counts before creation
class TaskValidationController {
  /// Validate if the requested number of operations is within the time limit
  /// Returns a validation result with details
  /// [numberOfAccounts] is used for direct_message operations (1-8)
  static Future<TaskValidationResult> validateOperationCount(
    String taskType,
    int requestedCount, {
    int numberOfAccounts = 1,
  }) async {
    final maxOperations =
        await TaskCalculationService.calculateMaxOperationsForTaskType(
          taskType,
          numberOfAccounts: numberOfAccounts,
        );
    final recommendedMax =
        await TaskCalculationService.getRecommendedMaxOperations(
          taskType,
          numberOfAccounts: numberOfAccounts,
        );

    final isValid = requestedCount <= maxOperations;
    final isWithinRecommended = requestedCount <= recommendedMax;

    return TaskValidationResult(
      isValid: isValid,
      isWithinRecommended: isWithinRecommended,
      requestedCount: requestedCount,
      maxByTime: maxOperations,
      recommendedMax: recommendedMax,
      taskType: taskType,
    );
  }

  /// Validate multiple task types at once
  /// [numberOfAccounts] is used for direct_message operations (1-8)
  static Future<Map<String, TaskValidationResult>> validateMultipleTasks(
    Map<String, int> taskRequests, {
    int numberOfAccounts = 1,
  }) async {
    final results = <String, TaskValidationResult>{};

    for (final entry in taskRequests.entries) {
      final taskType = entry.key;
      final count = entry.value;

      results[taskType] = await validateOperationCount(
        taskType,
        count,
        numberOfAccounts: numberOfAccounts,
      );
    }

    return results;
  }

  /// Get validation suggestions for a task type
  /// [numberOfAccounts] is used for direct_message operations (1-8)
  static Future<TaskValidationSuggestion> getValidationSuggestion(
    String taskType,
    int requestedCount, {
    int numberOfAccounts = 1,
  }) async {
    final validation = await validateOperationCount(
      taskType,
      requestedCount,
      numberOfAccounts: numberOfAccounts,
    );

    if (validation.isValid) {
      return TaskValidationSuggestion(
        isValid: true,
        message: 'Operation count is within limits',
        suggestion: null,
      );
    } else {
      final suggestion = validation.recommendedMax > 0
          ? 'Consider reducing to ${validation.recommendedMax} operations'
          : 'This task type cannot be performed within the time limit';

      return TaskValidationSuggestion(
        isValid: false,
        message: 'Operation count exceeds time limit',
        suggestion: suggestion,
      );
    }
  }

  /// Get a summary of all available task types and their limits
  /// [numberOfAccounts] is used for direct_message operations (1-8)
  static Future<TaskLimitsSummary> getTaskLimitsSummary({int numberOfAccounts = 1}) async {
    final allMaxOperations = await TaskCalculationService.getAllMaxOperations(numberOfAccounts: numberOfAccounts);

    final limits = <String, TaskLimitInfo>{};

    for (final entry in allMaxOperations.entries) {
      final taskType = entry.key;
      final maxByTime = entry.value;
      final recommended =
          await TaskCalculationService.getRecommendedMaxOperations(
            taskType,
            numberOfAccounts: numberOfAccounts,
          );

      limits[taskType] = TaskLimitInfo(
        taskType: taskType,
        maxByTime: maxByTime,
        recommendedMax: recommended,
        isLimitedByTime: maxByTime < recommended,
      );
    }

    return TaskLimitsSummary(limits: limits);
  }
}

/// Result of task validation
class TaskValidationResult {
  final bool isValid;
  final bool isWithinRecommended;
  final int requestedCount;
  final int maxByTime;
  final int recommendedMax;
  final String taskType;

  TaskValidationResult({
    required this.isValid,
    required this.isWithinRecommended,
    required this.requestedCount,
    required this.maxByTime,
    required this.recommendedMax,
    required this.taskType,
  });

  /// Get a user-friendly message about the validation result
  String get message {
    if (isValid) {
      if (isWithinRecommended) {
        return 'Operation count is within recommended limits';
      } else {
        return 'Operation count is within time limit but exceeds recommended limit';
      }
    } else {
      return 'Operation count exceeds time limit';
    }
  }

  /// Get a suggestion for the user
  String? get suggestion {
    if (isValid) {
      return null;
    } else {
      if (recommendedMax > 0) {
        return 'Consider reducing to $recommendedMax operations';
      } else {
        return 'This task type cannot be performed within the time limit';
      }
    }
  }
}

/// Suggestion for task validation
class TaskValidationSuggestion {
  final bool isValid;
  final String message;
  final String? suggestion;

  TaskValidationSuggestion({
    required this.isValid,
    required this.message,
    this.suggestion,
  });
}

/// Information about task limits
class TaskLimitInfo {
  final String taskType;
  final int maxByTime;
  final int recommendedMax;
  final bool isLimitedByTime;

  TaskLimitInfo({
    required this.taskType,
    required this.maxByTime,
    required this.recommendedMax,
    required this.isLimitedByTime,
  });
}

/// Summary of all task limits
class TaskLimitsSummary {
  final Map<String, TaskLimitInfo> limits;

  TaskLimitsSummary({required this.limits});

  /// Get a formatted string representation
  String get formattedSummary {
    final buffer = StringBuffer();
    buffer.writeln('Task Limits Summary:');
    buffer.writeln('===================');

    limits.forEach((taskType, info) {
      buffer.writeln('$taskType:');
      buffer.writeln('  Max by time: ${info.maxByTime}');
      buffer.writeln('  Recommended: ${info.recommendedMax}');
      buffer.writeln('  Limited by time: ${info.isLimitedByTime}');
      buffer.writeln('');
    });

    return buffer.toString();
  }
}
