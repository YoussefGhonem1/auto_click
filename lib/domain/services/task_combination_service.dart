// lib/domain/services/task_combination_service.dart

import '../models/task.dart';

/// A helper class to hold the result of a task combination.
class CombinationResult {
  final Task completedTask; // The task that will be fully completed (the smaller one).
  final Task partialTask;   // The task that was larger and might have a remainder.
  final int remainderCount; // The number of remaining operations.
  final bool hasRemainder;  // A flag to check if there is a remainder.

  CombinationResult({
    required this.completedTask,
    required this.partialTask,
    required this.remainderCount,
    required this.hasRemainder,
  });
}

/// This service is responsible for calculating the result of combining two watch tasks.
class TaskCombinationService {
  CombinationResult calculate(Task task1, Task task2) {
    // **مهم:** تأكد من أن اسم الحقل هنا 'numberOfWatches' يطابق الاسم في قاعدة البيانات
    final count1 = task1.data['numberOfWatches'] as int? ?? 1;
    final count2 = task2.data['numberOfWatches'] as int? ?? 1;

    if (count1 <= count2) {
      return CombinationResult(
        completedTask: task1,
        partialTask: task2,
        remainderCount: count2 - count1,
        hasRemainder: count2 > count1,
      );
    } else {
      return CombinationResult(
        completedTask: task2,
        partialTask: task1,
        remainderCount: count1 - count2,
        hasRemainder: count1 > count2,
      );
    }
  }
}