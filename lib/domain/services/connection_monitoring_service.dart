import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import 'user_service.dart';
import 'auth_service.dart';

class ConnectionMonitoringService {
  static final ConnectionMonitoringService _instance =
      ConnectionMonitoringService._internal();
  factory ConnectionMonitoringService() => _instance;
  ConnectionMonitoringService._internal();

  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  Timer? _heartbeatTimer;
  StreamSubscription? _appLifecycleSubscription;
  bool _isInitialized = false;

  // Initialize connection monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final userRole = await _userService.getUserRole(currentUser.uid);

      // Only monitor connection for server users
      if (userRole == UserRole.server) {
        await _startConnectionMonitoring(currentUser.uid);
      }
    }

    _isInitialized = true;
  }

  // Start monitoring connection for a server user
  Future<void> _startConnectionMonitoring(String uid) async {
    // Set initial connection status
    await _userService.setServerConnected(uid);

    // Start heartbeat to maintain connection status
    _startHeartbeat(uid);

    // Listen to app lifecycle changes
    _listenToAppLifecycle(uid);
  }

  // Start heartbeat timer to periodically update connection status
  void _startHeartbeat(String uid) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        await _userService.updateServerConnectionStatus(uid, true);
      } catch (e) {
        // Log error in production
      }
    });
  }

  // Listen to app lifecycle changes
  void _listenToAppLifecycle(String uid) {
    // Note: In a real Flutter app, you would use WidgetsBindingObserver
    // For now, we'll handle this through manual calls
    SystemChannels.lifecycle.setMessageHandler((message) async {
      switch (message) {
        case 'AppLifecycleState.paused':
        case 'AppLifecycleState.detached':
          log('AppLifecycleState.paused or AppLifecycleState.detached');
          // await _userService.setServerDisconnected(uid);
          break;
        case 'AppLifecycleState.resumed':
          await _userService.setServerConnected(uid);
          _startHeartbeat(uid);
          break;
      }
      return null;
    });
  }

  // Handle server connection when app starts
  Future<void> onAppStart() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final userRole = await _userService.getUserRole(currentUser.uid);

      if (userRole == UserRole.server) {
        await _userService.setServerConnected(currentUser.uid);
        _startHeartbeat(currentUser.uid);
      }
    }
  }

  // Handle server disconnection when app closes
  Future<void> onAppClose() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final userRole = await _userService.getUserRole(currentUser.uid);

      if (userRole == UserRole.server) {
        await _userService.setServerDisconnected(currentUser.uid);
      }
    }

    _cleanup();
  }

  // Cleanup resources
  void _cleanup() {
    _heartbeatTimer?.cancel();
    _appLifecycleSubscription?.cancel();
    _isInitialized = false;
  }

  // Get real-time connection status stream
  Stream<List<AppUser>> getConnectionStatusStream() {
    return _userService.listenToAdminConnectedServers(
      _authService.currentUser?.uid ?? '',
    );
  }

  // Get connection statistics
  Future<Map<String, int>> getConnectionStatistics() async {
    return await _userService.getAdminConnectionStatistics(
      _authService.currentUser?.uid ?? '',
    );
  }

  // Force update connection status (admin only)
  Future<bool> forceUpdateConnectionStatus(String uid, bool isConnected) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    final currentUserRole = await _userService.getUserRole(currentUser.uid);
    if (currentUserRole != UserRole.admin) return false;

    return await _userService.updateServerConnectionStatus(uid, isConnected);
  }

  // Get all connected servers
  Future<List<AppUser>> getConnectedServers() async {
    return await _userService.getConnectedServers();
  }

  // Get all server users
  Future<List<AppUser>> getAllServers() async {
    return await _userService.getAllServers();
  }

  // Check if a specific server is connected
  Future<bool> isServerConnected(String uid) async {
    final user = await _userService.getUserByUid(uid);
    return user?.isConnected ?? false;
  }

  // Listen to specific server status
  Stream<AppUser?> listenToServerStatus(String uid) {
    return _userService.listenToServerStatus(uid);
  }

  // Manually set server as connected (for testing or manual control)
  Future<void> setServerConnected(String uid) async {
    await _userService.setServerConnected(uid);
  }

  // Manually set server as disconnected (for testing or manual control)
  Future<void> setServerDisconnected(String uid) async {
    await _userService.setServerDisconnected(uid);
  }

  // Dispose method to clean up resources
  void dispose() {
    _cleanup();
  }
}
