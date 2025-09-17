import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';

abstract class AutomationRepositoryInterface {
  Future<bool> isTikTokInstalled();
  Future<bool> isAccessibilityServiceEnabled();
  Future<bool> clickLikeButton();
  Future<bool> clickSaveButton();
  Future<void> openAccessibilitySettings();
  Future<void> openTikTokInPlayStore();
  Future<void> openTikTokVideo(String videoUrl);
  Future<bool> performCommentAction(String commentText);
  Future<bool> executeEventSequence(List<Map<String, dynamic>> events);
  Future<bool> showTerminationOverlay(String taskType, String taskId);
  Future<bool> hideTerminationOverlay();
  Future<bool> cancelEventSequence();
  Future<bool> checkOverlayPermission();
  Future<bool> requestOverlayPermission();
  Future<bool> isOverlayVisible();
}

class AutomationRepository implements AutomationRepositoryInterface {
  static const _platform = MethodChannel('com.auto.tasks/accessibility');
  static const _overlayPlatform = MethodChannel('com.auto.tasks/overlay');

  @override
  Future<bool> isTikTokInstalled() async {
    try {
      return await _platform.invokeMethod('isTikTokInstalled');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      return await _platform.invokeMethod('isAccessibilityServiceEnabled');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> clickLikeButton() async {
    try {
      return await _platform.invokeMethod('clickLikeButton');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> clickSaveButton() async {
    try {
      return await _platform.invokeMethod('clickSaveButton');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> openAccessibilitySettings() async {
    try {
      await _platform.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      throw Exception('Failed to open accessibility settings: $e');
    }
  }

  @override
  Future<void> openTikTokInPlayStore() async {
    try {
      const intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data:
            'https://play.google.com/store/apps/details?id=com.ss.android.ugc.trill',
      );
      await intent.launch();
    } catch (e) {
      throw Exception('Failed to open Play Store: $e');
    }
  }

  @override
  Future<void> openTikTokVideo(String videoUrl) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: videoUrl,
      );
      await intent.launch();
    } catch (e) {
      throw Exception('Failed to open TikTok video: $e');
    }
  }

  @override
  Future<bool> performCommentAction(String commentText) async {
    try {
      return await _platform.invokeMethod('performCommentAction', {
        'commentText': commentText,
      });
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> executeEventSequence(List<Map<String, dynamic>> events) async {
    try {
      return await _platform.invokeMethod('executeEventSequence', {
        'events': events,
      });
    } catch (e) {
      return false;
    }
  }

  // Overlay methods
  @override
  Future<bool> showTerminationOverlay(String taskType, String taskId) async {
    try {
      return await _overlayPlatform.invokeMethod('showTerminationOverlay', {
        'taskType': taskType,
        'taskId': taskId,
      });
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> hideTerminationOverlay() async {
    try {
      return await _overlayPlatform.invokeMethod('hideTerminationOverlay');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> cancelEventSequence() async {
    try {
      return await _platform.invokeMethod('cancelEventSequence');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> checkOverlayPermission() async {
    try {
      return await _overlayPlatform.invokeMethod('checkOverlayPermission');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestOverlayPermission() async {
    try {
      return await _overlayPlatform.invokeMethod('requestOverlayPermission');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isOverlayVisible() async {
    try {
      return await _overlayPlatform.invokeMethod('isOverlayVisible');
    } catch (e) {
      return false;
    }
  }
}
