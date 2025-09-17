import 'package:flutter/material.dart';
import '../../domain/models/gesture_position.dart';
import '../../core/theme/app_theme.dart';
import 'section_card.dart';

class GesturePositionsSection extends StatelessWidget {
  final List<GesturePosition> gesturePositions;
  final VoidCallback onEdit;

  const GesturePositionsSection({
    super.key,
    required this.gesturePositions,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Gesture Positions',
      icon: Icons.touch_app,
      iconColor: AppColors.getGestureColor(context),
      subtitle: 'Touch points that make up automation',
      trailing: IconButton(
        onPressed: onEdit,
        icon: Icon(
          Icons.edit_note_outlined,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
