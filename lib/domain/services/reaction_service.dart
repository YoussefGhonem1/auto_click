import 'dart:math';

import '../models/automation_event.dart';
import '../../data/data_sources/local_datasource/gesture_positions.dart';
import 'gesture_config_service.dart';
import 'tiktok_links_service.dart';

class ReactionService {
  static final GestureConfigService _configService = GestureConfigService();
  static final TikTokLinksService _tikTokLinksService =
      TikTokLinksService.instance;

  // Cache for loaded configurations
  static Map<String, dynamic>? _cachedPositions;
  static Map<String, int>? _cachedDurations;

  /// Load configurations if not cached
  static Future<void> _ensureConfigLoaded() async {
    // if (_cachedPositions == null || _cachedDurations == null) {
    await _loadConfigurations();
    // }
  }

  /// Load configurations from GestureConfigService (respects user preferences)
  static Future<void> _loadConfigurations() async {
    try {
      _cachedPositions = await _configService.loadGesturePositions();
      _cachedDurations = await _configService.loadDurations();
    } catch (e) {
      // Fallback to defaults if loading fails
      _cachedPositions = Map<String, dynamic>.from(defaultGesturePositions);
      _cachedDurations = {
        'defaultWaitTime': defaultWaitTime,
        'videoLoadTime': videoLoadTime,
        'videoWatchTime': videoWatchTime,
        'switchAccountTime': switchAccountTime,
        'swapDuration': swapTime,
        'maxTaskDuration': maxTaskDuration,
      };
    }
  }

  /// Get duration value with configuration fallback
  static int _getDuration(String key) {
    if (_cachedDurations != null && _cachedDurations!.containsKey(key)) {
      return _cachedDurations![key]!;
    }

    // Fallback to defaults
    switch (key) {
      case 'defaultWaitTime':
        return defaultWaitTime;
      case 'videoLoadTime':
        return videoLoadTime;
      case 'videoWatchTime':
        return videoWatchTime;
      case 'switchAccountTime':
        return switchAccountTime;
      case 'swapDuration':
        return swapTime;
      case 'maxTaskDuration':
        return maxTaskDuration;
      default:
        return defaultWaitTime;
    }
  }

  /// Get the maximum task duration from configuration
  static Future<int> getMaxTaskDuration() async {
    await _ensureConfigLoaded();
    return _getDuration('maxTaskDuration');
  }

  /// Get a random TikTok URL or use the provided videoUrl as fallback
  static String _getVideoUrl() {
    // Try to get a random URL from the TikTok links service
    final randomUrl = _tikTokLinksService.getRandomTikTokUrl();
    if (randomUrl != null && randomUrl.isNotEmpty) {
      return randomUrl;
    }

    // Fallback to the default URL if no links are available
    return "https://vt.tiktok.com/ZSBbKtJLv/";
  }

  static Future<List<AutomationEvent>> generateWatchReaction(
    String videoUrl,
    int numberOfWatches,
  ) async {
    await _ensureConfigLoaded();

    final (x, y) = await getPosition('gesture_up', 'start');
    final (x2, y2) = await getPosition('gesture_up', 'end');

    // Get the video URL to use (random from list or provided URL)
    final urlToUse = _getVideoUrl();

    List<AutomationEvent> events = [
      AutomationEvent.openUrl(urlToUse),
      AutomationEvent.wait(_getDuration('videoLoadTime')),
      AutomationEvent.openUrl(videoUrl),
      AutomationEvent.wait(
        _getDuration('videoLoadTime') + _getDuration('videoWatchTime'),
      ),
    ];
    for (var i = 0; i < numberOfWatches - 1; i++) {
      events.addAll([
        AutomationEvent.swap(x2, y2, x, y, _getDuration('swapDuration')),
        AutomationEvent.wait(_getDuration('videoWatchTime')),
        AutomationEvent.swap(x, y, x2, y2, _getDuration('swapDuration')),
        AutomationEvent.wait(_getDuration('videoWatchTime')),
      ]);
    }

    events.addAll(await refreshApp());
    return events;
  }

