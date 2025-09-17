import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SystemOverlayWidget extends StatelessWidget {
  final String taskType;
  final String taskId;
  final VoidCallback onTerminate;
  final VoidCallback onDismiss;
  final bool isTerminating;

  const SystemOverlayWidget({
    super.key,
    required this.taskType,
    required this.taskId,
    required this.onTerminate,
    required this.onDismiss,
    this.isTerminating = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = AppColors.getErrorColor(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: errorColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Task Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getTaskTypeText(taskType),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Terminate Button
            GestureDetector(
              onTap: isTerminating ? null : onTerminate,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isTerminating
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              errorColor,
                            ),
                          ),
                        ),
                      )
                    : Icon(Icons.stop, color: errorColor, size: 24),
              ),
            ),
            const SizedBox(height: 8),
            // Terminate Text
            Text(
              isTerminating ? 'Stopping...' : 'Stop Task',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Dismiss Button
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Hide',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTaskTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return 'Like';
      case 'comment':
        return 'Comment';
      case 'share':
        return 'Share';
      case 'favorite':
        return 'Favorite';
      case 'watch':
        return 'Watch';
      case 'direct_message':
        return 'Direct Message';
      case 'automation':
        return 'Automation Task';
      case 'social':
        return 'Social Task';
      case 'content':
        return 'Content Task';
      case 'analysis':
        return 'Analysis Task';
      default:
        return 'Task';
    }
  }
}
