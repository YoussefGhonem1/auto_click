import 'package:flutter/material.dart';

class TaskOption {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const TaskOption({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