  static Future<List<AutomationEvent>> generateCombinationWatchesReaction(
    String videoUrl,
    String video2Url,
    int numberOfWatches,
  ) async {
    await _ensureConfigLoaded();

    final (x, y) = await getPosition('gesture_up', 'start');
    final (x2, y2) = await getPosition('gesture_up', 'end');

    // Get a warm-up video URL (same as in normal watch reaction)
    final warmupUrl = _getVideoUrl();

    List<AutomationEvent> events = [
      // Open warm-up video first to initialize the app properly
      AutomationEvent.openUrl(warmupUrl),
      AutomationEvent.wait(1000),
      // Now open the first target video
      AutomationEvent.openUrl(videoUrl),
      AutomationEvent.wait(
        _getDuration('videoLoadTime') + _getDuration('videoWatchTime'),
      ),
      AutomationEvent.openUrl(video2Url),
      AutomationEvent.wait(
        _getDuration('videoLoadTime') + _getDuration('videoWatchTime'),
      ),
    ];
    for (var i = 0; i < numberOfWatches - 1; i++) {
      events.addAll([
        AutomationEvent.swap(x2, y2, x, y, _getDuration('swapDuration')),
        AutomationEvent.wait(_getDuration('videoWatchTime')),
        AutomationEvent.swap(x, y, x2, y2, _getDuration('swapDuration')),
        AutomationEvent.wait(_getDuration('videoWatchTime')),
      ]);
    }

    events.addAll(await refreshApp());
    return events;
  }

  /// Generate event sequence for like reaction
  static Future<List<AutomationEvent>> generateLikeReaction(
    String videoUrl,
    int numberOfLikes,
  ) async {
    await _ensureConfigLoaded();

    final (x, y) = await getPosition('like_button');

    final warmupUrl = _getVideoUrl();

    var events = <AutomationEvent>[
      AutomationEvent.openUrl(warmupUrl),
      AutomationEvent.wait(1000),
      AutomationEvent.openUrl(videoUrl),
      AutomationEvent.wait(_getDuration('videoLoadTime')),
      AutomationEvent.click(x, y),
      AutomationEvent.wait(_getDuration('defaultWaitTime')),
    ];

    for (var i = 1; i < numberOfLikes; i++) {
      events.addAll([
        ...await switchAccount(i),
        AutomationEvent.openUrl(videoUrl),
        AutomationEvent.wait(_getDuration('videoLoadTime')),
        AutomationEvent.click(x, y),
        AutomationEvent.wait(_getDuration('defaultWaitTime')),
      ]);
    }

    events.addAll(await refreshApp());
    return events;
  }

  /// Generate event sequence for favorite reaction
  static Future<List<AutomationEvent>> generateFavoriteReaction(
    String videoUrl,
    int numberOfFavorites,
  ) async {
    await _ensureConfigLoaded();

    final (x, y) = await getPosition('favorite_button');

    final warmupUrl = _getVideoUrl();

    var events = [
      AutomationEvent.openUrl(warmupUrl),
      AutomationEvent.wait(2000),
      AutomationEvent.openUrl(videoUrl),
      AutomationEvent.wait(_getDuration('videoLoadTime')),
      AutomationEvent.click(x, y),
      AutomationEvent.wait(_getDuration('defaultWaitTime')),
    ];

    for (var i = 1; i < numberOfFavorites; i++) {
      events.addAll([
        ...await switchAccount(i),
        AutomationEvent.openUrl(videoUrl),
        AutomationEvent.wait(_getDuration('videoLoadTime')),
        AutomationEvent.click(x, y),
        AutomationEvent.wait(_getDuration('defaultWaitTime')),
      ]);
    }

    events.addAll(await refreshApp());
    return events;
  }

