import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/data_sources/local_datasource/gesture_positions.dart';

class GlobalGestureConfigService {
  static const String _globalConfigCollection = 'global_gesture_config';
  static const String _globalConfigDocId = 'default_config';
  static const String _currentVersion = '1.0.0';

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern for service
  static final GlobalGestureConfigService _instance =
      GlobalGestureConfigService._internal();
  factory GlobalGestureConfigService() => _instance;
  GlobalGestureConfigService._internal();

  // Cache for loaded data
  Map<String, dynamic>? _cachedGlobalPositions;
  Map<String, int>? _cachedGlobalDurations;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Check if cache is valid
  bool get _isCacheValid =>
      _lastCacheUpdate != null &&
      DateTime.now().difference(_lastCacheUpdate!) < _cacheValidityDuration;
/// Load global gesture positions from Firestore
  Future<Map<String, dynamic>> loadGlobalGesturePositions() async {
    // Return cached data if valid
    // if (_isCacheValid && _cachedGlobalPositions != null) {
    //   return Map<String, dynamic>.from(_cachedGlobalPositions!);
    // }

    try {
      final doc = await _firestore
          .collection(_globalConfigCollection)
          .doc(_globalConfigDocId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final positions = data['positions'] as Map<String, dynamic>?;

        if (positions != null) {
          _cachedGlobalPositions = _validateAndFixPositions(positions);
          _lastCacheUpdate = DateTime.now();
          return Map<String, dynamic>.from(_cachedGlobalPositions!);
        }
      }

      // If no global config exists, return defaults
      _cachedGlobalPositions = Map<String, dynamic>.from(
        defaultGesturePositions,
      );
      _lastCacheUpdate = DateTime.now();
      return Map<String, dynamic>.from(_cachedGlobalPositions!);
    } catch (e) {
      // Fallback to defaults if loading fails
      _cachedGlobalPositions = Map<String, dynamic>.from(
        defaultGesturePositions,
      );
      _lastCacheUpdate = DateTime.now();
      return Map<String, dynamic>.from(_cachedGlobalPositions!);
    }
  }

  /// Load global durations from Firestore
  Future<Map<String, int>> loadGlobalDurations() async {
    // Return cached data if valid
    if (_isCacheValid && _cachedGlobalDurations != null) {
      return Map<String, int>.from(_cachedGlobalDurations!);
    }

    try {
      final doc = await _firestore
          .collection(_globalConfigCollection)
          .doc(_globalConfigDocId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final durations = data['durations'] as Map<String, dynamic>?;

        if (durations != null) {
          _cachedGlobalDurations = _validateAndFixDurations(durations);
          _lastCacheUpdate = DateTime.now();
          print(
            'Loaded global durations from Firestore: $_cachedGlobalDurations',
          );
          return Map<String, int>.from(_cachedGlobalDurations!);
        }
      }

      // If no global config exists, return defaults
      _cachedGlobalDurations = {
        'defaultWaitTime': defaultWaitTime,
        'videoLoadTime': videoLoadTime,
        'videoWatchTime': videoWatchTime,
        'switchAccountTime': switchAccountTime,
        'swapDuration': swapTime,
      };
      _lastCacheUpdate = DateTime.now();
      return Map<String, int>.from(_cachedGlobalDurations!);
    } catch (e) {
      // Fallback to defaults if loading fails
      _cachedGlobalDurations = {
        'defaultWaitTime': defaultWaitTime,
        'videoLoadTime': videoLoadTime,
        'videoWatchTime': videoWatchTime,
        'switchAccountTime': switchAccountTime,
        'swapDuration': swapTime,
      };
      _lastCacheUpdate = DateTime.now();
      return Map<String, int>.from(_cachedGlobalDurations!);
    }
  }

