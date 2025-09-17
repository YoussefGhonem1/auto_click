import 'package:auto_click/presentation/pages/server_management_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../domain/services/connection_monitoring_service.dart';
import '../../core/theme/app_theme.dart';

class ServerConnectionStatus extends StatefulWidget {
  const ServerConnectionStatus({super.key});

  @override
  State<ServerConnectionStatus> createState() => _ServerConnectionStatusState();
}

class _ServerConnectionStatusState extends State<ServerConnectionStatus> {
  final ConnectionMonitoringService _connectionService =
      ConnectionMonitoringService();
  StreamSubscription? _connectionSubscription;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _listenToConnectionChanges();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final stats = await _connectionService.getConnectionStatistics();

    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  void _listenToConnectionChanges() {
    _connectionSubscription = _connectionService
        .getConnectionStatusStream()
        .listen((servers) {
          if (mounted) {
            setState(() {});
            _loadStats();
          }
        });
  }

  Future<void> _loadStats() async {
    final stats = await _connectionService.getConnectionStatistics();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dns,
                color: AppColors.getDeviceColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Server Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () {
                  _navigateToServerManagement();
                },
                icon: Icon(
                  Icons.edit_note_outlined,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Connection Statistics
          if (_stats.isNotEmpty)
            Text(
              'Connected Servers: ${_stats['connected']}',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
            ),
        ],
      ),
    );
  }

  void _navigateToServerManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ServerManagementPage()),
    );
  }
}
