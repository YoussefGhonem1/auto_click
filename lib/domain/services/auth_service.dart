import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current app user with role
  Future<AppUser?> get currentAppUser async {
    if (currentUser == null) return null;
    return await _userService.getUserByUid(currentUser!.uid);
  }

  // Sign in anonymously with role
  Future<UserCredential?> signInAnonymously({
    UserRole role = UserRole.server,
  }) async {
    try {
      UserCredential result = await _auth.signInAnonymously();

      if (result.user != null) {
        // Check if user already exists
        final existingUser = await _userService.getUserByUid(result.user!.uid);

        if (existingUser == null) {
          // Create new user with selected role
          await _userService.createUserWithRole(
            uid: result.user!.uid,
            role: role,
          );
        } else {
          // Update existing user's role to the newly selected role and last login time
          await _userService.updateUserRole(result.user!.uid, role);
          await _userService.updateLastLogin(result.user!.uid);
        }
      }

      return result;
    } catch (e) {
      // Log error in production apps, use a proper logging solution
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _userService.updateServerConnectionStatus(currentUser!.uid, false);
      await _auth.signOut();
    } catch (e) {
      // Log error in production apps, use a proper logging solution
    }
  }

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get user ID
  String? get userId => currentUser?.uid;

  // Delete current user account
  Future<bool> deleteAccount() async {
    try {
      if (currentUser != null) {
        await _userService.deleteUser(currentUser!.uid);
        await currentUser?.delete();
      }
      return true;
    } catch (e) {
      // Log error in production apps, use a proper logging solution
      return false;
    }
  }

  // Check if current user has permission
  Future<bool> hasPermission(Permission permission) async {
    if (currentUser == null) return false;
    return await _userService.hasPermission(currentUser!.uid, permission);
  }

  // Get current user role
  Future<UserRole?> getCurrentUserRole() async {
    if (currentUser == null) return null;
    return await _userService.getUserRole(currentUser!.uid);
  }

  // Get user service for admin operations
  UserService get userService => _userService;
}
