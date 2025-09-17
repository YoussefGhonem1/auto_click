import 'package:flutter/material.dart';
import '../../domain/models/gesture_position.dart';

class GesturePositionItem extends StatelessWidget {
  final GesturePosition position;

  const GesturePositionItem({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: position.isActive ? Colors.purple.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: position.isActive
              ? Colors.purple.shade200
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            position.isActive
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: position.isActive ? Colors.purple : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              position.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '(${position.x}, ${position.y})',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
