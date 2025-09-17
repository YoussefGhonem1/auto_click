import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/task.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/services/qr_code_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../controllers/task_execution_controller.dart';
import '../controllers/task_cleanup_manager.dart';
import '../controllers/task_stream_manager.dart';
import '../controllers/task_termination_controller.dart';
import '../../data/repositories/automation_repository.dart';
import '../widgets/task_waiting/execution_status_card.dart';
import '../widgets/task_waiting/task_details_dialog.dart';
import '../widgets/task_waiting/tasks_grid.dart';
import '../widgets/task_waiting/no_tasks_empty_state.dart';
import '../widgets/task_waiting/task_waiting_states.dart';

class TaskWaitingPage extends StatefulWidget {
  const TaskWaitingPage({super.key});

  @override
  State<TaskWaitingPage> createState() => _TaskWaitingPageState();
}

class _TaskWaitingPageState extends State<TaskWaitingPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Services
  final AuthService _authService = AuthService();

  // Controllers
  late final TaskExecutionController _executionController;
  late final TaskCleanupManager _cleanupManager;
  late final TaskStreamManager _streamManager;
  late final TaskTerminationController _terminationController;

  // Animation
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Lifecycle state
  bool _wasExecutingBeforeBackground = false;

  List<Task> _tasks = [];

  bool _isAppInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _setupAnimation();
    _setupStreamListener();
    _cleanupManager.startCleanupTimer();

    SystemChannels.lifecycle.setMessageHandler((message) async {
      if (message == 'AppLifecycleState.resumed') {
        await Future.delayed(const Duration(milliseconds: 10000), () async {
          await _executionController.processTaskQueue(_tasks);
        });
      }
      if (message == 'AppLifecycleState.paused' ||
          message == 'AppLifecycleState.detached') {
        _isAppInBackground = true;
        _wasExecutingBeforeBackground = _executionController.isExecutingTasks;
      }
      return null;
    });
  }

  void _handleAppResumed() {
    // Resume cleanup timer
    _cleanupManager.resumeCleanupTimer();

    // Re-establish stream listeners with forced reconnection
    // This ensures we get fresh data after potentially losing network connection
    _streamManager.reconnectTaskStream();

    // Resume task execution if it was executing before background
    if (_wasExecutingBeforeBackground &&
        !_executionController.isExecutingTasks) {
      _executionController.resumeTaskExecution();
    }

    // Show a subtle message about resuming
    if (_wasExecutingBeforeBackground) {
      _showMessage('Tasks resumed after returning to the app');
    }

    // Reset the background state
    _wasExecutingBeforeBackground = false;
  }

  void _handleAppTerminated() {
    // Cleanup resources when app is terminated to prevent memory leaks
    _cleanupManager.dispose();
    _streamManager.dispose();
    _executionController.dispose();
    _terminationController.dispose();
  }

  void _initializeControllers() {
    _executionController = TaskExecutionController();
    _cleanupManager = TaskCleanupManager();
    _streamManager = TaskStreamManager();

    // Initialize termination controller
    final automationRepository = AutomationRepository();
    _terminationController = TaskTerminationController(
      _executionController,
      automationRepository,
    );

    // Setup callbacks
    _executionController.onShowMessage = _showMessage;
    _executionController.onExecutionToggled = _processExistingTasks;
    _cleanupManager.onShowMessage = _showMessage;
    _terminationController.onShowMessage = _showMessage;

    _streamManager.onTasksReceived = (tasks) async {
      _tasks = tasks;
      if (_executionController.isExecutingTasks &&
          !_executionController.isCurrentlyExecuting) {
        final sortedTasks = _streamManager.sortTasksByCreationDate(tasks);

        await _executionController.processTaskQueue(sortedTasks);
      }
      _cleanupManager.cleanupCompletedTasks(tasks);
    };
  }

  void _setupAnimation() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  void _setupStreamListener() {
    _streamManager.setupTaskStreamListener();
  }

  void _processExistingTasks() async {
    // Get current tasks from the stream
    try {
      final tasksStream = _streamManager.getUserTasksStream();
      final currentTasks = await tasksStream.first;

      if (currentTasks.isNotEmpty) {
        // Process existing pending tasks
        final sortedTasks = _streamManager.sortTasksByCreationDate(
          currentTasks,
        );
        await _executionController.processTaskQueue(sortedTasks);
      }
    } catch (e) {
      _showMessage(
        'Error processing existing tasks: ${e.toString()}',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      if (isError) {
        SnackbarUtils.showError(context, message);
      } else {
        SnackbarUtils.showSuccess(context, message);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _executionController.dispose();
    _cleanupManager.dispose();
    _streamManager.dispose();
    _terminationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: Column(
          children: [
            // Execution Status Card
            AnimatedBuilder(
              animation: Listenable.merge([
                _executionController,
                _terminationController,
              ]),
              builder: (context, child) {
                return ExecutionStatusCard(
                  isExecutingTasks: _executionController.isExecutingTasks,
                  currentExecutingTask:
                      _executionController.currentExecutingTask,
                  executionStatus: _executionController.executionStatus,
                  cleanupInterval: _cleanupManager.cleanupInterval,
                  onToggleExecution: _executionController.toggleTaskExecution,
                  isOverlayVisible: _terminationController.isOverlayVisible,
                  isTerminating: _terminationController.isTerminating,
                  onShowOverlay: _terminationController.showOverlayManually,
                  onHideOverlay: _terminationController.hideOverlayManually,
                  onTerminateTask: _terminationController.terminateTaskManually,
                );
              },
            ),
            // Tasks Stream
            Expanded(
              child: StreamBuilder<List<Task>>(
                stream: _streamManager.getUserTasksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return TaskWaitingStates.buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return TaskWaitingStates.buildErrorState(
                      snapshot.error.toString(),
                      () => setState(() {}),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const NoTasksEmptyState();
                  }

                  final tasks = _streamManager.sortTasksByCreationDate(
                    snapshot.data!,
                  );
                  _slideController.forward();

                  return AnimatedBuilder(
                    animation: _executionController,
                    builder: (context, child) {
                      return TasksGrid(
                        tasks: tasks,
                        currentExecutingTask:
                            _executionController.currentExecutingTask,
                        slideAnimation: _slideAnimation,
                        onTaskTap: _showTaskDetails,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Task Waiting'),
      elevation: 0,
      centerTitle: true,
      actions: [
        // QR Code Button for Server Users
        IconButton(
          icon: const Icon(Icons.qr_code),
          onPressed: _scanQRCode,
          tooltip: 'Show server QR code',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            setState(() {});
            SnackbarUtils.showInfo(context, 'Data updated');
          },
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(
                    _executionController.isExecutingTasks
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _executionController.isExecutingTasks
                        ? 'Stop Execution'
                        : 'Start Execution',
                  ),
                ],
              ),
              onTap: () async =>
                  await _executionController.toggleTaskExecution(),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.cleaning_services),
                  SizedBox(width: 8),
                  Text('Clean Completed Tasks'),
                ],
              ),
              onTap: () => _cleanupManager.performManualCleanup(),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Update Gesture Configurations'),
                ],
              ),
              onTap: () => _executionController.reloadGestureConfigurations(),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
              onTap: () => _showLogoutDialog(),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _scanQRCode() async {
    try {
      // Get current user's server ID
      final currentUser = await _authService.currentAppUser;
      if (currentUser == null) {
        _showMessage('Please log in first', isError: true);
        return;
      }

      final serverId = currentUser.uid;

      // Show QR code dialog
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Server QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                QRCodeService.generateServerRegistrationQRCode(
                  serverId,
                  size: 250,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan this code from the management device to connect to this server',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to show QR code: ${e.toString()}', isError: true);
      }
    }
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailsDialog(task: task),
    );
  }

  void _showLogoutDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: AppTextStyles.subtitle(
            context,
          ).copyWith(color: theme.colorScheme.primary),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTextStyles.body1.copyWith(color: theme.colorScheme.primary),
        ),
        actions: [
          // Cancel Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(color: theme.colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await _authService.signOut();
              if (mounted) {
                navigator.pushReplacementNamed('/');
              }
            },
            child: Text(
              'Logout',
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
