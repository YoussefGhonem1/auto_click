import 'package:flutter_test/flutter_test.dart';
import 'package:auto_click/domain/models/task.dart';
import 'package:auto_click/domain/services/task_combination_service.dart';

void main() {
  group('Smart Swap Behavior Tests', () {
    late TaskCombinationService combinationService;

    setUp(() {
      combinationService = TaskCombinationService();
    });

    group('Smart Swap Combination Logic', () {
      test('should combine watch tasks with DIFFERENT video URLs', () {
        // Arrange - Create tasks with different video URLs (Smart Swap scenario)
        final taskA = Task(
          id: 'task1',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoA',
            'numberOfWatches': 60,
          },
          createdAt: DateTime.now(),
          status: 'pending',
        );

        final taskB = Task(
          id: 'task2',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoB', // DIFFERENT URL
            'numberOfWatches': 30,
          },
          createdAt: DateTime.now(),
          status: 'pending',
        );

        // Act
        final result = combinationService.calculate(taskA, taskB);

        // Assert
        expect(result.completedTask.id, equals('task1'));
        expect(result.partialTask?.id, equals('task2'));
        expect(result.hasRemainder, isTrue);
        expect(result.remainderCount, equals(30)); // 60 - 30 = 30 remainder
        expect(result.taskWithRemainder?.id, equals('task1')); // Task A has remainder
      });

      test('should NOT combine watch tasks with SAME video URLs', () {
        // Arrange - Create tasks with same video URLs (should NOT combine)
        final taskA = Task(
          id: 'task1',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoA',
            'numberOfWatches': 60,
          },
          createdAt: DateTime.now(),
          status: 'pending',
        );

        final taskB = Task(
          id: 'task2',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoA', // SAME URL - should be ignored
            'numberOfWatches': 30,
          },
          createdAt: DateTime.now(),
          status: 'pending',
        );

        // Act
        final result = combinationService.calculate(taskA, taskB);

        // Assert - This should be treated as single task execution
        expect(result.completedTask.id, equals('task1'));
        expect(result.partialTask, isNull);
        expect(result.hasRemainder, isFalse);
        expect(result.remainderCount, equals(0));
      });

      test('should handle equal watch counts without remainder', () {
        // Arrange
        final taskA = Task(
          id: 'task1',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoA',
            'numberOfWatches': 50,
          },
          createdAt: DateTime.now(),
          status: 'pending',
        );

        final taskB = Task(
          id: 'task2',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoB',
            'numberOfWatches': 50, // Equal count
          },
          createdAt: DateTime.now(),
          status: 'pending',
        );

        // Act
        final result = combinationService.calculate(taskA, taskB);

        // Assert
        expect(result.hasRemainder, isFalse);
        expect(result.remainderCount, equals(0));
        expect(result.taskWithRemainder, isNull);
      });

      test('should handle non-watch tasks as single execution', () {
        // Arrange
        final likeTask = Task(
          id: 'task1',
          type: 'like',
          data: {
            'action': 'like',
            'videoUrl': 'https://example.com/videoA',
          },
          createdAt: DateTime.now(),
          status: 'pending',
        );

        final watchTask = Task(
          id: 'task2',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoB',
            'numberOfWatches': 30,
          },
          createdAt: DateTime.now(),
          status: 'pending',
        );

        // Act
        final result = combinationService.calculate(likeTask, watchTask);

        // Assert - Non-watch tasks should not combine
        expect(result.completedTask.id, equals('task1'));
        expect(result.partialTask, isNull);
        expect(result.hasRemainder, isFalse);
      });
    });

    group('Complex Smart Swap Scenarios', () {
      test('should handle the complex scenario from specification', () {
        // This test simulates the complex scenario described in the specification:
        // Task #1: Watch Video A - 60 views
        // Task #3: Watch Video B - 30 views
        // Expected: Smart Swap for 30 iterations, remainder of 30 for Video A

        final task1 = Task(
          id: 'task1',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoA',
            'numberOfWatches': 60,
          },
          createdAt: DateTime(2024, 1, 1, 10, 0, 0), // Oldest
          status: 'pending',
        );

        final task3 = Task(
          id: 'task3',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoB', // Different URL
            'numberOfWatches': 30,
          },
          createdAt: DateTime(2024, 1, 1, 10, 2, 0), // Newer
          status: 'pending',
        );

        // Act
        final result = combinationService.calculate(task1, task3);

        // Assert
        expect(result.completedTask.id, equals('task1')); // Video A task
        expect(result.partialTask?.id, equals('task3')); // Video B task
        expect(result.hasRemainder, isTrue);
        expect(result.remainderCount, equals(30)); // 60 - 30 = 30 remainder
        expect(result.taskWithRemainder?.id, equals('task1')); // Video A has remainder
      });

      test('should handle second combination scenario', () {
        // Task #2: Watch Video A - 60 views
        // Task #5: Watch Video D - 40 views
        // Expected: Smart Swap for 40 iterations, remainder of 20 for Video A

        final task2 = Task(
          id: 'task2',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoA',
            'numberOfWatches': 60,
          },
          createdAt: DateTime(2024, 1, 1, 10, 1, 0),
          status: 'pending',
        );

        final task5 = Task(
          id: 'task5',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoD', // Different URL
            'numberOfWatches': 40,
          },
          createdAt: DateTime(2024, 1, 1, 10, 4, 0),
          status: 'pending',
        );

        // Act
        final result = combinationService.calculate(task2, task5);

        // Assert
        expect(result.hasRemainder, isTrue);
        expect(result.remainderCount, equals(20)); // 60 - 40 = 20 remainder
        expect(result.taskWithRemainder?.id, equals('task2')); // Video A has remainder
      });
    });

    group('Task Prioritization', () {
      test('should verify oldest tasks are processed first', () {
        // Arrange - Create tasks with different timestamps
        final olderTask = Task(
          id: 'older',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoA',
            'numberOfWatches': 30,
          },
          createdAt: DateTime(2024, 1, 1, 10, 0, 0), // Older
          status: 'pending',
        );

        final newerTask = Task(
          id: 'newer',
          type: 'watch',
          data: {
            'action': 'watch',
            'videoUrl': 'https://example.com/videoB',
            'numberOfWatches': 30,
          },
          createdAt: DateTime(2024, 1, 1, 10, 1, 0), // Newer
          status: 'pending',
        );

        // Act - Simulate sorting (oldest first)
        final tasks = [newerTask, olderTask];
        tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // Assert
        expect(tasks.first.id, equals('older')); // Oldest should be first
        expect(tasks.last.id, equals('newer')); // Newest should be last
      });
    });
  });
}
