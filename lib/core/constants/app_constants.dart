import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class AppConstants {
  // App Information
  static const String appName = 'TikTok Auto Actions';
  static const String appVersion = '1.0.0';

  // Spacing and Sizing
  static const double defaultPadding = 20.0;
  static const double cardPadding = 20.0;
  static const double itemSpacing = 8.0;
  static const double sectionSpacing = 24.0;

  // Border Radius
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double itemRadius = 8.0;

  // Animation Durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 500;
  static const int longAnimationDuration = 1000;

  // API Endpoints (if any in future)
  static const String baseUrl = '';

  // Platform Channel Names
  static const String accessibilityChannel = 'com.auto.tasks/accessibility';

  // TikTok Package Names
  static const String tiktokMainPackage = 'com.ss.android.ugc.trill';
  static const String tiktokAlternativePackage = 'com.zhiliaoapp.musically';

  // Play Store URLs
  static const String tiktokPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ss.android.ugc.trill';

  // Default Gesture Positions
  static const Map<String, Map<String, dynamic>> defaultGesturePositions = {
    'like': {'x': 360, 'y': 520, 'active': true},
    'comment': {'x': 360, 'y': 580, 'active': true},
    'share': {'x': 360, 'y': 640, 'active': true},
    'favorite': {'x': 360, 'y': 460, 'active': false},
  };

  // Task Types
  static const List<String> reactionTasks = [
    'comments',
    'likes',
    'favorite',
    'share',
  ];

  static const List<String> communicationTasks = ['direct_message'];

  // Messages
  static const String systemReadyMessage =
      'TikTok connected and ready for automation';
  static const String setupRequiredMessage = 'Please complete setup to begin';
  static const String likeSuccessMessage =
      'Like button clicked successfully! ❤️';
  static const String likeErrorMessage = 'Could not locate like button';
  static const String commentSuccessMessage = 'Comment action executed';
  static const String favoriteSuccessMessage = 'Favorite action executed';
  static const String shareSuccessMessage = 'Share action executed';
  static const String directMessageSuccessMessage =
      'Direct message action executed';

  // Error Messages
  static const String tiktokNotInstalledError =
      'TikTok is not installed. Please install TikTok first.';
  static const String accessibilityNotEnabledError =
      'Accessibility service is not enabled.';
  static const String taskExecutionError = 'Failed to execute task';
  static const String accessibilitySettingsError =
      'Failed to open accessibility settings';
  static const String playStoreError = 'Failed to open Play Store';

  // Screen Dimensions - Get real device dimensions

  // Physical pixels (actual device pixels)
  static double get screenWidthPixels => ui.window.physicalSize.width;
  static double get screenHeightPixels => ui.window.physicalSize.height;

  // Logical pixels (Flutter units) - for UI layout
  static double get screenWidth =>
      ui.window.physicalSize.width / ui.window.devicePixelRatio;
  static double get screenHeight =>
      ui.window.physicalSize.height / ui.window.devicePixelRatio;

  // Alternative method using MediaQueryData (logical pixels)
  static double get screenWidthAlt =>
      MediaQueryData.fromView(ui.window).size.width;
  static double get screenHeightAlt =>
      MediaQueryData.fromView(ui.window).size.height;

  // Device pixel ratio
  static double get devicePixelRatio => ui.window.devicePixelRatio;

  // Screen info for debugging
  static String get screenInfo =>
      'Physical: ${screenWidthPixels.toInt()}x${screenHeightPixels.toInt()} pixels\n'
      'Logical: ${screenWidth.toStringAsFixed(1)}x${screenHeight.toStringAsFixed(1)} dp\n'
      'Pixel Ratio: ${devicePixelRatio.toStringAsFixed(2)}x';
}
