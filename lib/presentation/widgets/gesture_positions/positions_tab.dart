import 'package:flutter/material.dart';
import 'info_cards.dart';
import 'position_card.dart';
import 'gesture_card.dart';
import 'account_positions_card.dart';

class PositionsTab extends StatelessWidget {
  final Map<String, dynamic> positions;
  final Function(String, String, String) onPositionUpdate;
  final Function(String, String, String, String) onGestureUpdate;
  final Function(String, String, String) onAccountPositionUpdate;

  const PositionsTab({
    super.key,
    required this.positions,
    required this.onPositionUpdate,
    required this.onGestureUpdate,
    required this.onAccountPositionUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PositionsInfoCard(),
          const SizedBox(height: 16),
          _buildPositionsList(),
        ],
      ),
    );
  }

  Widget _buildPositionsList() {
    return Column(
      children: positions.entries.map((entry) {
        if (entry.key == 'account_positions') {
          return AccountPositionsCard(
            configKey: entry.key,
            accounts: entry.value,
            onUpdate: onAccountPositionUpdate,
          );
        } else if (entry.value is Map && entry.value.containsKey('start')) {
          return GestureCard(
            configKey: entry.key,
            gesture: entry.value,
            onUpdate: onGestureUpdate,
          );
        } else if (entry.value is Map && entry.value.containsKey('x')) {
          return PositionCard(
            configKey: entry.key,
            position: entry.value,
            onUpdate: onPositionUpdate,
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}
