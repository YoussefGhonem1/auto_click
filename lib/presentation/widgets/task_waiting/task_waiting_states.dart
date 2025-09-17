import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TaskWaitingStates {
  static Widget buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  static Widget buildErrorState(String error, VoidCallback onRetry) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.getErrorColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connection Error',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.getErrorColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your internet connection and try again',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle(context),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getErrorColor(context),
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