  /// Generate event sequence for share reaction
  static Future<List<AutomationEvent>> generateShareReaction(
    String videoUrl,
    int numberOfShares,
  ) async {
    await _ensureConfigLoaded();

    final (x, y) = await getPosition('share_button');
    final (copyX, copyY) = await getPosition('copy_link_button');

    final warmupUrl = _getVideoUrl();

    List<AutomationEvent> events = [
      AutomationEvent.openUrl(warmupUrl),
      AutomationEvent.wait(2000),
      AutomationEvent.openUrl(videoUrl),
      AutomationEvent.wait(_getDuration('videoLoadTime')),
    ];

    for (var i = 0; i < numberOfShares; i++) {
      events.addAll([
        AutomationEvent.click(x, y),
        AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
        AutomationEvent.click(copyX, copyY),
        AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
      ]);
    }

    events.addAll(await refreshApp());
    return events;
  }

  /// Generate event sequence for comment reaction
  static Future<List<AutomationEvent>> generateCommentReaction(
    String videoUrl,
    String commentText,
  ) async {
    await _ensureConfigLoaded();

    final (commentX, commentY) = await getPosition('comment_button');
    final (fieldX, fieldY) = await getPosition('comment_field');
    final (sendX, sendY) = await getPosition('send_comment_button');

    return [
      AutomationEvent.openUrl(videoUrl),
      AutomationEvent.wait(_getDuration('videoLoadTime')),
      AutomationEvent.click(commentX, commentY),
      AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
      AutomationEvent.click(fieldX, fieldY),
      AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
      AutomationEvent.write(commentText),
      AutomationEvent.wait(_getDuration('defaultWaitTime')),
      AutomationEvent.dismissKeyboard(),
      AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
      AutomationEvent.click(sendX, sendY),
      AutomationEvent.wait(_getDuration('defaultWaitTime')),
      ...await refreshApp(),
    ];
  }

  /// Generate event sequence for follow reaction
  static Future<List<AutomationEvent>> generateFollowReaction(
    String videoUrl,
    int numberOfFollows,
  ) async {
    await _ensureConfigLoaded();

    final (x, y) = await getPosition('follow_button');

    var events = <AutomationEvent>[
      AutomationEvent.openUrl(videoUrl),
      AutomationEvent.wait(_getDuration('videoLoadTime')),
      AutomationEvent.click(x, y),
      AutomationEvent.wait(_getDuration('defaultWaitTime')),
    ];

    for (var i = 1; i < numberOfFollows; i++) {
      events.addAll([
        ...await switchAccount(i),
        AutomationEvent.openUrl(videoUrl),
        AutomationEvent.wait(_getDuration('videoLoadTime')),
        AutomationEvent.click(x, y),
        AutomationEvent.wait(_getDuration('defaultWaitTime')),
      ]);
    }

    events.addAll(await refreshApp());
    return events;
  }

  /// Generate event sequence for multiple reactions
  static Future<List<AutomationEvent>> generateMultipleReactions(
    String videoUrl,
    List<String> actions, {
    int numberOfReactions = 1,
    String? commentText,
  }) async {
    await _ensureConfigLoaded();

    List<AutomationEvent> events = [];

    for (var i = 0; i < numberOfReactions; i++) {
      for (var action in actions) {
        switch (action) {
          case 'like':
            events.addAll(await generateLikeReaction(videoUrl, 1));
            break;
          case 'favorite':
            events.addAll(await generateFavoriteReaction(videoUrl, 1));
            break;
          case 'share':
            events.addAll(await generateShareReaction(videoUrl, 1));
            break;
          case 'follow':
            events.addAll(await generateFollowReaction(videoUrl, 1));
            break;
          case 'watch':
            events.addAll(await generateWatchReaction(videoUrl, 1));
            break;
          case 'comment':
            if (commentText != null) {
              events.addAll(
                await generateCommentReaction(videoUrl, commentText),
              );
            }
            break;
        }
      }
    }

    events.addAll(await refreshApp());
    return events;
  }

