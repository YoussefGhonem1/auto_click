import 'gesture_config_service.dart';

/// Service to calculate the maximum number of repeat operations
/// that can be performed within the maxTaskDuration
class TaskCalculationService {
  static final GestureConfigService _configService = GestureConfigService();

  /// Calculate the maximum number of watch operations that can be performed
  /// within the maxTaskDuration
  static Future<int> calculateMaxWatchOperations() async {
    final durations = await _configService.loadDurations();

    final maxTaskDuration = durations['maxTaskDuration'] ?? 300000;
    final videoLoadTime = durations['videoLoadTime'] ?? 5000;
    final videoWatchTime = durations['videoWatchTime'] ?? 220;
    final swapDuration = durations['swapDuration'] ?? 10;
    final defaultWaitTime = durations['defaultWaitTime'] ?? 1000;

    // For watch operations:
    // - Initial load: videoLoadTime + videoWatchTime
    // - Each additional watch: swapDuration + videoWatchTime + swapDuration + defaultWaitTime
    // - Final refresh: ~2000ms (estimated)

    final initialTime = videoLoadTime + videoWatchTime;
    final additionalWatchTime =
        (swapDuration * 2) + videoWatchTime + defaultWaitTime;
    final refreshTime = 2000; // Estimated refresh time

    final availableTime = maxTaskDuration - initialTime - refreshTime;

    if (availableTime <= 0) {
      return 1; // Can only do 1 watch operation
    }

    final maxAdditionalWatches = availableTime ~/ additionalWatchTime;
    return 1 + maxAdditionalWatches; // Initial watch + additional watches
  }

  /// Calculate the maximum number of like operations that can be performed
  /// within the maxTaskDuration
  static Future<int> calculateMaxLikeOperations() async {
    final durations = await _configService.loadDurations();

    final maxTaskDuration = durations['maxTaskDuration'] ?? 300000;
    final videoLoadTime = durations['videoLoadTime'] ?? 5000;
    final defaultWaitTime = durations['defaultWaitTime'] ?? 1000;
    final switchAccountTime = durations['switchAccountTime'] ?? 5000;

    // For like operations:
    // - Initial like: videoLoadTime + defaultWaitTime
    // - Each additional like: switchAccountTime + videoLoadTime + defaultWaitTime
    // - Final refresh: ~2000ms (estimated)

    final initialTime = videoLoadTime + defaultWaitTime;
    final additionalLikeTime =
        switchAccountTime + videoLoadTime + defaultWaitTime;
    final refreshTime = 2000;

    final availableTime = maxTaskDuration - initialTime - refreshTime;

    if (availableTime <= 0) {
      return 1; // Can only do 1 like operation
    }

    final maxAdditionalLikes = availableTime ~/ additionalLikeTime;
    return 1 + maxAdditionalLikes; // Initial like + additional likes
  }

  /// Calculate the maximum number of favorite operations that can be performed
  /// within the maxTaskDuration
  static Future<int> calculateMaxFavoriteOperations() async {
    final durations = await _configService.loadDurations();

    final maxTaskDuration = durations['maxTaskDuration'] ?? 300000;
    final videoLoadTime = durations['videoLoadTime'] ?? 5000;
    final defaultWaitTime = durations['defaultWaitTime'] ?? 1000;
    final switchAccountTime = durations['switchAccountTime'] ?? 5000;

    // For favorite operations (same pattern as likes):
    // - Initial favorite: videoLoadTime + defaultWaitTime
    // - Each additional favorite: switchAccountTime + videoLoadTime + defaultWaitTime
    // - Final refresh: ~2000ms (estimated)

    final initialTime = videoLoadTime + defaultWaitTime;
    final additionalFavoriteTime =
        switchAccountTime + videoLoadTime + defaultWaitTime;
    final refreshTime = 2000;

    final availableTime = maxTaskDuration - initialTime - refreshTime;

    if (availableTime <= 0) {
      return 1; // Can only do 1 favorite operation
    }

    final maxAdditionalFavorites = availableTime ~/ additionalFavoriteTime;
    return 1 +
        maxAdditionalFavorites; // Initial favorite + additional favorites
  }

  /// Calculate the maximum number of share operations that can be performed
  /// within the maxTaskDuration
  static Future<int> calculateMaxShareOperations() async {
    final durations = await _configService.loadDurations();

    final maxTaskDuration = durations['maxTaskDuration'] ?? 300000;
    final videoLoadTime = durations['videoLoadTime'] ?? 5000;
    final defaultWaitTime = durations['defaultWaitTime'] ?? 1000;

    // For share operations:
    // - Initial setup: videoLoadTime
    // - Each share: (defaultWaitTime * 2) + (defaultWaitTime * 2) = defaultWaitTime * 4
    // - Final refresh: ~2000ms (estimated)

    final initialTime = videoLoadTime;
    final shareTime =
        defaultWaitTime * 4; // Click share + wait + click copy + wait
    final refreshTime = 3000;

    final availableTime = maxTaskDuration - initialTime - refreshTime;

    if (availableTime <= 0) {
      return 0; // Can't do any share operations
    }

    return availableTime ~/ shareTime;
  }

