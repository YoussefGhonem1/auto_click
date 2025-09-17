import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'user_service.dart';

class ServerManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final String _usersCollection = 'users';

  /// Get all servers owned by the current admin
  Future<List<AppUser>> getAdminServers() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return [];

      return await _userService.getAdminServers(currentUser.uid);
    } catch (e) {
      return [];
    }
  }

  /// Get all connected servers owned by the current admin
  Future<List<AppUser>> getAdminConnectedServers() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return [];

      return await _userService.getAdminConnectedServers(currentUser.uid);
    } catch (e) {
      return [];
    }
  }

  /// Create a new server for the current admin
  Future<bool> createServer({
    required String serverId,
    required String serverName,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Check if server ID already exists
      final existingServer = await _firestore
          .collection(_usersCollection)
          .doc(serverId)
          .get();

      if (existingServer.exists) {
        throw Exception('Server ID already exists');
      }

      // Create new server user
      final serverUser = AppUser(
        uid: serverId,
        role: UserRole.server,
        createdAt: DateTime.now(),
        serverName: serverName,
        ownedByAdmin: currentUser.uid,
        isActive: true,
        isConnected: false,
      );

      await _firestore
          .collection(_usersCollection)
          .doc(serverId)
          .set(serverUser.toMap());

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update server information
  Future<bool> updateServer({
    required String serverId,
    String? serverName,
    bool? isActive,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Verify the server belongs to the current admin
      final server = await _firestore
          .collection(_usersCollection)
          .doc(serverId)
          .get();

      if (!server.exists) return false;

      final serverData = AppUser.fromMap(server.data()!);
      if (serverData.ownedByAdmin != currentUser.uid) {
        throw Exception('You can only modify your own servers');
      }

      final updateData = <String, dynamic>{};
      if (serverName != null) updateData['serverName'] = serverName;
      if (isActive != null) updateData['isActive'] = isActive;

      await _firestore
          .collection(_usersCollection)
          .doc(serverId)
          .update(updateData);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a server
  Future<bool> deleteServer(String serverId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Verify the server belongs to the current admin
      final server = await _firestore
          .collection(_usersCollection)
          .doc(serverId)
          .get();

      if (!server.exists) return false;

      final serverData = AppUser.fromMap(server.data()!);
      if (serverData.ownedByAdmin != currentUser.uid) {
        throw Exception('You can only delete your own servers');
      }

      await _firestore.collection(_usersCollection).doc(serverId).delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get server by ID (only if owned by current admin)
  Future<AppUser?> getServerById(String serverId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      final doc = await _firestore
          .collection(_usersCollection)
          .doc(serverId)
          .get();

      if (!doc.exists || doc.data() == null) return null;

      final server = AppUser.fromMap(doc.data()!);

      // Only return if owned by current admin
      if (server.ownedByAdmin != currentUser.uid) return null;

      return server;
    } catch (e) {
      return null;
    }
  }

  /// Listen to admin's servers changes
  Stream<List<AppUser>> listenToAdminServers() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _userService.listenToAdminServers(currentUser.uid);
  }

  /// Listen to admin's connected servers changes
  Stream<List<AppUser>> listenToAdminConnectedServers() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _userService.listenToAdminConnectedServers(currentUser.uid);
  }

  /// Get server statistics for the current admin
  Future<Map<String, int>> getAdminServerStatistics() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return {'total': 0, 'connected': 0, 'active': 0};

      return await _userService.getAdminConnectionStatistics(currentUser.uid);
    } catch (e) {
      return {'total': 0, 'connected': 0, 'active': 0};
    }
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    final userRole = await _authService.getCurrentUserRole();
    return userRole == UserRole.admin;
  }

  /// Add an existing server to admin's management
  Future<bool> addServerToAdmin(String serverId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Check if current user is admin
      final userRole = await _authService.getCurrentUserRole();
      if (userRole != UserRole.admin) {
        throw Exception('You must be an admin to add servers');
      }

      // Check if server exists
      final server = await _firestore
          .collection(_usersCollection)
          .doc(serverId)
          .get();

      if (!server.exists || server.data() == null) {
        throw Exception('Server not found');
      }

      final serverData = AppUser.fromMap(server.data()!);
      if (serverData.role != UserRole.server) {
        throw Exception('ID does not belong to a server');
      }

      // Check if server is already owned by another admin
      if (serverData.ownedByAdmin != null &&
          serverData.ownedByAdmin != currentUser.uid) {
        throw Exception('Server is owned by another admin');
      }

      // Add server to admin's management
      await _firestore.collection(_usersCollection).doc(serverId).update({
        'ownedByAdmin': currentUser.uid,
      });

      return true;
    } catch (e) {
      throw Exception('Failed to add server: ${e.toString()}');
    }
  }

  /// Add an existing server to admin's management with custom name
  Future<bool> addServerToAdminWithName(
    String serverId,
    String serverName,
  ) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Check if current user is admin
      final userRole = await _authService.getCurrentUserRole();
      if (userRole != UserRole.admin) {
        throw Exception('You must be an admin to add servers');
      }

      // Check if server exists
      final server = await _firestore
          .collection(_usersCollection)
          .doc(serverId)
          .get();

      if (!server.exists || server.data() == null) {
        throw Exception('Server not found');
      }

      final serverData = AppUser.fromMap(server.data()!);
      if (serverData.role != UserRole.server) {
        throw Exception('ID does not belong to a server');
      }

      // Check if server is already owned by another admin
      if (serverData.ownedByAdmin != null &&
          serverData.ownedByAdmin != currentUser.uid) {
        throw Exception('Server is owned by another admin');
      }

      // Add server to admin's management with custom name
      await _firestore.collection(_usersCollection).doc(serverId).update({
        'ownedByAdmin': currentUser.uid,
        'serverName': serverName,
      });

      return true;
    } catch (e) {
      throw Exception('Failed to add server: ${e.toString()}');
    }
  }
}
