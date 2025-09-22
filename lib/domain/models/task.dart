import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String status;
  final String? assignedTo;
  final double progress;
  final bool inProgress;

  const Task({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.status = 'pending',
    this.assignedTo,
    this.progress = 0,
    this.inProgress = false,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'assignedTo': assignedTo,
      'progress': progress,
      'inProgress': inProgress,
    };
  }


factory Task.fromMap(Map<String, dynamic> map, String documentId) {
  // This is a robust helper function to safely parse timestamps.
  DateTime _parseTimestamp(dynamic value) {
    if (value == null) {
      return DateTime.now(); // Fallback if createdAt is missing.
    }
    if (value is Timestamp) {
      // Handles new data stored correctly as a Timestamp.
      return value.toDate();
    } else if (value is String) {
      // Handles old data stored as a String.
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string: $value. Error: $e');
        return DateTime.now(); // Fallback if parsing fails.
      }
    }
    // Fallback for any other unexpected type.
    return DateTime.now();
  }

  return Task(
    id: documentId,
    type: map['type'] as String? ?? '',
    data: Map<String, dynamic>.from(map['data'] ?? {}),
    createdAt: _parseTimestamp(map['createdAt']), // Use the robust helper
    status: map['status'] as String? ?? 'pending',
    assignedTo: map['assignedTo'] as String?,
    progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    inProgress: map['inProgress'] as bool? ?? false,
  );
}
  Task copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    String? status,
    String? assignedTo,
    double? progress,
    bool? inProgress,
  }) {
    return Task(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      progress: progress ?? this.progress,
      inProgress: inProgress ?? this.inProgress,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          createdAt == other.createdAt &&
          status == other.status &&
          assignedTo == other.assignedTo &&
          progress == other.progress &&
          inProgress == other.inProgress;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      createdAt.hashCode ^
      status.hashCode ^
      assignedTo.hashCode ^
      progress.hashCode ^
      inProgress.hashCode;

  @override
  String toString() {
    return 'Task{id: $id, type: $type, createdAt: $createdAt, status: $status, assignedTo: $assignedTo, progress: $progress, inProgress: $inProgress}';
  }
}
