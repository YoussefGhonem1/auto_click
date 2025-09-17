import 'package:flutter/material.dart';
import 'info_cards.dart';
import 'duration_card.dart';

class DurationsTab extends StatelessWidget {
  final Map<String, int> durations;
  final Function(String, String) onDurationUpdate;

  const DurationsTab({
    super.key,
    required this.durations,
    required this.onDurationUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DurationsInfoCard(),
          const SizedBox(height: 16),
          _buildDurationsList(),
        ],
      ),
    );
  }

  Widget _buildDurationsList() {
    return Column(
      children: durations.entries.map((entry) {
        return DurationCard(
          configKey: entry.key,
          duration: entry.value,
          onUpdate: onDurationUpdate,
        );
      }).toList(),
    );
  }
}
