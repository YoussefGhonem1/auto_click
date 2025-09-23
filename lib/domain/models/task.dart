import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { high, normal }

class Task {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String status;
  final String? assignedTo;
  final double progress;
  // final bool inProgress; // تم حذف هذا الحقل
  final TaskPriority priority;

  const Task({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.status = 'pending',
    this.assignedTo,
    this.progress = 0,
    // this.inProgress = false, // تم الحذف
    this.priority = TaskPriority.high,
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
      // 'inProgress': inProgress, // تم الحذف
      'priority': priority.name,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime _parseTimestamp(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing date string: $value. Error: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Task(
      id: documentId,
      type: map['type'] as String? ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      createdAt: _parseTimestamp(map['createdAt']),
      status: map['status'] as String? ?? 'pending',
      assignedTo: map['assignedTo'] as String?,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      // inProgress: map['inProgress'] as bool? ?? false, // تم الحذف
      priority: _parsePriority(map['priority']),
    );
  }

  static TaskPriority _parsePriority(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'normal':
          return TaskPriority.normal;
        case 'high':
        default:
          return TaskPriority.high;
      }
    }
    return TaskPriority.high;
  }

  Task copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    String? status,
    String? assignedTo,
    double? progress,
    // bool? inProgress, // تم الحذف
    TaskPriority? priority,
  }) {
    return Task(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      progress: progress ?? this.progress,
      // inProgress: inProgress ?? this.inProgress, // تم الحذف
      priority: priority ?? this.priority,
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
          progress == other.progress;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      createdAt.hashCode ^
      status.hashCode ^
      assignedTo.hashCode ^
      progress.hashCode ^
      priority.hashCode;

  @override
  String toString() {
    return 'Task{id: $id, type: $type, createdAt: $createdAt, status: $status, assignedTo: $assignedTo, progress: $progress, priority: $priority}';
  }
}