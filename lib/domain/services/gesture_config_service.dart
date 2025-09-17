import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/data_sources/local_datasource/gesture_positions.dart';
import 'global_gesture_config_service.dart';
import 'auth_service.dart';
import '../models/user_role.dart';

class GestureConfigService {
  static const String _positionsKey = 'gesture_positions';
  static const String _durationsKey = 'gesture_durations';
  static const String _versionKey = 'config_version';
  static const String _useGlobalConfigKey = 'use_global_config';
  static const String _currentVersion = '1.0.0';
  static const String _configsCollection = 'gesture_configs';

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalGestureConfigService _globalConfigService =
      GlobalGestureConfigService();
  final AuthService _authService = AuthService();

  // Singleton pattern for service
  static final GestureConfigService _instance =
      GestureConfigService._internal();
  factory GestureConfigService() => _instance;
  GestureConfigService._internal();

  // Cache for loaded data
  Map<String, dynamic>? _cachedPositions;
  Map<String, int>? _cachedDurations;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Check if user should use global configuration
  Future<bool> shouldUseGlobalConfig() async {
    try {
      // Check user role
      final currentUserRole = await _authService.getCurrentUserRole();

      // For admin users, always use global config by default
      if (currentUserRole == UserRole.admin) {
        return true;
      }

      // For server users, check preference or use global by default
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_useGlobalConfigKey) ?? true;
    } catch (e) {
      return true; // Default to global config
    }
  }

  /// Set preference for using global configuration
  Future<void> setUseGlobalConfig(bool useGlobal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useGlobalConfigKey, useGlobal);

      // Clear cache to force reload
      clearCache();
    } catch (e) {
      // Handle error
    }
  }

  /// Load current gesture positions (prioritizes global if enabled)
  Future<Map<String, dynamic>> loadGesturePositions() async {
    // if (_cachedPositions != null) {
    //   return Map<String, dynamic>.from(_cachedPositions!);
    // }

    try {
      // Check if should use global configuration
      final useGlobal = await shouldUseGlobalConfig();

      if (useGlobal) {
        // Load from global configuration
        final globalPositions = await _globalConfigService
            .loadGlobalGesturePositions();
        _cachedPositions = globalPositions;
        return Map<String, dynamic>.from(_cachedPositions!);
      }

      // Try to load from user-specific Firestore first
      if (_userId != null) {
        final firestoreData = await _loadPositionsFromFirestore();
        if (firestoreData != null) {
          _cachedPositions = _validateAndFixPositions(firestoreData);
          // Cache to local storage
          await _savePositionsToPrefs(_cachedPositions!);
          return Map<String, dynamic>.from(_cachedPositions!);
        }
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final positionsJson = prefs.getString(_positionsKey);

      if (positionsJson != null) {
        final decoded = jsonDecode(positionsJson) as Map<String, dynamic>;
        _cachedPositions = _validateAndFixPositions(decoded);
      } else {
        _cachedPositions = Map<String, dynamic>.from(defaultGesturePositions);
        await _savePositionsToPrefs(_cachedPositions!);
      }

      return Map<String, dynamic>.from(_cachedPositions!);
    } catch (e) {
      // Fallback to defaults if loading fails
      _cachedPositions = Map<String, dynamic>.from(defaultGesturePositions);
      return Map<String, dynamic>.from(_cachedPositions!);
    }
  }

  /// Load current durations (prioritizes global if enabled)
  Future<Map<String, int>> loadDurations() async {
    // if (_cachedDurations != null) {
    //   return Map<String, int>.from(_cachedDurations!);
    // }

    try {
      // Check if should use global configuration
      final useGlobal = await shouldUseGlobalConfig();

      if (useGlobal) {
        // Load from global configuration
        final globalDurations = await _globalConfigService
            .loadGlobalDurations();
        _cachedDurations = globalDurations;
        return Map<String, int>.from(_cachedDurations!);
      }

      // Try to load from user-specific Firestore first
      if (_userId != null) {
        final firestoreData = await _loadDurationsFromFirestore();
        if (firestoreData != null) {
          _cachedDurations = _validateAndFixDurations(firestoreData);
          // Cache to local storage
          await _saveDurationsToPrefs(_cachedDurations!);
          return Map<String, int>.from(_cachedDurations!);
        }
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final durationsJson = prefs.getString(_durationsKey);

      if (durationsJson != null) {
        final decoded = jsonDecode(durationsJson) as Map<String, dynamic>;
        _cachedDurations = _validateAndFixDurations(decoded);
      } else {
        _cachedDurations = {
          'defaultWaitTime': defaultWaitTime,
          'videoLoadTime': videoLoadTime,
          'videoWatchTime': videoWatchTime,
          'switchAccountTime': switchAccountTime,
          'swapDuration': swapTime,
          'maxTaskDuration': maxTaskDuration,
        };
        await _saveDurationsToPrefs(_cachedDurations!);
      }

      return Map<String, int>.from(_cachedDurations!);
    } catch (e) {
      // Fallback to defaults if loading fails
      _cachedDurations = {
        'defaultWaitTime': defaultWaitTime,
        'videoLoadTime': videoLoadTime,
        'videoWatchTime': videoWatchTime,
        'switchAccountTime': switchAccountTime,
        'swapDuration': swapTime,
        'maxTaskDuration': maxTaskDuration,
      };
      return Map<String, int>.from(_cachedDurations!);
    }
  }

  /// Save gesture positions (saves to global if admin, local if server with override)
  Future<bool> saveGesturePositions(Map<String, dynamic> positions) async {
    try {
      final validatedPositions = _validateAndFixPositions(positions);
      final currentUserRole = await _authService.getCurrentUserRole();

      // Admin users save to global configuration
      if (currentUserRole == UserRole.admin) {
        final success = await _globalConfigService.saveGlobalGesturePositions(
          validatedPositions,
        );
        if (success) {
          _cachedPositions = validatedPositions;
          return true;
        }
        return false;
      }

      // Server users save locally (if they have local override enabled)
      final useGlobal = await shouldUseGlobalConfig();
      if (useGlobal) {
        // Cannot save to global as server user
        throw Exception('Server users cannot modify global configuration');
      }

      // Save to user-specific Firestore first
      bool firestoreSuccess = true;
      if (_userId != null) {
        firestoreSuccess = await _savePositionsToFirestore(validatedPositions);
      }

      // Save to SharedPreferences (as cache/fallback)
      final prefsSuccess = await _savePositionsToPrefs(validatedPositions);

      if (firestoreSuccess && prefsSuccess) {
        _cachedPositions = validatedPositions;
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Save durations (saves to global if admin, local if server with override)
  Future<bool> saveDurations(Map<String, int> durations) async {
    try {
      final validatedDurations = _validateAndFixDurations(durations);
      final currentUserRole = await _authService.getCurrentUserRole();

      // Admin users save to global configuration
      if (currentUserRole == UserRole.admin) {
        final success = await _globalConfigService.saveGlobalDurations(
          validatedDurations,
        );
        if (success) {
          _cachedDurations = validatedDurations;
          return true;
        }
        return false;
      }

      // Server users save locally (if they have local override enabled)
      final useGlobal = await shouldUseGlobalConfig();
      if (useGlobal) {
        // Cannot save to global as server user
        throw Exception('Server users cannot modify global configuration');
      }

      // Save to user-specific Firestore first
      bool firestoreSuccess = true;
      if (_userId != null) {
        firestoreSuccess = await _saveDurationsToFirestore(validatedDurations);
      }

      // Save to SharedPreferences (as cache/fallback)
      final prefsSuccess = await _saveDurationsToPrefs(validatedDurations);

      if (firestoreSuccess && prefsSuccess) {
        _cachedDurations = validatedDurations;
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Reset to default values
  Future<bool> resetToDefaults() async {
    try {
      final currentUserRole = await _authService.getCurrentUserRole();

      // Admin users reset global configuration
      if (currentUserRole == UserRole.admin) {
        final success = await _globalConfigService.resetGlobalToDefaults();
        if (success) {
          // Clear cache to force reload
          clearCache();
          return true;
        }
        return false;
      }

      // Server users reset their local configuration
      final defaultPositions = Map<String, dynamic>.from(
        defaultGesturePositions,
      );
      final defaultDurs = {
        'defaultWaitTime': defaultWaitTime,
        'videoLoadTime': videoLoadTime,
        'videoWatchTime': videoWatchTime,
        'switchAccountTime': switchAccountTime,
        'swapDuration': swapTime,
        'maxTaskDuration': maxTaskDuration,
      };

      final positionsSaved = await saveGesturePositions(defaultPositions);
      final durationsSaved = await saveDurations(defaultDurs);

      // Clear cache to force reload
      clearCache();

      return positionsSaved && durationsSaved;
    } catch (e) {
      return false;
    }
  }

  /// Clear all cached data and force reload
  void clearCache() {
    _cachedPositions = null;
    _cachedDurations = null;
    // Also clear global service cache
    _globalConfigService.clearCache();
  }

  /// Validate coordinate value (should be any positive number)
  bool isValidCoordinate(double value) {
    return value >= 0.0 && !value.isNaN && value.isFinite;
  }

  /// Validate duration value (should be positive)
  bool isValidDuration(int value) {
    return value > 0 &&
        value <= 600000; // Max 10 minutes (allows maxTaskDuration of 5 minutes)
  }

  /// Export configuration as JSON string
  Future<String> exportConfiguration() async {
    try {
      final positions = await loadGesturePositions();
      final durations = await loadDurations();
      final useGlobal = await shouldUseGlobalConfig();
      final currentUserRole = await _authService.getCurrentUserRole();

      final config = {
        'positions': positions,
        'durations': durations,
        'version': _currentVersion,
        'exportDate': DateTime.now().toIso8601String(),
        'appName': 'Auto Click TikTok',
        'userId': _userId,
        'configType': useGlobal ? 'global' : 'local',
        'userRole': currentUserRole?.name,
      };

      return jsonEncode(config);
    } catch (e) {
      throw Exception('Failed to export settings: $e');
    }
  }

  /// Import configuration from JSON string
  Future<bool> importConfiguration(String jsonString) async {
    try {
      final config = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate the configuration structure
      if (!_isValidConfigStructure(config)) {
        throw Exception('Invalid file format');
      }

      final positions = config['positions'] as Map<String, dynamic>;
      final durations = Map<String, int>.from(config['durations']);
      final currentUserRole = await _authService.getCurrentUserRole();

      // Check if this is a global config and user is admin
      final configType = config['configType'] as String?;
      if (configType == 'global' && currentUserRole == UserRole.admin) {
        // Import to global configuration
        final success = await _globalConfigService.importGlobalConfiguration(
          jsonString,
        );
        if (success) {
          clearCache();
          return true;
        }
        return false;
      }

      // Import to local configuration
      final positionsSaved = await saveGesturePositions(positions);
      final durationsSaved = await saveDurations(durations);

      if (positionsSaved && durationsSaved) {
        // Update version info
        if (_userId != null) {
          await _updateVersionInFirestore(config['version'] ?? _currentVersion);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _versionKey,
          config['version'] ?? _currentVersion,
        );

        // Clear cache to force reload
        clearCache();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get configuration version
  Future<String> getConfigVersion() async {
    try {
      final useGlobal = await shouldUseGlobalConfig();

      if (useGlobal) {
        return await _globalConfigService.getGlobalConfigVersion();
      }

      // Try to get from Firestore first
      if (_userId != null) {
        final firestoreVersion = await _getVersionFromFirestore();
        if (firestoreVersion != null) {
          return firestoreVersion;
        }
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_versionKey) ?? _currentVersion;
    } catch (e) {
      return _currentVersion;
    }
  }

  /// Check if configuration exists
  Future<bool> hasCustomConfiguration() async {
    try {
      final useGlobal = await shouldUseGlobalConfig();

      if (useGlobal) {
        return await _globalConfigService.hasGlobalConfiguration();
      }

      // Check user-specific Firestore first
      if (_userId != null) {
        final hasFirestoreConfig = await _hasFirestoreConfiguration();
        if (hasFirestoreConfig) {
          return true;
        }
      }

      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_positionsKey) ||
          prefs.containsKey(_durationsKey);
    } catch (e) {
      return false;
    }
  }

  /// Sync local data to Firestore (useful when user logs in)
  Future<bool> syncLocalToFirestore() async {
    if (_userId == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Sync positions
      final positionsJson = prefs.getString(_positionsKey);
      if (positionsJson != null) {
        final positions = jsonDecode(positionsJson) as Map<String, dynamic>;
        await _savePositionsToFirestore(positions);
      }

      // Sync durations
      final durationsJson = prefs.getString(_durationsKey);
      if (durationsJson != null) {
        final durations = jsonDecode(durationsJson) as Map<String, dynamic>;
        await _saveDurationsToFirestore(durations);
      }

      // Sync version
      final version = prefs.getString(_versionKey);
      if (version != null) {
        await _updateVersionInFirestore(version);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Private Firestore methods (for user-specific configurations)

  Future<Map<String, dynamic>?> _loadPositionsFromFirestore() async {
    try {
      if (_userId == null) return null;

      final doc = await _firestore
          .collection(_configsCollection)
          .doc(_userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return data['positions'] as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadDurationsFromFirestore() async {
    try {
      if (_userId == null) return null;

      final doc = await _firestore
          .collection(_configsCollection)
          .doc(_userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return data['durations'] as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _savePositionsToFirestore(Map<String, dynamic> positions) async {
    try {
      if (_userId == null) return false;

      await _firestore.collection(_configsCollection).doc(_userId).set({
        'positions': positions,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': _currentVersion,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _saveDurationsToFirestore(Map<String, dynamic> durations) async {
    try {
      if (_userId == null) return false;

      await _firestore.collection(_configsCollection).doc(_userId).set({
        'durations': durations,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': _currentVersion,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _updateVersionInFirestore(String version) async {
    try {
      if (_userId == null) return false;

      await _firestore.collection(_configsCollection).doc(_userId).set({
        'version': version,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> _getVersionFromFirestore() async {
    try {
      if (_userId == null) return null;

      final doc = await _firestore
          .collection(_configsCollection)
          .doc(_userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return data['version'] as String?;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _hasFirestoreConfiguration() async {
    try {
      if (_userId == null) return false;

      final doc = await _firestore
          .collection(_configsCollection)
          .doc(_userId)
          .get();

      return doc.exists && doc.data() != null;
    } catch (e) {
      return false;
    }
  }

  // Private SharedPreferences methods (kept for caching)

  Future<bool> _savePositionsToPrefs(Map<String, dynamic> positions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(positions);
      return await prefs.setString(_positionsKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _saveDurationsToPrefs(Map<String, int> durations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(durations);
      return await prefs.setString(_durationsKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  // Private validation methods

  Map<String, dynamic> _validateAndFixPositions(
    Map<String, dynamic> positions,
  ) {
    final validated = <String, dynamic>{};

    for (final entry in positions.entries) {
      final key = entry.key;
      final value = entry.value;

      if (key == 'account_positions' && value is Map) {
        validated[key] = _validateAccountPositions(
          Map<String, dynamic>.from(value),
        );
      } else if (value is Map &&
          value.containsKey('start') &&
          value.containsKey('end')) {
        validated[key] = _validateGesturePosition(
          Map<String, dynamic>.from(value),
        );
      } else if (value is Map &&
          value.containsKey('x') &&
          value.containsKey('y')) {
        validated[key] = _validateSimplePosition(
          Map<String, dynamic>.from(value),
        );
      } else {
        // Keep original if structure is unexpected but valid
        validated[key] = value;
      }
    }

    // Ensure all required positions exist
    for (final defaultEntry in defaultGesturePositions.entries) {
      if (!validated.containsKey(defaultEntry.key)) {
        validated[defaultEntry.key] = defaultEntry.value;
      }
    }

    return validated;
  }

  Map<String, int> _validateAndFixDurations(Map<String, dynamic> durations) {
    final validated = <String, int>{};

    final defaultDurations = {
      'defaultWaitTime': defaultWaitTime,
      'videoLoadTime': videoLoadTime,
      'videoWatchTime': videoWatchTime,
      'switchAccountTime': switchAccountTime,
      'swapDuration': swapTime,
      'maxTaskDuration': maxTaskDuration,
    };

    for (final entry in defaultDurations.entries) {
      final key = entry.key;
      final defaultValue = entry.value;

      if (durations.containsKey(key)) {
        final value = durations[key];
        if (value is int && isValidDuration(value)) {
          validated[key] = value;
        } else if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null && isValidDuration(parsed)) {
            validated[key] = parsed;
          } else {
            validated[key] = defaultValue;
          }
        } else {
          validated[key] = defaultValue;
        }
      } else {
        validated[key] = defaultValue;
      }
    }

    return validated;
  }

  Map<String, dynamic> _validateAccountPositions(
    Map<String, dynamic> accounts,
  ) {
    final validated = <String, dynamic>{};

    for (final entry in accounts.entries) {
      final accountKey = entry.key;
      final position = entry.value;

      if (position is Map &&
          position.containsKey('x') &&
          position.containsKey('y')) {
        validated[accountKey] = _validateSimplePosition(
          Map<String, dynamic>.from(position),
        );
      }
    }

    return validated;
  }

  Map<String, dynamic> _validateGesturePosition(Map<String, dynamic> gesture) {
    final start = gesture['start'];
    final end = gesture['end'];

    return {
      'start': start is Map
          ? _validateSimplePosition(Map<String, dynamic>.from(start))
          : {'x': 360.0, 'y': 1232.0},
      'end': end is Map
          ? _validateSimplePosition(Map<String, dynamic>.from(end))
          : {'x': 360.0, 'y': 616.0},
    };
  }

  Map<String, dynamic> _validateSimplePosition(Map<String, dynamic> position) {
    final x = _validateCoordinateValue(position['x']);
    final y = _validateCoordinateValue(position['y']);

    return {'x': x, 'y': y};
  }

  double _validateCoordinateValue(dynamic value) {
    if (value is double && isValidCoordinate(value)) {
      return value;
    } else if (value is int) {
      final doubleValue = value.toDouble();
      if (isValidCoordinate(doubleValue)) {
        return doubleValue;
      }
    } else if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && isValidCoordinate(parsed)) {
        return parsed;
      }
    }

    return 360.0; // Default fallback
  }

  bool _isValidConfigStructure(Map<String, dynamic> config) {
    return config.containsKey('positions') &&
        config.containsKey('durations') &&
        config['positions'] is Map &&
        config['durations'] is Map;
  }
}