  /// Save global gesture positions to Firestore (Admin only)
  Future<bool> saveGlobalGesturePositions(
    Map<String, dynamic> positions,
  ) async {
    try {
      final validatedPositions = _validateAndFixPositions(positions);

      await _firestore
          .collection(_globalConfigCollection)
          .doc(_globalConfigDocId)
          .set({
            'positions': validatedPositions,
            'lastUpdated': FieldValue.serverTimestamp(),
            'version': _currentVersion,
          }, SetOptions(merge: true));

      // Update cache
      _cachedGlobalPositions = validatedPositions;
      _lastCacheUpdate = DateTime.now();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save global durations to Firestore (Admin only)
  Future<bool> saveGlobalDurations(Map<String, int> durations) async {
    try {
      final validatedDurations = _validateAndFixDurations(durations);

      // Debug: Print the durations being saved
      print('Saving global durations: $validatedDurations');

      await _firestore
          .collection(_globalConfigCollection)
          .doc(_globalConfigDocId)
          .set({
            'durations': validatedDurations,
            'lastUpdated': FieldValue.serverTimestamp(),
            'version': _currentVersion,
          }, SetOptions(merge: true));

      // Update cache
      _cachedGlobalDurations = validatedDurations;
      _lastCacheUpdate = DateTime.now();

      return true;
    } catch (e) {
      print('Error saving global durations: $e');
      return false;
    }
  }

  /// Reset global configuration to defaults (Admin only)
  Future<bool> resetGlobalToDefaults() async {
    try {
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

      await _firestore
          .collection(_globalConfigCollection)
          .doc(_globalConfigDocId)
          .set({
            'positions': defaultPositions,
            'durations': defaultDurs,
            'lastUpdated': FieldValue.serverTimestamp(),
            'version': _currentVersion,
          });

      // Clear cache to force reload
      _cachedGlobalPositions = null;
      _cachedGlobalDurations = null;
      _lastCacheUpdate = null;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear cache and force reload from Firestore
  void clearCache() {
    _cachedGlobalPositions = null;
    _cachedGlobalDurations = null;
    _lastCacheUpdate = null;
  }

  /// Get global configuration version
  Future<String> getGlobalConfigVersion() async {
    try {
      final doc = await _firestore
          .collection(_globalConfigCollection)
          .doc(_globalConfigDocId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return data['version'] as String? ?? _currentVersion;
      }

      return _currentVersion;
    } catch (e) {
      return _currentVersion;
    }
  }

  /// Check if global configuration exists
  Future<bool> hasGlobalConfiguration() async {
    try {
      final doc = await _firestore
          .collection(_globalConfigCollection)
          .doc(_globalConfigDocId)
          .get();

      return doc.exists && doc.data() != null;
    } catch (e) {
      return false;
    }
  }

  /// Get last update timestamp
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final doc = await _firestore
          .collection(_globalConfigCollection)
          .doc(_globalConfigDocId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final timestamp = data['lastUpdated'] as Timestamp?;
        return timestamp?.toDate();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Listen to global configuration changes
  Stream<Map<String, dynamic>> listenToGlobalConfigChanges() {
    return _firestore
        .collection(_globalConfigCollection)
        .doc(_globalConfigDocId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;

            // Update cache when data changes
            if (data['positions'] != null) {
              _cachedGlobalPositions = _validateAndFixPositions(
                data['positions'] as Map<String, dynamic>,
              );
            }

            if (data['durations'] != null) {
              _cachedGlobalDurations = _validateAndFixDurations(
                data['durations'] as Map<String, dynamic>,
              );
            }

            _lastCacheUpdate = DateTime.now();

            return data;
          }

          return <String, dynamic>{};
        });
  }

  /// Export global configuration as JSON string
  Future<String> exportGlobalConfiguration() async {
    try {
      final positions = await loadGlobalGesturePositions();
      final durations = await loadGlobalDurations();

      final config = {
        'positions': positions,
        'durations': durations,
        'version': _currentVersion,
        'exportDate': DateTime.now().toIso8601String(),
        'appName': 'Auto Click TikTok - Global Config',
        'configType': 'global',
      };

      return jsonEncode(config);
    } catch (e) {
      throw Exception('Failed to export global configuration: $e');
    }
  }

  /// Import global configuration from JSON string (Admin only)
  Future<bool> importGlobalConfiguration(String jsonString) async {
    try {
      final config = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate the configuration structure
      if (!_isValidConfigStructure(config)) {
        throw Exception('Invalid file format');
      }

      final positions = config['positions'] as Map<String, dynamic>;
      final durations = Map<String, int>.from(config['durations']);

      // Save the imported data
      final positionsSaved = await saveGlobalGesturePositions(positions);
      final durationsSaved = await saveGlobalDurations(durations);

      if (positionsSaved && durationsSaved) {
        // Clear cache to force reload
        clearCache();
        return true;
      }

      return false;
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
        if (value is int && _isValidDuration(value)) {
          validated[key] = value;
        } else if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null && _isValidDuration(parsed)) {
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
    if (value is double && _isValidCoordinate(value)) {
      return value;
    } else if (value is int) {
      final doubleValue = value.toDouble();
      if (_isValidCoordinate(doubleValue)) {
        return doubleValue;
      }
    } else if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && _isValidCoordinate(parsed)) {
        return parsed;
      }
    }

    return 360.0; // Default fallback
  }

  bool _isValidCoordinate(double value) {
    return value >= 0.0 && !value.isNaN && value.isFinite;
  }

  bool _isValidDuration(int value) {
    return value > 0 &&
        value <= 600000; // Max 10 minutes (allows maxTaskDuration of 5 minutes)
  }

  bool _isValidConfigStructure(Map<String, dynamic> config) {
    return config.containsKey('positions') &&
        config.containsKey('durations') &&
        config['positions'] is Map &&
        config['durations'] is Map;
  }
}
