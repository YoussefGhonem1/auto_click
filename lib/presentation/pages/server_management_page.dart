import 'package:flutter/material.dart';
import 'dart:async';
import '../../domain/models/app_user.dart';
import '../../domain/services/server_management_service.dart';
import '../../domain/services/qr_code_service.dart';
import '../../domain/services/qr_scanner_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/theme/app_theme.dart';

class ServerManagementPage extends StatefulWidget {
  const ServerManagementPage({super.key});

  @override
  State<ServerManagementPage> createState() => _ServerManagementPageState();
}

class _ServerManagementPageState extends State<ServerManagementPage> {
  final ServerManagementService _serverService = ServerManagementService();
  final TextEditingController _searchController = TextEditingController();

  List<AppUser> _servers = [];
  List<AppUser> _filteredServers = [];
  bool _isLoading = true;
  StreamSubscription? _serversSubscription;
  Map<String, int> _serverStats = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadServers();
    _loadServerStats();
    _listenToServersChanges();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _serversSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final servers = await _serverService.getAdminServers();
      setState(() {
        _servers = servers;
        _filteredServers = servers;
        _isLoading = false;
      });
      _filterServers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to load servers');
      }
    }
  }

  Future<void> _loadServerStats() async {
    final stats = await _serverService.getAdminServerStatistics();
    setState(() {
      _serverStats = stats;
    });
  }

  void _listenToServersChanges() {
    _serversSubscription = _serverService.listenToAdminServers().listen((
      servers,
    ) {
      setState(() {
        _servers = servers;
      });
      _filterServers();
      _loadServerStats();
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
    _filterServers();
  }

  void _filterServers() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredServers = _servers;
      } else {
        _filteredServers = _servers.where((server) {
          final serverName = (server.serverName ?? '').toLowerCase();
          final serverId = server.uid.toLowerCase();
          return serverName.contains(_searchQuery) ||
              serverId.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _addServer() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const AddServerDialog(),
    );

    if (result != null) {
      try {
        final success = await _serverService.createServer(
          serverId: result['serverId']!,
          serverName: result['serverName']!,
        );

        if (success && mounted) {
          SnackbarUtils.showSuccess(context, 'Server created successfully');
          _showQRCodeDialog(result['serverId']!);
        } else {
          if (mounted) {
            SnackbarUtils.showError(context, 'Failed to create server');
          }
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(context, 'Error: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _scanServerQRCode() async {
    try {
      final serverId = await QRScannerService.scanServerRegistrationQRCode(
        context,
      );
      if (serverId != null && mounted) {
        SnackbarUtils.showSuccess(context, 'Server added successfully');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Failed to add server: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _editServer(AppUser server) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditServerDialog(server: server),
    );

    if (result != null) {
      try {
        final success = await _serverService.updateServer(
          serverId: server.uid,
          serverName: result['serverName'] as String?,
          isActive: result['isActive'] as bool?,
        );

        if (success && mounted) {
          SnackbarUtils.showSuccess(context, 'Server updated successfully');
        } else {
          if (mounted) {
            SnackbarUtils.showError(context, 'Failed to update server');
          }
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(context, 'Error: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _deleteServer(AppUser server) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Server',
          style: AppTextStyles.heading1.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete the server "${server.serverName ?? server.uid}"?',
          style: AppTextStyles.subtitle(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.body1.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getErrorColor(context),
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(
              'Delete',
              style: AppTextStyles.body1.copyWith(
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _serverService.deleteServer(server.uid);
        if (success && mounted) {
          SnackbarUtils.showSuccess(context, 'Server deleted successfully');
        } else {
          if (mounted) {
            SnackbarUtils.showError(context, 'Failed to delete server');
          }
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(context, 'Error: ${e.toString()}');
        }
      }
    }
  }

  void _showQRCodeDialog(String serverId) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            'Server QR Code',
            style: AppTextStyles.heading1.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          content: QRCodeService.generateServerQRCode(serverId),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: AppTextStyles.body1.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Management'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadServers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Cards
                _buildStatisticsCards(),
                const SizedBox(height: 16),

                // Search Bar
                _buildSearchBar(),
                const SizedBox(height: 16),

                // Servers List
                Expanded(
                  child: _filteredServers.isEmpty
                      ? _buildEmptyState()
                      : _buildServersList(),
                ),
              ],
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _scanServerQRCode,
            heroTag: 'scan_qr',
            tooltip: 'Scan server QR code',
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            onPressed: _addServer,
            heroTag: 'add_server',
            icon: const Icon(Icons.add),
            label: const Text('Add Server'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total Servers',
              value: _serverStats['total']?.toString() ?? '0',
              icon: Icons.dns,
              color: AppColors.getInfoColor(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              title: 'Connected',
              value: _serverStats['connected']?.toString() ?? '0',
              icon: Icons.link,
              color: AppColors.getConnectedColor(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              title: 'Active',
              value: _serverStats['active']?.toString() ?? '0',
              icon: Icons.check_circle,
              color: AppColors.getSuccessColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.caption(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final isSearching = _searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.dns_outlined,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No results found' : 'No servers',
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try different search terms'
                : 'Click the add button to create a new server',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search servers...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildServersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredServers.length,
      itemBuilder: (context, index) {
        final server = _filteredServers[index];
        return _buildServerCard(server);
      },
    );
  }

  Widget _buildServerCard(AppUser server) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _isServerReallyConnected(server)
                      ? AppColors.getConnectedBackgroundColor(context)
                      : AppColors.getDisconnectedBackgroundColor(context),
                  child: Icon(
                    Icons.dns,
                    color: _isServerReallyConnected(server)
                        ? AppColors.getConnectedColor(context)
                        : AppColors.getDisconnectedColor(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (server.serverName != null)
                        Text(
                          server.serverName!,
                          style: AppTextStyles.heading1.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      Text(
                        server.uid,
                        style: AppTextStyles.body1.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Connection Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isServerReallyConnected(server)
                        ? AppColors.getConnectedBackgroundColor(context)
                        : AppColors.getDisconnectedBackgroundColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isServerReallyConnected(server)
                            ? Icons.link
                            : Icons.link_off,
                        size: 12,
                        color: _isServerReallyConnected(server)
                            ? AppColors.getConnectedColor(context)
                            : AppColors.getDisconnectedColor(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isServerReallyConnected(server)
                            ? 'Connected'
                            : 'Disconnected',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isServerReallyConnected(server)
                              ? AppColors.getConnectedColor(context)
                              : AppColors.getDisconnectedColor(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Status and dates
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: server.isActive
                        ? AppColors.getSuccessColor(
                            context,
                          ).withValues(alpha: 0.2)
                        : AppColors.getErrorColor(
                            context,
                          ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    server.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: server.isActive
                          ? AppColors.getSuccessColor(context)
                          : AppColors.getErrorColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Created on: ${_formatDate(server.createdAt)}',
                  style: AppTextStyles.caption(context),
                ),
              ],
            ),

            if (server.lastConnectedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last connection: ${_formatDateTime(server.lastConnectedAt!)}',
                style: AppTextStyles.caption(context),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editServer(server),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteServer(server),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.getErrorColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Check if server is really connected (same logic as statistics)
  bool _isServerReallyConnected(AppUser server) {
    return server.isConnected &&
        server.lastConnectedAt != null &&
        server.lastConnectedAt!.isAfter(
          DateTime.now().subtract(const Duration(hours: 3)),
        );
  }
}

// Add Server Dialog
class AddServerDialog extends StatefulWidget {
  const AddServerDialog({super.key});

  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serverIdController = TextEditingController();
  final _serverNameController = TextEditingController();

  @override
  void dispose() {
    _serverIdController.dispose();
    _serverNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Add New Server',
        style: AppTextStyles.heading1.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _serverIdController,
              decoration: const InputDecoration(
                labelText: 'Server ID',
                hintText: 'Enter a unique server ID',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a server ID';
                }
                if (value.length < 3) {
                  return 'Server ID must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serverNameController,
              decoration: const InputDecoration(
                labelText: 'Server Name',
                hintText: 'Enter server name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a server name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'serverId': _serverIdController.text.trim(),
                'serverName': _serverNameController.text.trim(),
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Edit Server Dialog
class EditServerDialog extends StatefulWidget {
  final AppUser server;

  const EditServerDialog({super.key, required this.server});

  @override
  State<EditServerDialog> createState() => _EditServerDialogState();
}

class _EditServerDialogState extends State<EditServerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _serverNameController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _serverNameController = TextEditingController(
      text: widget.server.serverName,
    );
    _isActive = widget.server.isActive;
  }

  @override
  void dispose() {
    _serverNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Edit Server',
        style: AppTextStyles.heading1.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _serverNameController,
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                labelText: 'Server Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a server name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? false;
                    });
                  },
                ),
                Text(
                  'Active',
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'serverName': _serverNameController.text.trim(),
                'isActive': _isActive,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
