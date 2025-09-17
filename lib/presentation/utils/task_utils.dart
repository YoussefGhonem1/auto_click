import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TaskUtils {
  static String getTaskTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'watch':
        return "Watch";
      case 'like':
        return "Like";
      case 'comment':
        return "Comment";
      case 'share':
        return "Share";
      case 'favorite':
        return "Favorite";
      case 'direct_message':
        return "Direct Message";
      default:
        return type;
    }
  }

  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  static Color getStatusColor(String status, BuildContext context) {
    return AppColors.getStatusColor(status, context);
  }

  static IconData getTaskIcon(String type) {
    switch (type.toLowerCase()) {
      case 'automation':
        return Icons.smart_toy;
      case 'social':
        return Icons.people;
      case 'content':
        return Icons.video_library;
      case 'analysis':
        return Icons.analytics;
      default:
        return Icons.task;
    }
  }

  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  static String buildTaskDataPreview(Map<String, dynamic> data) {
    if (data.containsKey('videoUrl')) {
      return 'TikTok Video';
    } else if (data.containsKey('action')) {
      return 'Action: ${data['action']}';
    } else if (data.containsKey('message')) {
      return 'Message: ${data['message']}';
    } else {
      return '${data.keys.length} items';
    }
  }

  static Map<String, int> countOperations(Map<String, dynamic> data) {
    final operations = <String, int>{};

    // Count different types of operations
    if (data.containsKey('likes')) {
      operations['likes'] = data['numberOfLikes'] is int
          ? data['numberOfLikes']
          : 0;
    }
    if (data.containsKey('watches')) {
      operations['watches'] = data['numberOfWatches'] is int
          ? data['numberOfWatches']
          : 0;
    }
    if (data.containsKey('comments')) {
      operations['comments'] = data['comments'] is List
          ? data['comments'].length
          : 0;
    }
    if (data.containsKey('shares')) {
      operations['shares'] = data['numberOfShares'] is int
          ? data['numberOfShares']
          : 0;
    }
    if (data.containsKey('favorites')) {
      operations['favorites'] = data['numberOfFavorites'] is int
          ? data['numberOfFavorites']
          : 0;
    }
    if (data.containsKey('directMessages')) {
      operations['directMessages'] = data['numberOfAccounts'] is int
          ? data['numberOfAccounts']
          : 0;
    }

    // Count total operations
    operations['total'] = operations.values.fold(
      0,
      (sum, count) => sum + count,
    );

    return operations;
  }

  static String getOperationText(String operation) {
    switch (operation.toLowerCase()) {
      case 'likes':
        return 'Like';
      case 'watches':
        return 'Watch';
      case 'comments':
        return 'Comment';
      case 'shares':
        return 'Share';
      case 'favorites':
        return 'Favorite';
      case 'directmessages':
        return 'Direct Message';
      case 'total':
        return 'Total';
      default:
        return operation;
    }
  }
}
