import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../domain/models/user_role.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserRole? currentUserRole;
  final VoidCallback onLogout;
  final VoidCallback? onTaskHistory;

  const HomeAppBar({
    super.key,
    required this.currentUserRole,
    required this.onLogout,
    this.onTaskHistory,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'TikTok Automation Tools',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevation: 0,
      centerTitle: true,
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            if (currentUserRole == UserRole.admin && onTaskHistory != null)
              PopupMenuItem(
                onTap: onTaskHistory,
                child: const Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Task History'),
                  ],
                ),
              ),
            PopupMenuItem(
              onTap: onLogout,
              child: const Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Sign Out'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