  /// Generate event sequence for switching account
  static Future<List<AutomationEvent>> switchAccount(int accountIndex) async {
    await _ensureConfigLoaded();

    final (x, y) = await getPosition('profile_button');
    final (currentX, currentY) = await getPosition('current_account_username');
    final (accountX, accountY) = await getAccountPosition(accountIndex);

    return [
      AutomationEvent.wait(_getDuration('defaultWaitTime') * 3),
      AutomationEvent.click(x, y),
      AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
      AutomationEvent.click(currentX, currentY),
      AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
      AutomationEvent.click(accountX, accountY),
      AutomationEvent.wait(_getDuration('switchAccountTime')),
    ];
  }

  /// Get position value from cached configuration
  ///
  /// Throws [Exception] if position is not found
  static Future<(double, double)> getPosition(
    String key, [
    String? subKey,
  ]) async {
    await _ensureConfigLoaded();

    dynamic positionData;

    // Try to get from cached positions first
    if (_cachedPositions != null) {
      positionData = _cachedPositions![key];
    }

    // Fallback to defaults if not found in cache
    if (positionData == null) {
      positionData = defaultGesturePositions[key];
      if (positionData == null) {
        throw Exception('Position not found: $key');
      }
    }

    // Handle sub-key if provided
    if (subKey != null) {
      if (positionData is! Map<String, dynamic>) {
        throw Exception('Position data for $key is not a map');
      }

      final subPosition = positionData[subKey];
      if (subPosition == null || subPosition is! Map<String, dynamic>) {
        throw Exception('Sub-position not found or invalid: $key.$subKey');
      }

      return _parsePositionMap(subPosition);
    }

    return _parsePositionMap(positionData);
  }

  /// Get account position by index from gesture configuration
  ///
  /// Returns the (x, y) coordinates for the account at the specified index
  /// Throws [Exception] if account position is not found
  static Future<(double, double)> getAccountPosition(int accountIndex) async {
    await _ensureConfigLoaded();

    dynamic accountPositionsData;

    // Try to get from cached positions first
    if (_cachedPositions != null) {
      accountPositionsData = _cachedPositions!['account_positions'];
    }

    // Fallback to defaults if not found in cache
    if (accountPositionsData == null) {
      accountPositionsData = defaultGesturePositions['account_positions'];
      if (accountPositionsData == null) {
        throw Exception('Account positions not found in configuration');
      }
    }

    if (accountPositionsData is! Map<String, dynamic>) {
      throw Exception('Account positions data is not a map');
    }

    final accountKey = accountIndex.toString();
    final accountPosition = accountPositionsData[accountKey];

    if (accountPosition == null) {
      throw Exception('Account position not found for index: $accountIndex');
    }

    if (accountPosition is! Map<String, dynamic>) {
      throw Exception(
        'Account position data is invalid for index: $accountIndex',
      );
    }

    return _parsePositionMap(accountPosition);
  }

  /// Helper to parse position from map and validate types
  static (double, double) _parsePositionMap(Map<String, dynamic> position) {
    final x = position['x'];
    final y = position['y'];

    if (x == null || y == null) {
      throw Exception('Position data missing x or y coordinate');
    }

    if (x is! num || y is! num) {
      throw Exception('Position coordinates must be numbers');
    }

    return (x.toDouble(), y.toDouble());
  }

  /// Generate event sequence for refreshing app
  static Future<List<AutomationEvent>> refreshApp() async {
    return [
      AutomationEvent.wait(_getDuration('defaultWaitTime')),
      AutomationEvent.back(),
      AutomationEvent.wait(_getDuration('defaultWaitTime')),
      AutomationEvent.back(),
      AutomationEvent.wait(_getDuration('defaultWaitTime')),
      AutomationEvent.openThisAppIfNeeded(),
      AutomationEvent.wait(_getDuration('defaultWaitTime')),
    ];
  }

  /// Reload global configurations
  static Future<void> reloadGlobalConfigurations() async {
    resetCache();
    await _ensureConfigLoaded();
  }

