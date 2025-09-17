import 'package:flutter/material.dart';
import '../models/task_option.dart';

class TaskConfiguration {
  static List<TaskOption> getReactionTasks({
    required Function(String) onTaskExecute,
  }) {
    return [
      TaskOption(
        title: 'Comments',
        icon: Icons.comment,
        onTap: () => onTaskExecute('comment'),
      ),
      TaskOption(
        title: 'Like',
        icon: Icons.favorite,
        onTap: () => onTaskExecute('like'),
      ),
      TaskOption(
        title: 'Add to Favorites',
        icon: Icons.star,
        onTap: () => onTaskExecute('favorite'),
      ),
      TaskOption(
        title: 'Share Video',
        icon: Icons.share,
        onTap: () => onTaskExecute('share'),
      ),
      TaskOption(
        title: 'Watch Video',
        icon: Icons.play_circle,
        onTap: () => onTaskExecute('watch'),
      ),
    ];
  }

  static List<TaskOption> getCommunicationTasks({
    required Function(String) onTaskExecute,
  }) {
    return [
      TaskOption(
        title: 'Send Direct Message',
        icon: Icons.send,
        onTap: () => onTaskExecute('direct_message'),
      ),
    ];
  }
}
