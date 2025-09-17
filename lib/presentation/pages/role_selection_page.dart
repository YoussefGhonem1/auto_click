import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/user_role.dart';
import '../../domain/services/auth_service.dart';
import '../../core/utils/snackbar_utils.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  final AuthService _authService = AuthService();
  UserRole? _selectedRole;
  bool _isLoading = false;

  Future<void> _signInWithRole() async {
    if (_selectedRole == null) {
      SnackbarUtils.showError(context, 'Please select a user type');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInAnonymously(role: _selectedRole!);

      if (result != null && mounted) {
        SnackbarUtils.showSuccess(
          context,
          'Successfully logged in as ${_selectedRole!.displayName}!',
        );
      } else if (mounted) {
        SnackbarUtils.showError(context, 'Login failed, please try again');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'An error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo/Icon
                Container(
                  height: 120,
                  width: 120,
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                // Welcome Text
                Text(
                  'Choose user type',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the appropriate role for your account',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    color: onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 48),

                // Role Selection Cards
                _buildRoleCard(
                  role: UserRole.admin,
                  icon: Icons.admin_panel_settings,
                  color: Colors.purple,
                  surface: surface,
                  onSurface: onSurface,
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  role: UserRole.server,
                  icon: Icons.dns,
                  color: Colors.blue,
                  surface: surface,
                  onSurface: onSurface,
                ),
                const SizedBox(height: 48),

                // Continue Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithRole,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: onPrimary,
                      elevation: 2,
                      shadowColor: primaryColor.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.login, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Continue',
                                style: AppTextStyles.body1.copyWith(
                                  color: onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required Color color,
    required Color surface,
    required Color onSurface,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              spreadRadius: isSelected ? 2 : 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.displayName,
                    style: AppTextStyles.heading2.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.description,
                    style: AppTextStyles.subtitle(
                      context,
                    ).copyWith(color: onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
