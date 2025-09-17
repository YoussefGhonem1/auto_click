import 'dart:async';
import '../models/task.dart';
import 'reaction_service.dart';
import '../../data/repositories/automation_repository.dart';

class TaskExecutionService {
  final AutomationRepositoryInterface _repository;

  TaskExecutionService(this._repository);

  /// Execute a task based on its action type
  Future<bool> executeTask(Task task, [Task? other]) async {
    try {
      // Reload latest gesture configuration before executing task
      await ReactionService.reloadGlobalConfigurations();

      final action = task.data['action'] as String?;
      if (action == null) {
        throw Exception('Task action is missing');
      }

      // Get max task duration for timeout
      final maxDuration = await ReactionService.getMaxTaskDuration();

      // Execute task with timeout
      return await _executeTaskWithTimeout(task, action, maxDuration, other);
    } catch (e) {
      print('Task execution failed: $e');
      return false;
    }
  }

  /// Execute task with timeout using maxTaskDuration configuration
  Future<bool> _executeTaskWithTimeout(
    Task task,
    String action,
    int maxDuration, [
    Task? other,
  ]) async {
    try {
      // Execute the task with a timeout
      return await _executeTaskAction(task, action, other);
    } on TimeoutException catch (e) {
      print('Task execution timed out: $e');
      return false;
    } catch (e) {
      print('Task execution failed: $e');
      return false;
    }
  }

  /// Execute the actual task action
  Future<bool> _executeTaskAction(
    Task task,
    String action, [
    Task? other,
  ]) async {
    switch (action) {
      case 'like':
        return await _executeLikeReaction(task);
      case 'favorite':
        return await _executeFavoriteReaction(task);
      case 'share':
        return await _executeShareReaction(task);
      case 'comment':
        return await _executeCommentAction(task);
      case 'watch':
        if (other != null) {
          return await _executeCombinationWatchesAction(task, other);
        }
        return await _executeWatchAction(task);
      case 'direct_message':
        return await _executeDirectMessageAction(task);
      default:
        throw Exception('Unknown action type: $action');
    }
  }

  /// Execute like reaction using event sequence
  Future<bool> _executeLikeReaction(Task task) async {
    final videoUrl = task.data['videoUrl'] as String?;
    if (videoUrl == null) {
      throw Exception('Video URL is missing');
    }

    final events = await ReactionService.generateLikeReaction(
      videoUrl,
      task.data['numberOfLikes'] as int? ?? 1,
    );
    final eventMaps = events.map((e) => e.toJson()).toList();
    return await _repository.executeEventSequence(eventMaps);
  }

  /// Execute favorite reaction using event sequence
  Future<bool> _executeFavoriteReaction(Task task) async {
    final videoUrl = task.data['videoUrl'] as String?;
    if (videoUrl == null) {
      throw Exception('Video URL is missing');
    }

    final events = await ReactionService.generateFavoriteReaction(
      videoUrl,
      task.data['numberOfFavorites'] as int? ?? 1,
    );
    final eventMaps = events.map((e) => e.toJson()).toList();
    return await _repository.executeEventSequence(eventMaps);
  }

  /// Execute share reaction using event sequence
  Future<bool> _executeShareReaction(Task task) async {
    final videoUrl = task.data['videoUrl'] as String?;
    if (videoUrl == null) {
      throw Exception('Video URL is missing');
    }

    final events = await ReactionService.generateShareReaction(
      videoUrl,
      task.data['numberOfShares'] as int? ?? 1,
    );
    final eventMaps = events.map((e) => e.toJson()).toList();
    return await _repository.executeEventSequence(eventMaps);
  }

  /// Execute comment action using event sequence
  Future<bool> _executeCommentAction(Task task) async {
    final videoUrl = task.data['videoUrl'] as String?;
    final comments = task.data['comments'] as List<dynamic>?;

    if (videoUrl == null || comments == null || comments.isEmpty) {
      throw Exception('Video URL or comments are missing');
    }

    // Execute comments one by one
    final events = await ReactionService.generateMultipleCommentsReaction(
      videoUrl,
      comments.map((e) => "$e").toList(),
    );

    final eventMaps = events.map((e) => e.toJson()).toList();
    final success = await _repository.executeEventSequence(eventMaps);
    if (!success) {
      return false;
    }
    return true;
  }

  /// Execute watch action (opens video and waits)
  Future<bool> _executeWatchAction(Task task) async {
    final videoUrl = task.data['videoUrl'] as String?;

    if (videoUrl == null) {
      throw Exception('Video URL is missing');
    }
    final events = await ReactionService.generateWatchReaction(
      videoUrl,
      task.data['numberOfWatches'] as int? ?? 1,
    );
    final eventMaps = events.map((e) => e.toJson()).toList();
    return await _repository.executeEventSequence(eventMaps);
  }

  Future<bool> _executeCombinationWatchesAction(Task task, Task task2) async {
    final videoUrl = task.data['videoUrl'] as String?;
    final video2Url = task2.data['videoUrl'] as String?;

    if (videoUrl == null || video2Url == null) {
      throw Exception('Video URL is missing');
    }
    final events = await ReactionService.generateCombinationWatchesReaction(
      videoUrl,
      video2Url,
      task.data['numberOfWatches'] as int? ?? 1,
    );
    final eventMaps = events.map((e) => e.toJson()).toList();
    return await _repository.executeEventSequence(eventMaps);
  }

  /// Execute direct message action
  Future<bool> _executeDirectMessageAction(Task task) async {
    final usernames = task.data['usernames'] as List<dynamic>?;
    final message = task.data['message'] as String?;

    if (usernames == null || message == null || usernames.isEmpty) {
      throw Exception('Usernames or message are missing');
    }
    final events = await ReactionService.generateDirectMessageReaction(
      usernames.map((e) => "$e").toList(),
      message,
      1,
    );
    final eventMaps = events.map((e) => e.toJson()).toList();
    return await _repository.executeEventSequence(eventMaps);
  }

  /// Execute multiple reactions in sequence
  Future<bool> executeMultipleReactions(
    String videoUrl,
    List<String> reactions, {
    String? commentText,
  }) async {
    final events = await ReactionService.generateMultipleReactions(
      videoUrl,
      reactions,
      commentText: commentText,
    );
    final eventMaps = events.map((e) => e.toJson()).toList();
    return await _repository.executeEventSequence(eventMaps);
  }

  /// Reload gesture configurations to ensure latest settings are used
  Future<void> reloadGestureConfigurations() async {
    await ReactionService.reloadGlobalConfigurations();
  }
}