  /// Calculate the maximum number of comment operations that can be performed
  /// within the maxTaskDuration
  static Future<int> calculateMaxCommentOperations() async {
    final durations = await _configService.loadDurations();

    final maxTaskDuration = durations['maxTaskDuration'] ?? 300000;

    // For comment operations:
    // - Initial setup: videoLoadTime + (defaultWaitTime * 2) + (defaultWaitTime * 2) + defaultWaitTime + (defaultWaitTime * 2) + defaultWaitTime
    // - Each comment: ~8000ms (estimated total time for comment operation)
    // - Final refresh: ~2000ms (estimated)

    final commentTime = 8000; // Estimated time for one comment operation
    final refreshTime = 2000;

    final availableTime = maxTaskDuration - refreshTime;

    if (availableTime <= 0) {
      return 0; // Can't do any comment operations
    }

    return availableTime ~/ commentTime;
  }

  /// Calculate the maximum number of direct message operations that can be performed
  /// within the maxTaskDuration
  /// [numberOfAccounts] is the number of accounts that will be sending messages (1-8)
  static Future<int> calculateMaxDirectMessageOperations({
    int numberOfAccounts = 1,
  }) async {
    final durations = await _configService.loadDurations();

    final maxTaskDuration = durations['maxTaskDuration'] ?? 300000;
    final videoLoadTime = durations['videoLoadTime'] ?? 5000;
    final defaultWaitTime = durations['defaultWaitTime'] ?? 1000;

    // For direct message operations:
    // - Each DM per account: videoLoadTime + (defaultWaitTime * 2) + (defaultWaitTime * 2) + defaultWaitTime + (defaultWaitTime * 2) + defaultWaitTime
    // - Pattern: Load profile → Click DM → Wait → Click field → Wait → Type message → Wait → Dismiss keyboard → Wait → Click send → Wait
    // - Final refresh: ~2000ms (estimated)

    final dmPerAccountTime =
        videoLoadTime + (defaultWaitTime * 8); // ~13000ms per account
    final refreshTime = 2000;

    final availableTime = maxTaskDuration - refreshTime;

    if (availableTime <= 0) {
      return 0; // Can't do any DM operations
    }

    // Calculate how many complete rounds of all accounts can be done
    final totalTimePerRound = dmPerAccountTime * numberOfAccounts;
    final maxRounds = availableTime ~/ totalTimePerRound;

    return maxRounds;
  }

  /// Calculate the maximum number of operations for a specific task type
  /// [numberOfAccounts] is used for direct_message operations (1-8)
  static Future<int> calculateMaxOperationsForTaskType(
    String taskType, {
    int numberOfAccounts = 1,
  }) async {
    switch (taskType.toLowerCase()) {
      case 'watch':
        return await calculateMaxWatchOperations();
      case 'like':
        return await calculateMaxLikeOperations();
      case 'favorite':
        return await calculateMaxFavoriteOperations();
      case 'share':
        return await calculateMaxShareOperations();
      case 'comment':
        return await calculateMaxCommentOperations();
      case 'direct_message':
        return await calculateMaxDirectMessageOperations(
          numberOfAccounts: numberOfAccounts,
        );
      default:
        return 1; // Default to 1 for unknown task types
    }
  }

  /// Get a summary of maximum operations for all task types
  /// [numberOfAccounts] is used for direct_message operations (1-8)
  static Future<Map<String, int>> getAllMaxOperations({
    int numberOfAccounts = 1,
  }) async {
    return {
      'watch': await calculateMaxWatchOperations(),
      'like': await calculateMaxLikeOperations(),
      'favorite': await calculateMaxFavoriteOperations(),
      'share': await calculateMaxShareOperations(),
      'comment': await calculateMaxCommentOperations(),
      'direct_message': await calculateMaxDirectMessageOperations(
        numberOfAccounts: numberOfAccounts,
      ),
    };
  }

  /// Check if a given number of operations is within the maxTaskDuration limit
  /// [numberOfAccounts] is used for direct_message operations (1-8)
  static Future<bool> isOperationCountWithinLimit(
    String taskType,
    int operationCount, {
    int numberOfAccounts = 1,
  }) async {
    final maxOperations = await calculateMaxOperationsForTaskType(
      taskType,
      numberOfAccounts: numberOfAccounts,
    );
    return operationCount <= maxOperations;
  }

  /// Get the recommended maximum operations for a task type
  /// This considers both the time limit and practical limits
  /// [numberOfAccounts] is used for direct_message operations (1-8)
  static Future<int> getRecommendedMaxOperations(
    String taskType, {
    int numberOfAccounts = 1,
  }) async {
    final maxByTime = await calculateMaxOperationsForTaskType(
      taskType,
      numberOfAccounts: numberOfAccounts,
    );

    // Apply practical limits based on task type
    switch (taskType.toLowerCase()) {
      case 'watch':
        return maxByTime; // No practical limit for watches
      case 'like':
      case 'favorite':
        return maxByTime > 8 ? 8 : maxByTime; // Max 8 per server
      case 'share':
        return maxByTime; // No practical limit for shares
      case 'comment':
        return maxByTime > 8 ? 8 : maxByTime; // Max 8 per server
      case 'direct_message':
        return maxByTime > 8 ? 8 : maxByTime; // Max 8 per server
      default:
        return maxByTime;
    }
  }
}
