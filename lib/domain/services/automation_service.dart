import '../models/device_status.dart';
import '../models/gesture_position.dart';
import '../../data/repositories/automation_repository.dart';
import 'reaction_service.dart';

class AutomationService {
  final AutomationRepositoryInterface _repository;

  AutomationService(this._repository);

  Future<DeviceStatus> checkDeviceStatus() async {
    final isTikTokInstalled = await _repository.isTikTokInstalled();
    final isAccessibilityEnabled = await _repository
        .isAccessibilityServiceEnabled();
    final connectedDevicesCount = isTikTokInstalled ? 1 : 0;

    return DeviceStatus(
      isTikTokInstalled: isTikTokInstalled,
      isAccessibilityEnabled: isAccessibilityEnabled,
      connectedDevicesCount: connectedDevicesCount,
    );
  }

  Future<bool> performLikeAction({required String videoUrl}) async {
    final events = await ReactionService.generateLikeReaction(videoUrl, 1);
    final eventMaps = events.map((e) => e.toJson()).toList();
    return await _repository.executeEventSequence(eventMaps);
  }

  Future<bool> performSaveAction() async {
    return await _repository.clickSaveButton();
  }

  Future<void> openAccessibilitySettings() async {
    await _repository.openAccessibilitySettings();
  }

  Future<void> openTikTokInPlayStore() async {
    await _repository.openTikTokInPlayStore();
  }

  Future<void> openTikTokVideo(String videoUrl) async {
    await _repository.openTikTokVideo(videoUrl);
  }

  List<GesturePosition> getDefaultGesturePositions() {
    return [
      const GesturePosition(name: 'Like', x: 360, y: 520, isActive: true),
      const GesturePosition(name: 'Comment', x: 360, y: 580, isActive: true),
      const GesturePosition(name: 'Save', x: 360, y: 640, isActive: true),
      const GesturePosition(name: 'Share', x: 360, y: 700, isActive: true),
      const GesturePosition(name: 'Favorite', x: 360, y: 460, isActive: false),
    ];
  }

  Future<bool> performCommentAction({
    required String videoUrl,
    required String commentText,
  }) async {
    await openTikTokVideo(videoUrl);
    // Wait for TikTok to load the video
    await Future.delayed(const Duration(seconds: 3));
    // Perform the comment action with the provided text
    return await _repository.performCommentAction(commentText);
  }

  Future<void> performBookmarkAction() async {
    await performSaveAction();
  }

  Future<bool> performFavoriteAction({required String videoUrl}) async {
    final events = await ReactionService.generateFavoriteReaction(videoUrl, 1);
    final eventMaps = events.map((e) => e.toJson()).toList();
    return await _repository.executeEventSequence(eventMaps);
  }

  Future<bool> performShareAction({required String videoUrl}) async {
    final events = await ReactionService.generateShareReaction(videoUrl, 1);
    final eventMaps = events.map((e) => e.toJson()).toList();
    return await _repository.executeEventSequence(eventMaps);
  }

  Future<void> performDirectMessageAction({required String videoUrl}) async {
    await openTikTokVideo(videoUrl);
    // Wait for TikTok to load the video
    await Future.delayed(const Duration(seconds: 3));
    // TODO: Implement direct message action
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
