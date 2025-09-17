import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GesturePositionsUtils {
  static IconData getPositionIcon(String key) {
    switch (key) {
      case 'like_button':
        return Icons.favorite;
      case 'comment_button':
        return Icons.comment;
      case 'favorite_button':
        return Icons.star;
      case 'share_button':
        return Icons.share;
      case 'comment_field':
        return Icons.text_fields;
      case 'profile_button':
        return Icons.person;
      case 'direct_message_button':
        return Icons.message;
      case 'current_account_username':
        return Icons.account_circle;
      default:
        return Icons.touch_app;
    }
  }

  static IconData getDurationIcon(String key) {
    switch (key) {
      case 'defaultWaitTime':
        return Icons.hourglass_empty;
      case 'videoLoadTime':
        return Icons.video_library;
      case 'videoWatchTime':
        return Icons.play_circle;
      case 'switchAccountTime':
        return Icons.swap_horiz;
      case 'swapDuration':
        return Icons.swipe;
      case 'maxTaskDuration':
        return Icons.timer_off;
      default:
        return Icons.timer;
    }
  }

  static String getPositionDisplayName(String key) {
    switch (key) {
      case 'like_button':
        return 'Like Button';
      case 'comment_button':
        return 'Comment Button';
      case 'favorite_button':
        return 'Favorite Button';
      case 'share_button':
        return 'Share Button';
      case 'comment_field':
        return 'Comment Field';
      case 'creator_account_button':
        return 'Creator Account Button';
      case 'profile_button':
        return 'Profile Button';
      case 'send_comment_button':
        return 'Send Comment Button';
      case 'copy_link_button':
        return 'Copy Link Button';
      case 'direct_message_button':
        return 'Direct Message Button';
      case 'direct_message_field':
        return 'Direct Message Field';
      case 'direct_message_send_button':
        return 'Direct Message Send Button';
      case 'gesture_up':
        return 'Gesture Up';
      case 'gesture_down':
        return 'Gesture Down';
      case 'current_account_username':
        return 'Current Account Username';
      default:
        return key;
    }
  }

  static String getDurationDisplayName(String key) {
    switch (key) {
      case 'defaultWaitTime':
        return 'Default Wait Time';
      case 'videoLoadTime':
        return 'Video Load Time';
      case 'videoWatchTime':
        return 'Video Watch Time';
      case 'switchAccountTime':
        return 'Switch Account Time';
      case 'swapDuration':
        return 'Swap Duration';
      case 'maxTaskDuration':
        return 'Max Task Duration';
      default:
        return key;
    }
  }

  static Color getPositionIconColor(String key, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (key) {
      case 'like_button':
        return AppColors.getReactionColor(context);
      case 'comment_button':
        return AppColors.getCommunicationColor(context);
      case 'favorite_button':
        return AppColors.getReactionColor(context);
      case 'share_button':
        return AppColors.getCommunicationColor(context);
      case 'comment_field':
        return colorScheme.primary;
      case 'profile_button':
        return colorScheme.primary;
      case 'direct_message_button':
        return AppColors.getCommunicationColor(context);
      case 'current_account_username':
        return colorScheme.primary;
      default:
        return colorScheme.onSurface;
    }
  }

  static Color getDurationIconColor(String key, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (key) {
      case 'defaultWaitTime':
        return AppColors.getWarningColor(context);
      case 'videoLoadTime':
        return AppColors.getInfoColor(context);
      case 'videoWatchTime':
        return AppColors.getSuccessColor(context);
      case 'switchAccountTime':
        return AppColors.getInfoColor(context);
      case 'maxTaskDuration':
        return AppColors.getWarningColor(context);
      default:
        return colorScheme.onSurface;
    }
  }
}
