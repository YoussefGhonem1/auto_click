import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/services/connection_monitoring_service.dart';
import '../../domain/services/automation_service.dart';
import '../../data/repositories/automation_repository.dart';
import '../../domain/models/device_status.dart';
import '../../domain/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../pages/home_page.dart';
import '../pages/role_selection_page.dart';
import '../pages/task_waiting_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() async {
    // Small delay to prevent flash of loading screen
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in - check role and redirect accordingly
          return RoleBasedHomePage(user: snapshot.data!);
        } else {
          // User is not signed in
          return const RoleSelectionPage();
        }
      },
    );
  }
}

class RoleBasedHomePage extends StatefulWidget {
  final User user;

  const RoleBasedHomePage({super.key, required this.user});

  @override
  State<RoleBasedHomePage> createState() => _RoleBasedHomePageState();
}

class _RoleBasedHomePageState extends State<RoleBasedHomePage> {
  final AuthService _authService = AuthService();
  final ConnectionMonitoringService _connectionService =
      ConnectionMonitoringService();
  late final AutomationService _automationService;
  UserRole? _userRole;
  bool _isLoading = true;
  DeviceStatus? _deviceStatus;

  @override
  void initState() {
    super.initState();
    _automationService = AutomationService(AutomationRepository());
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      // Add a small delay to ensure the role update has completed
      await Future.delayed(const Duration(milliseconds: 1000));

      UserRole? role = await _authService.getCurrentUserRole();

      // If role is still null after delay, retry a few times
      int retryCount = 0;
      while (role == null && retryCount < 3) {
        await Future.delayed(const Duration(milliseconds: 500));
        role = await _authService.getCurrentUserRole();
        retryCount++;
      }

      // For server users, check device status including accessibility
      if (role == UserRole.server) {
        await _connectionService.initialize();
        await _connectionService.onAppStart();

        // Check device status to see if accessibility is enabled
        final deviceStatus = await _automationService.checkDeviceStatus();

        if (mounted) {
          setState(() {
            _userRole = role;
            _deviceStatus = deviceStatus;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _userRole = role;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Handle cleanup for server users
    if (_userRole == UserRole.server) {
      _connectionService.onAppClose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading permissions...',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few seconds',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Redirect based on user role
    if (_userRole == UserRole.admin) {
      return const HomePage();
    } else if (_userRole == UserRole.server) {
      // For server users, check if accessibility is enabled
      if (_deviceStatus != null && !_deviceStatus!.isAccessibilityEnabled) {
        return _buildAccessibilityEnablePage();
      }
      return const TaskWaitingPage();
    } else {
      // Fallback to home page if role is unknown
      return const HomePage();
    }
  }

  Widget _buildAccessibilityEnablePage() {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enable Accessibility'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          right: 24,
          left: 24,
          top: 24,
          bottom: 16,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.accessibility,
              size: 100,
              color: AppColors.getInfoColor(context),
            ),
            const SizedBox(height: 24),
            Text(
              'Accessibility required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To execute tasks, you must enable the accessibility service for this app.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You will be redirected to system settings to enable the service.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _automationService.openAccessibilitySettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Accessibility Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                // Refresh device status
                setState(() {
                  _isLoading = true;
                });
                await _loadUserRole();
              },
              child: Text(
                'Update Status',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(
                right: 10,
                left: 10,
                top: 10,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.getInfoColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.getInfoColor(context).withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.getInfoColor(context),
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Instructions for enabling',
                    style: TextStyle(
                      color: AppColors.getInfoColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Press the "Open Accessibility Settings" button\n'
                    '2. Find this app in the list\n'
                    '3. Enable the accessibility service\n'
                    '4. Return to the app and press "Update Status"',
                    style: TextStyle(
                      color: AppColors.getInfoColor(context),
                      fontSize: 14,
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
