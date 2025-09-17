import 'package:auto_click/data/data_sources/local_datasource/gesture_positions.dart';
import 'package:flutter/material.dart';

class GesturePositionConfig {
  final String key;
  final String displayName;
  final IconData icon;
  final GesturePositionType type;
  final Map<String, dynamic> value;

  const GesturePositionConfig({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.type,
    required this.value,
  });

  static List<GesturePositionConfig> getAllPositions(
    Map<String, dynamic> positions,
  ) {
    return [
      GesturePositionConfig(
        key: 'like_button',
        displayName: 'Like Button',
        icon: Icons.favorite,
        type: GesturePositionType.simple,
        value:
            positions['like_button'] ?? defaultGesturePositions['like_button'],
      ),
      GesturePositionConfig(
        key: 'comment_button',
        displayName: 'Comment Button',
        icon: Icons.comment,
        type: GesturePositionType.simple,
        value:
            positions['comment_button'] ??
            defaultGesturePositions['comment_button'],
      ),
      GesturePositionConfig(
        key: 'favorite_button',
        displayName: 'Favorite Button',
        icon: Icons.star,
        type: GesturePositionType.simple,
        value:
            positions['favorite_button'] ??
            defaultGesturePositions['favorite_button'],
      ),
      GesturePositionConfig(
        key: 'share_button',
        displayName: 'Share Button',
        icon: Icons.share,
        type: GesturePositionType.simple,
        value:
            positions['share_button'] ??
            defaultGesturePositions['share_button'],
      ),
      GesturePositionConfig(
        key: 'comment_field',
        displayName: 'Comment Field',
        icon: Icons.text_fields,
        type: GesturePositionType.simple,
        value:
            positions['comment_field'] ??
            defaultGesturePositions['comment_field'],
      ),
      GesturePositionConfig(
        key: 'creator_account_button',
        displayName: 'Creator Account Button',
        icon: Icons.person,
        type: GesturePositionType.simple,
        value:
            positions['creator_account_button'] ??
            defaultGesturePositions['creator_account_button'],
      ),
      GesturePositionConfig(
        key: 'profile_button',
        displayName: 'Profile Button',
        icon: Icons.account_circle,
        type: GesturePositionType.simple,
        value:
            positions['profile_button'] ??
            defaultGesturePositions['profile_button'],
      ),
      GesturePositionConfig(
        key: 'send_comment_button',
        displayName: 'Send Comment Button',
        icon: Icons.send,
        type: GesturePositionType.simple,
        value:
            positions['send_comment_button'] ??
            defaultGesturePositions['send_comment_button'],
      ),
      GesturePositionConfig(
        key: 'copy_link_button',
        displayName: 'Copy Link Button',
        icon: Icons.link,
        type: GesturePositionType.simple,
        value:
            positions['copy_link_button'] ??
            defaultGesturePositions['copy_link_button'],
      ),
      GesturePositionConfig(
        key: 'direct_message_button',
        displayName: 'Direct Message Button',
        icon: Icons.message,
        type: GesturePositionType.simple,
        value:
            positions['direct_message_button'] ??
            defaultGesturePositions['direct_message_button'],
      ),
      GesturePositionConfig(
        key: 'direct_message_field',
        displayName: 'Direct Message Field',
        icon: Icons.chat,
        type: GesturePositionType.simple,
        value:
            positions['direct_message_field'] ??
            defaultGesturePositions['direct_message_field'],
      ),
      GesturePositionConfig(
        key: 'direct_message_send_button',
        displayName: 'Direct Message Send Button',
        icon: Icons.send,
        type: GesturePositionType.simple,
        value:
            positions['direct_message_send_button'] ??
            defaultGesturePositions['direct_message_send_button'],
      ),
      GesturePositionConfig(
        key: 'current_account_username',
        displayName: 'Current Account Username',
        icon: Icons.person_outline,
        type: GesturePositionType.simple,
        value:
            positions['current_account_username'] ??
            defaultGesturePositions['current_account_username'],
      ),
      GesturePositionConfig(
        key: 'gesture_up',
        displayName: 'Gesture Up',
        icon: Icons.keyboard_arrow_up,
        type: GesturePositionType.gesture,
        value:
            positions['gesture_up'] ??
            {
              'start': defaultGesturePositions['gesture_up']['start'],
              'end': defaultGesturePositions['gesture_up']['end'],
            },
      ),
      GesturePositionConfig(
        key: 'gesture_down',
        displayName: 'Gesture Down',
        icon: Icons.keyboard_arrow_down,
        type: GesturePositionType.gesture,
        value:
            positions['gesture_down'] ??
            {
              'start': defaultGesturePositions['gesture_down']['start'],
              'end': defaultGesturePositions['gesture_down']['end'],
            },
      ),
    ];
  }
}

class DurationConfig {
  final String key;
  final String displayName;
  final IconData icon;
  final int value;
  final String description;

  const DurationConfig({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.value,
    required this.description,
  });

  static List<DurationConfig> getAllDurations(Map<String, int> durations) {
    return [
      DurationConfig(
        key: 'defaultWaitTime',
        displayName: 'Default Wait Time',
        icon: Icons.hourglass_empty,
        value: durations['defaultWaitTime'] ?? defaultWaitTime,
        description: 'The default wait time between actions',
      ),
      DurationConfig(
        key: 'videoLoadTime',
        displayName: 'Video Load Time',
        icon: Icons.video_library,
        value: durations['videoLoadTime'] ?? videoLoadTime,
        description: 'The time required to load the video before interaction',
      ),
      DurationConfig(
        key: 'videoWatchTime',
        displayName: 'Video Watch Time',
        icon: Icons.play_circle,
        value: durations['videoWatchTime'] ?? videoWatchTime,
        description: 'The duration of video viewing before moving to the next',
      ),
      DurationConfig(
        key: 'switchAccountTime',
        displayName: 'Switch Account Time',
        icon: Icons.swap_horiz,
        value: durations['switchAccountTime'] ?? switchAccountTime,
        description:
            'The time required to switch accounts and move between them',
      ),
      DurationConfig(
        key: 'swapDuration',
        displayName: 'Swap Duration',
        icon: Icons.swipe,
        value: durations['swapDuration'] ?? swapTime,
        description: 'The time required to swipe the page',
      ),
      DurationConfig(
        key: 'maxTaskDuration',
        displayName: 'Max Task Duration',
        icon: Icons.timer,
        value: durations['maxTaskDuration'] ?? maxTaskDuration,
        description: 'The maximum duration for task execution in milliseconds',
      ),
    ];
  }
}

enum GesturePositionType { simple, gesture, accountPositions }
