import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../widgets/tiktok_url_dialog.dart';
import '../widgets/comment_dialog.dart';
import '../widgets/watch_dialog.dart';
import '../widgets/share_dialog.dart';
import '../widgets/like_dialog.dart';
import '../widgets/favorite_dialog.dart';
import '../widgets/direct_message_dialog.dart';
import '../pages/gesture_positions_page.dart';

class DialogService {
  static void showCommentDialog(
    BuildContext context, {
    required Function(String url, List<String> comments) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => CommentDialog(
        title: 'Comment on Video',
        description:
            'The selected video will be opened and commented on with the written texts',
        onConfirm: onConfirm,
      ),
    );
  }

  static void showWatchDialog(
    BuildContext context, {
    required Function(String url, int numberOfWatches) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => WatchDialog(
        title: 'Watch Video',
        description:
            'The selected video will be opened and commented on with the written texts',
        onConfirm: onConfirm,
      ),
    );
  }

  static void showShareDialog(
    BuildContext context, {
    required Function(String url, int numberOfShares) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => ShareDialog(
        title: 'Share Video',
        description:
            'The selected video will be opened and commented on with the written texts',
        onConfirm: onConfirm,
      ),
    );
  }

  static void showLikeDialog(
    BuildContext context, {
    required Function(String url, int numberOfLikes) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => LikeDialog(
        title: 'Like Video',
        description:
            'The selected video will be opened and commented on with the written texts',
        onConfirm: onConfirm,
      ),
    );
  }

  static void showFavoriteDialog(
    BuildContext context, {
    required Function(String url, int numberOfFavorites) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => FavoriteDialog(
        title: 'Add to Favorites',
        description:
            'The selected video will be opened and commented on with the written texts',
        onConfirm: onConfirm,
      ),
    );
  }

  static void showDirectMessageDialog(
    BuildContext context, {
    required Function(
      List<String> usernames,
      String message,
      int numberOfAccounts,
    )
    onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => DirectMessageDialog(
        title: 'Send Direct Message',
        description:
            'The selected video will be opened and commented on with the written texts',
        onConfirm: onConfirm,
      ),
    );
  }

  static void showUrlDialogForTask(
    BuildContext context, {
    required String taskType,
    required Function(String url) onConfirm,
  }) {
    final taskTitles = {
      'comment': 'Comment on Video',
      'like': 'Like Video',
      'favorite': 'Add to Favorites',
      'share': 'Share Video',
      'watch': 'Watch Video',
      'direct_message': 'Send Direct Message',
    };

    final taskDescriptions = {
      'comment':
          'The selected video will be opened and commented on with the written texts',
      'like':
          'The selected video will be opened and commented on with the written texts',
      'favorite':
          'The selected video will be opened and commented on with the written texts',
      'share':
          'The selected video will be opened and commented on with the written texts',
      'watch':
          'The selected video will be opened and commented on with the written texts',
      'direct_message':
          'The selected video will be opened and commented on with the written texts',
    };

    showDialog(
      context: context,
      builder: (context) => TikTokUrlDialog(
        title: taskTitles[taskType] ?? 'Perform Task',
        description:
            taskDescriptions[taskType] ??
            'The selected video will be opened and commented on with the written texts',
        onConfirm: onConfirm,
      ),
    );
  }

  static void showLogoutDialog(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: AppTextStyles.heading2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTextStyles.subtitle(
            context,
          ).copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  static void navigateToGesturePositionsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GesturePositionsPage()),
    );
  }
}
