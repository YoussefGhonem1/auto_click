import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Create or update user with role
  Future<AppUser> createUserWithRole({
    required String uid,
    required UserRole role,
  }) async {
    final user = AppUser(
      uid: uid,
      role: role,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await _firestore.collection(_usersCollection).doc(uid).set(user.toMap());

    return user;
  }

  // Get user by UID
  Future<AppUser?> getUserByUid(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user's last login time
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log error in production apps
    }
  }

  // Update user role (admin only)
  Future<bool> updateUserRole(String uid, UserRole newRole) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'role': newRole.name,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get all users (admin only)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  // Activate/deactivate user (admin only)
  Future<bool> updateUserStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isActive': isActive,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete user (admin only)
  Future<bool> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if user has permission
  Future<bool> hasPermission(String uid, Permission permission) async {
    final user = await getUserByUid(uid);
    if (user == null || !user.isActive) {
      return false;
    }
    return user.role.hasPermission(permission);
  }

  // Get user role
  Future<UserRole?> getUserRole(String uid) async {
    final user = await getUserByUid(uid);
    return user?.role;
  }

  // Connection status management methods

  // Update server connection status
  Future<bool> updateServerConnectionStatus(
    String uid,
    bool isConnected,
  ) async {
    try {
      final user = await getUserByUid(uid);
      if (user == null || user.role != UserRole.server) {
        return false;
      }

      final now = DateTime.now();
      final updateData = <String, dynamic>{'isConnected': isConnected};

      if (isConnected) {
        updateData['lastConnectedAt'] = now.toIso8601String();
      } else {
        updateData['lastDisconnectedAt'] = now.toIso8601String();
      }

      await _firestore.collection(_usersCollection).doc(uid).update(updateData);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get all connected servers
  Future<List<AppUser>> getConnectedServers() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: UserRole.server.name)
          .where('isConnected', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      List<AppUser> data = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
      data = data
          .where(
            (e) =>
                e.lastConnectedAt != null &&
                e.lastConnectedAt!.isAfter(
                  DateTime.now().subtract(const Duration(hours: 3)),
                ),
          )
          .toList();
      return data;
    } catch (e) {
      return [];
    }
  }

  // Get all server users (connected and disconnected)
  Future<List<AppUser>> getAllServers() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: UserRole.server.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  // Listen to server connection status changes
  Stream<List<AppUser>> listenToServerConnectionStatus() {
    return _firestore
        .collection(_usersCollection)
        .where('role', isEqualTo: UserRole.server.name)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList(),
        );
  }

  // Listen to specific server connection status
  Stream<AppUser?> listenToServerStatus(String uid) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Listen to specific server owned by the current admin
  Stream<AppUser?> listenToAdminServerStatus(String uid, String adminUid) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        final server = AppUser.fromMap(doc.data()!);
        // Only return if owned by current admin
        if (server.ownedByAdmin == adminUid) {
          return server;
        }
      }
      return null;
    });
  }

  // Set server as connected (called when app starts)
  Future<void> setServerConnected(String uid) async {
    await updateServerConnectionStatus(uid, true);
  }

  // Set server as disconnected (called when app closes)
  Future<void> setServerDisconnected(String uid) async {
    await updateServerConnectionStatus(uid, false);
  }

  // Get connection statistics for the current admin's servers
  Future<Map<String, int>> getAdminConnectionStatistics(String adminUid) async {
    try {
      final allServers = await getAdminServers(adminUid);

      // Clean up stale connections before calculating statistics
      await _cleanupStaleConnections(allServers);

      final connectedServers = allServers
          .where(
            (user) =>
                user.isConnected &&
                user.lastConnectedAt != null &&
                user.lastConnectedAt!.isAfter(
                  DateTime.now().subtract(const Duration(hours: 3)),
                ),
          )
          .length;
      final totalServers = allServers.length;
      final activeServers = allServers
          .where((server) => server.isActive)
          .length;

      return {
        'total': totalServers,
        'connected': connectedServers,
        'active': activeServers,
      };
    } catch (e) {
      return {'total': 0, 'connected': 0, 'active': 0};
    }
  }

  // Listen to servers owned by the current admin user
  Stream<List<AppUser>> listenToAdminServers(String adminUid) {
    return _firestore
        .collection(_usersCollection)
        .where('role', isEqualTo: UserRole.server.name)
        .where('ownedByAdmin', isEqualTo: adminUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data()))
              .toList();
        });
  }

  // Listen to connected servers owned by the current admin user
  Stream<List<AppUser>> listenToAdminConnectedServers(String adminUid) {
    return _firestore
        .collection(_usersCollection)
        .where('role', isEqualTo: UserRole.server.name)
        .where('ownedByAdmin', isEqualTo: adminUid)
        .where('isConnected', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          List<AppUser> data = snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data()))
              .toList();

          // Filter by recent connection (within last 4 minutes)
          data = data
              .where(
                (e) =>
                    e.lastConnectedAt != null &&
                    e.lastConnectedAt!.isAfter(
                      DateTime.now().subtract(const Duration(hours: 3)),
                    ),
              )
              .toList();

          return data;
        });
  }

  // Get all servers owned by the current admin user
  Future<List<AppUser>> getAdminServers(String adminUid) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: UserRole.server.name)
          .where('ownedByAdmin', isEqualTo: adminUid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all connected servers owned by the current admin user
  Future<List<AppUser>> getAdminConnectedServers(String adminUid) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: UserRole.server.name)
          .where('ownedByAdmin', isEqualTo: adminUid)
          .where('isConnected', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      List<AppUser> data = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();

      // Filter by recent connection (within last 4 minutes)
      data = data
          .where(
            (e) =>
                e.lastConnectedAt != null &&
                e.lastConnectedAt!.isAfter(
                  DateTime.now().subtract(const Duration(hours: 3)),
                ),
          )
          .toList();

      return data;
    } catch (e) {
      return [];
    }
  }

  // Clean up stale connections by setting isConnected to false for servers
  // that have been inactive for more than 10 minutes
  Future<void> _cleanupStaleConnections(List<AppUser> servers) async {
    final staleThreshold = DateTime.now().subtract(const Duration(hours: 3));

    for (final server in servers) {
      if (server.isConnected &&
          (server.lastConnectedAt == null ||
              server.lastConnectedAt!.isBefore(staleThreshold))) {
        try {
          await _firestore.collection(_usersCollection).doc(server.uid).update({
            'isConnected': false,
            'lastDisconnectedAt': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // Log error but continue with other servers
          print('Failed to cleanup stale connection for ${server.uid}: $e');
        }
      }
    }
  }
}
