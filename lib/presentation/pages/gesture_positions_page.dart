import 'package:flutter/material.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../domain/services/gesture_config_service.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/gesture_positions/positions_tab.dart';
import '../widgets/gesture_positions/durations_tab.dart';
import '../../data/data_sources/local_datasource/gesture_positions.dart';

class GesturePositionsPage extends StatefulWidget {
  const GesturePositionsPage({super.key});

  @override
  State<GesturePositionsPage> createState() => _GesturePositionsPageState();
}

class _GesturePositionsPageState extends State<GesturePositionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GestureConfigService _configService = GestureConfigService();
  final AuthService _authService = AuthService();
  Map<String, dynamic> _positions = {};
  Map<String, int> _durations = {};
  bool _hasChanges = false;
  bool _isLoading = true;
  bool _useGlobalConfig = true;
  UserRole? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentValues();
  }

  Future<void> _loadCurrentValues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load current user role
      _currentUserRole = await _authService.getCurrentUserRole();

      // Load global config preference
      _useGlobalConfig = await _configService.shouldUseGlobalConfig();

      // Load current gesture positions
      _positions = await _configService.loadGesturePositions();

      // Load current durations
      _durations = await _configService.loadDurations();
      // Ensure swapDuration is present
      _durations.putIfAbsent('swapDuration', () => swapTime);
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to load settings: $e');
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      final positionsSaved = await _configService.saveGesturePositions(
        _positions,
      );
      final durationsSaved = await _configService.saveDurations(_durations);

      if (positionsSaved && durationsSaved) {
        SnackbarUtils.showSuccess(context, 'Changes saved successfully');
        setState(() {
          _hasChanges = false;
        });
      } else {
        SnackbarUtils.showError(context, 'Failed to save some settings');
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to save changes: $e');
    }
  }

  Future<void> _resetToDefaults() async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _currentUserRole == UserRole.admin
              ? 'Reset global settings'
              : 'Reset default values',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          _currentUserRole == UserRole.admin
              ? 'Are you sure you want to reset all global settings to default values? This will affect all devices.'
              : 'Are you sure you want to reset all values to default settings?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getWarningColor(context),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _configService.resetToDefaults();
        if (success) {
          await _loadCurrentValues();
          // Ensure swapDuration is present after reset
          setState(() {
            _durations.putIfAbsent('swapDuration', () => swapTime);
          });
          setState(() {
            _hasChanges = false;
          });
          SnackbarUtils.showSuccess(
            context,
            'Default values reset successfully',
          );
        } else {
          SnackbarUtils.showError(context, 'Failed to reset default values');
        }
      } catch (e) {
        SnackbarUtils.showError(context, 'An error occurred: $e');
      }
    }
  }

  Future<void> _toggleGlobalConfig() async {
    if (_currentUserRole == UserRole.admin) {
      // Admins cannot disable global config
      SnackbarUtils.showInfo(context, 'Admins always use global settings');
      return;
    }

    try {
      final newValue = !_useGlobalConfig;
      await _configService.setUseGlobalConfig(newValue);
      setState(() {
        _useGlobalConfig = newValue;
      });

      // Reload configurations
      await _loadCurrentValues();

      SnackbarUtils.showSuccess(
        context,
        newValue ? 'Switched to global settings' : 'Switched to local settings',
      );
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to change setting type: $e');
    }
  }

  void _updatePosition(String key, String coordinate, String value) {
    final doubleValue = double.tryParse(value);
    if (doubleValue != null && doubleValue >= 0.0) {
      setState(() {
        _positions[key][coordinate] = doubleValue;
        _hasChanges = true;
      });
    }
  }

  void _updateGesture(
    String key,
    String point,
    String coordinate,
    String value,
  ) {
    final doubleValue = double.tryParse(value);
    if (doubleValue != null && doubleValue >= 0.0) {
      setState(() {
        _positions[key][point][coordinate] = doubleValue;
        _hasChanges = true;
      });
    }
  }

  void _updateAccountPosition(
    String accountKey,
    String coordinate,
    String value,
  ) {
    final doubleValue = double.tryParse(value);
    if (doubleValue != null && doubleValue >= 0.0) {
      setState(() {
        _positions['account_positions'][accountKey][coordinate] = doubleValue;
        _hasChanges = true;
      });
    }
  }

  void _updateDuration(String key, String value) {
    final intValue = int.tryParse(value);
    if (intValue != null && intValue > 0) {
      setState(() {
        _durations[key] = intValue;
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gesture Settings'),
        centerTitle: true,
        actions: [
          if (_hasChanges)
            IconButton(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              tooltip: 'Save changes',
            ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _resetToDefaults,
                child: const Row(
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('Reset to defaults'),
                  ],
                ),
              ),
              if (_currentUserRole == UserRole.server)
                PopupMenuItem(
                  onTap: _toggleGlobalConfig,
                  child: Row(
                    children: [
                      Icon(_useGlobalConfig ? Icons.public_off : Icons.public),
                      const SizedBox(width: 8),
                      Text(
                        _useGlobalConfig
                            ? 'Use local settings'
                            : 'Use global settings',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Configuration type indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: _useGlobalConfig
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      _useGlobalConfig ? Icons.public : Icons.phone_android,
                      size: 20,
                      color: _useGlobalConfig ? Colors.blue : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _useGlobalConfig
                            ? (_currentUserRole == UserRole.admin
                                  ? 'Edit global settings (affects all devices)'
                                  : 'Use global settings')
                            : 'Use local settings (only this device)',
                        style: TextStyle(
                          fontSize: 12,
                          color: _useGlobalConfig ? Colors.blue : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_currentUserRole == UserRole.server &&
                        !_useGlobalConfig)
                      TextButton(
                        onPressed: _toggleGlobalConfig,
                        child: const Text(
                          'Switch',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.touch_app), text: 'Gesture Positions'),
                  Tab(icon: Icon(Icons.timer), text: 'Action Durations'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading settings...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                PositionsTab(
                  positions: _positions,
                  onPositionUpdate: _updatePosition,
                  onGestureUpdate: _updateGesture,
                  onAccountPositionUpdate: _updateAccountPosition,
                ),
                DurationsTab(
                  durations: _durations,
                  onDurationUpdate: _updateDuration,
                ),
              ],
            ),
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: Text(
                _currentUserRole == UserRole.admin
                    ? 'Save global settings'
                    : 'Save changes',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
    );
  }
}
