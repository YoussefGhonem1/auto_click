enum UserRole {
  admin,
  server;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.server:
        return 'Server';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'System Administrator - Full permissions to manage the application and users';
      case UserRole.server:
        return 'Server - Limited permissions for automated task execution only';
    }
  }

  List<Permission> get permissions {
    switch (this) {
      case UserRole.admin:
        return Permission.values; // All permissions
      case UserRole.server:
        return [Permission.executeAutomation, Permission.viewDeviceStatus];
    }
  }

  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }
}

enum Permission {
  executeAutomation,
  viewDeviceStatus,
  manageGesturePositions,
  manageUsers,
  viewLogs,
  manageSettings;

  String get displayName {
    switch (this) {
      case Permission.executeAutomation:
        return 'Execute Automation';
      case Permission.viewDeviceStatus:
        return 'View Device Status';
      case Permission.manageGesturePositions:
        return 'Manage Gesture Positions';
      case Permission.manageUsers:
        return 'Manage Users';
      case Permission.viewLogs:
        return 'View Logs';
      case Permission.manageSettings:
        return 'Manage Settings';
    }
  }
}
