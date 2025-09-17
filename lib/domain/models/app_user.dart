import 'user_role.dart';

class AppUser {
  final String uid;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final bool isConnected;
  final DateTime? lastConnectedAt;
  final DateTime? lastDisconnectedAt;
  final String? serverName; // New field for server name
  final String? ownedByAdmin; // New field to track which admin owns this server

  const AppUser({
    required this.uid,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.isConnected = false,
    this.lastConnectedAt,
    this.lastDisconnectedAt,
    this.serverName,
    this.ownedByAdmin,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'isConnected': isConnected,
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
      'lastDisconnectedAt': lastDisconnectedAt?.toIso8601String(),
      'serverName': serverName,
      'ownedByAdmin': ownedByAdmin,
    };
  }

  // Create from Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.server, // Default to server if role not found
      ),
      createdAt: DateTime.parse(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'])
          : null,
      isActive: map['isActive'] ?? true,
      isConnected: map['isConnected'] ?? false,
      lastConnectedAt: map['lastConnectedAt'] != null
          ? DateTime.parse(map['lastConnectedAt'])
          : null,
      lastDisconnectedAt: map['lastDisconnectedAt'] != null
          ? DateTime.parse(map['lastDisconnectedAt'])
          : null,
      serverName: map['serverName'],
      ownedByAdmin: map['ownedByAdmin'],
    );
  }

  AppUser copyWith({
    String? uid,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    bool? isConnected,
    DateTime? lastConnectedAt,
    DateTime? lastDisconnectedAt,
    String? serverName,
    String? ownedByAdmin,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      isConnected: isConnected ?? this.isConnected,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      lastDisconnectedAt: lastDisconnectedAt ?? this.lastDisconnectedAt,
      serverName: serverName ?? this.serverName,
      ownedByAdmin: ownedByAdmin ?? this.ownedByAdmin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          role == other.role &&
          createdAt == other.createdAt &&
          lastLoginAt == other.lastLoginAt &&
          isActive == other.isActive &&
          isConnected == other.isConnected &&
          lastConnectedAt == other.lastConnectedAt &&
          lastDisconnectedAt == other.lastDisconnectedAt &&
          serverName == other.serverName &&
          ownedByAdmin == other.ownedByAdmin;

  @override
  int get hashCode =>
      uid.hashCode ^
      role.hashCode ^
      createdAt.hashCode ^
      lastLoginAt.hashCode ^
      isActive.hashCode ^
      isConnected.hashCode ^
      lastConnectedAt.hashCode ^
      lastDisconnectedAt.hashCode ^
      serverName.hashCode ^
      ownedByAdmin.hashCode;

  @override
  String toString() {
    return 'AppUser{uid: $uid, role: $role, createdAt: $createdAt, lastLoginAt: $lastLoginAt, isActive: $isActive, isConnected: $isConnected, lastConnectedAt: $lastConnectedAt, lastDisconnectedAt: $lastDisconnectedAt, serverName: $serverName, ownedByAdmin: $ownedByAdmin}';
  }
}
