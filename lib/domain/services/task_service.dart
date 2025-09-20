import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _tasksCollection = 'tasks';

  // Get stream of the latest task
  Stream<Task?> getLatestTaskStream() {
    return _firestore
        .collection(_tasksCollection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          return Task.fromMap(
            snapshot.docs.first.data(),
            snapshot.docs.first.id,
          );
        });
  }

  // Get all tasks
  Future<List<Task>> getAllTasks() async {
    try {
      final snapshot = await _firestore
          .collection(_tasksCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      final doc = await _firestore
          .collection(_tasksCollection)
          .doc(taskId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Task.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create a new task
  Future<String?> createTask(Task task) async {
    try {
      final docRef = await _firestore
          .collection(_tasksCollection)
          .add(task.toMap());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Update task status
  Future<bool> updateTaskStatus(String taskId, String status) async {
    try {
      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'status': status,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // update watch count
  Future<bool> updateWatchCount(String taskId, int count) async {
    try {
      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'data.numberOfWatches': count,
        'inProgress': true,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateDateTask(String taskId, DateTime date) async {
    try {
      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'createdAt': date.toIso8601String(),
      });
    } catch (e) {
      print('Error updating date task: $e');
    }
  }

  // Assign task to user
  Future<bool> assignTask(String taskId, String userId) async {
    try {
      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'assignedTo': userId,
        'status': 'assigned',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete task
  Future<bool> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_tasksCollection).doc(taskId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Stream of tasks with specific status
  Stream<List<Task>> getTasksByStatusStream(String status) {
    return _firestore
        .collection(_tasksCollection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Task.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Stream of tasks assigned to specific user
  Stream<List<Task>> getTasksByUserStream(String userId) {
    return _firestore
        .collection(_tasksCollection)
        .where('assignedTo', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Task.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // In lib/domain/services/task_service.dart
// Add this NEW function inside the TaskService class.

Future<void> createRemainderTask({
  required Task originalTask,
  required int remainingCount,
}) async {
  try {
    final newTaskData = originalTask.toMap();

    // Update fields for the new remainder task
    newTaskData['data']['numberOfWatches'] = remainingCount;
    newTaskData['status'] = 'pending';
    newTaskData['inProgress'] = false;
    // This is crucial: set a new timestamp to place it at the end of the queue
    newTaskData['createdAt'] = FieldValue.serverTimestamp();
    newTaskData['originalTaskId'] = originalTask.id;

    // Remove the old ID so Firestore generates a new one
    newTaskData.remove('id');

    await _firestore.collection(_tasksCollection).add(newTaskData);
  } catch (e) {
    print('Error creating remainder task: $e');
    rethrow;
  }
}
}
