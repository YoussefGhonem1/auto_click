import 'package:flutter/material.dart';

import '../../domain/services/auth_service.dart';
import '../../domain/models/user_role.dart';

import '../widgets/tasks_section.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/gesture_positions_section.dart';
import '../widgets/server_connection_status.dart';
import '../controllers/task_controller.dart';
import '../services/dialog_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/theme/app_theme.dart';
import 'gesture_positions_page.dart';
import 'server_qr_page.dart';
import 'task_history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final TaskController _taskController = TaskController();

  UserRole? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _currentUserRole = await _authService.getCurrentUserRole();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        currentUserRole: _currentUserRole,
        onLogout: _showLogoutDialog,
        onTaskHistory: _navigateToTaskHistory,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentUserRole == UserRole.admin) ...[
              const ServerConnectionStatus(),
              const SizedBox(height: 24),
            ],

            if (_currentUserRole == UserRole.server) ...[
              _buildServerQRSection(),
              const SizedBox(height: 24),
            ],

            GesturePositionsSection(
              gesturePositions: const [],
              onEdit: _navigateToGesturePositions,
            ),
            const SizedBox(height: 24),
            TasksSection(
              currentUserRole: _currentUserRole,
              onTaskExecute: _executeTask,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerQRSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'QR Code for Server',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Display your QR code to add this server to the administrator\'s management',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToServerQR,
                icon: const Icon(Icons.qr_code),
                label: const Text('Display QR Code'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _executeTask(String taskType) {
    // If a task is already being created, ignore additional taps
    if (_taskController.isCreatingTask) return;

    // Show appropriate dialog based on task type
    switch (taskType) {
      case 'comment':
        _showCommentDialog();
        break;
      case 'watch':
        _showWatchDialog();
        break;
      case 'share':
        _showShareDialog();
        break;
      case 'like':
        _showLikeDialog();
        break;
      case 'favorite':
        _showFavoriteDialog();
        break;
      case 'direct_message':
        _showDirectMessageDialog();
        break;
    }
  }

  void _showCommentDialog() {
    DialogService.showCommentDialog(
      context,
      onConfirm: (url, comments) => _executeCommentTask(url, comments),
    );
  }

  void _showWatchDialog() {
    DialogService.showWatchDialog(
      context,
      onConfirm: (url, numberOfWatches) =>
          _executeWatchTask(url, numberOfWatches),
    );
  }

  void _showShareDialog() {
    DialogService.showShareDialog(
      context,
      onConfirm: (url, numberOfShares) =>
          _executeShareTask(url, numberOfShares),
    );
  }

  void _showLikeDialog() {
    DialogService.showLikeDialog(
      context,
      onConfirm: (url, numberOfLikes) => _executeLikeTask(url, numberOfLikes),
    );
  }

  void _showFavoriteDialog() {
    DialogService.showFavoriteDialog(
      context,
      onConfirm: (url, numberOfFavorites) =>
          _executeFavoriteTask(url, numberOfFavorites),
    );
  }

  void _showDirectMessageDialog() {
    DialogService.showDirectMessageDialog(
      context,
      onConfirm: (usernames, message, numberOfAccounts) =>
          _executeDirectMessageTask(usernames, message, numberOfAccounts),
    );
  }

  Future<void> _executeCommentTask(
    String videoUrl,
    List<String> comments,
  ) async {
    try {
      final _ = await _taskController.executeCommentTask(videoUrl, comments);
      _showSuccess('Task created successfully (${comments.length} comments)');
    } catch (e) {
      _showError('Error occurred while creating task: $e');
    }
  }

  Future<void> _executeWatchTask(String videoUrl, int numberOfWatches) async {
    try {
      final _ = await _taskController.executeWatchTask(
        videoUrl,
        numberOfWatches,
      );
      _showSuccess('Task created successfully ($numberOfWatches watches)');
    } catch (e) {
      _showError('Error occurred while creating task: $e');
    }
  }

  Future<void> _executeShareTask(String videoUrl, int numberOfShares) async {
    try {
      final _ = await _taskController.executeShareTask(
        videoUrl,
        numberOfShares,
      );
      _showSuccess('Task created successfully ($numberOfShares shares)');
    } catch (e) {
      _showError('Error occurred while creating task: $e');
    }
  }

  Future<void> _executeLikeTask(String videoUrl, int numberOfLikes) async {
    try {
      final _ = await _taskController.executeLikeTask(videoUrl, numberOfLikes);
      _showSuccess('Task created successfully ($numberOfLikes likes)');
    } catch (e) {
      _showError('Error occurred while creating task: $e');
    }
  }

  Future<void> _executeFavoriteTask(
    String videoUrl,
    int numberOfFavorites,
  ) async {
    try {
      final _ = await _taskController.executeFavoriteTask(
        videoUrl,
        numberOfFavorites,
      );
      _showSuccess('Task created successfully ($numberOfFavorites favorites)');
    } catch (e) {
      _showError('Error occurred while creating task: $e');
    }
  }

  Future<void> _executeDirectMessageTask(
    List<String> usernames,
    String message,
    int numberOfAccounts,
  ) async {
    try {
      final _ = await _taskController.executeDirectMessageTask(
        usernames,
        message,
        numberOfAccounts,
      );
      _showSuccess('Task created successfully (${usernames.length} users)');
    } catch (e) {
      _showError('Error occurred while creating task: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.getErrorColor(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.getSuccessColor(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showLogoutDialog() {
    DialogService.showLogoutDialog(context, onConfirm: _logout);
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Logged out successfully');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Error occurred while logging out: ${e.toString()}',
        );
      }
    }
  }

  void _navigateToGesturePositions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GesturePositionsPage()),
    );
  }

  void _navigateToServerQR() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ServerQRPage()),
    );
  }

  void _navigateToTaskHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskHistoryPage()),
    );
  }
}
