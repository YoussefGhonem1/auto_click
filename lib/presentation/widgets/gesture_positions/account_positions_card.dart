import 'package:flutter/material.dart';
import 'coordinate_field.dart';

class AccountPositionsCard extends StatelessWidget {
  final String configKey;
  final Map<String, dynamic> accounts;
  final Function(String, String, String) onUpdate;

  const AccountPositionsCard({
    super.key,
    required this.configKey,
    required this.accounts,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Account Positions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...accounts.entries.map((account) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account ${account.key}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CoordinateField(
                            label: 'X',
                            value: account.value['x']?.toString() ?? '0.0',
                            onChanged: (value) =>
                                onUpdate(account.key, 'x', value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CoordinateField(
                            label: 'Y',
                            value: account.value['y']?.toString() ?? '0.0',
                            onChanged: (value) =>
                                onUpdate(account.key, 'y', value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