  /// Generate multiple comments reaction
  static Future<List<AutomationEvent>> generateMultipleCommentsReaction(
    String videoUrl,
    List<String> comments,
  ) async {
    await _ensureConfigLoaded();

    final (commentX, commentY) = await getPosition('comment_button');
    final (fieldX, fieldY) = await getPosition('comment_field');
    final (sendX, sendY) = await getPosition('send_comment_button');

    final warmupUrl = _getVideoUrl();

    List<AutomationEvent> events = [
      AutomationEvent.openUrl(warmupUrl),
      AutomationEvent.wait(1000),
    ];

    for (int i = 0; i < comments.length; i++) {
      final comment = comments[i];
      events.addAll([
        AutomationEvent.openUrl(videoUrl),
        AutomationEvent.wait(_getDuration('videoLoadTime')),
        AutomationEvent.click(commentX, commentY),
        AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
        AutomationEvent.click(fieldX, fieldY),
        AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
        AutomationEvent.write(comment),
        AutomationEvent.wait(_getDuration('defaultWaitTime')),
        AutomationEvent.dismissKeyboard(),
        AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
        AutomationEvent.click(sendX, sendY),
        AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
        AutomationEvent.back(),
        AutomationEvent.wait(_getDuration('defaultWaitTime')),
        if (i < comments.length - 1) ...await switchAccount(i + 1),
      ]);
    }

    events.addAll(await refreshApp());
    return events;
  }

  /// Generate direct message reaction
  static Future<List<AutomationEvent>> generateDirectMessageReaction(
    List<String> usernames,
    String messageText,
    int numberOfMessages,
  ) async {
    await _ensureConfigLoaded();

    final (dmX, dmY) = await getPosition('direct_message_button');
    final (fieldX, fieldY) = await getPosition('direct_message_field');
    final (sendX, sendY) = await getPosition('direct_message_send_button');

    List<AutomationEvent> events = [];

    for (int i = 0; i < numberOfMessages; i++) {
      for (String username in usernames) {
        events.addAll([
          AutomationEvent.openUrl('https://www.tiktok.com/@$username'),
          AutomationEvent.wait(_getDuration('videoLoadTime')),
          AutomationEvent.click(dmX, dmY),
          AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
          AutomationEvent.click(fieldX, fieldY),
          AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
          AutomationEvent.write(messageText),
          AutomationEvent.wait(_getDuration('defaultWaitTime')),
          AutomationEvent.dismissKeyboard(),
          AutomationEvent.wait(_getDuration('defaultWaitTime') * 2),
          AutomationEvent.click(sendX, sendY),
          AutomationEvent.wait(_getDuration('defaultWaitTime')),
        ]);
      }
    }

    events.addAll(await refreshApp());
    return events;
  }

  /// Simulate user-like behavior by adding random delays
  static Future<List<AutomationEvent>> addRandomDelays(
    List<AutomationEvent> events,
  ) async {
    await _ensureConfigLoaded();

    final random = Random();
    List<AutomationEvent> newEvents = [];

    for (var event in events) {
      newEvents.add(event);

      // Add random delay between 500ms to 2000ms
      if (random.nextDouble() < 0.3) {
        final randomDelay = 500 + random.nextInt(1500);
        newEvents.add(AutomationEvent.wait(randomDelay));
      }
    }

    return newEvents;
  }

  /// Validate if the video URL is a valid TikTok URL
  static bool isValidTikTokUrl(String url) {
    final tiktokRegex = RegExp(
      r'^https?:\/\/(www\.)?(tiktok\.com|vm\.tiktok\.com|vt\.tiktok\.com)\/.*',
      caseSensitive: false,
    );
    return tiktokRegex.hasMatch(url);
  }

  /// Get reaction statistics
  static Map<String, int> getReactionStats() {
    return {
      'total_reactions': 0,
      'likes': 0,
      'favorites': 0,
      'shares': 0,
      'comments': 0,
      'follows': 0,
      'watches': 0,
    };
  }

  /// Reset cached configurations
  static void resetCache() {
    _cachedPositions = null;
    _cachedDurations = null;
  }
}
