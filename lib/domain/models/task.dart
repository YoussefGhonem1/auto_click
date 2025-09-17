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

  // Create from Firestore document
  factory Task.fromMap(Map<String, dynamic> map, String documentId) {
    return Task(
      id: documentId,
      type: map['type'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'pending',
      assignedTo: map['assignedTo'],
      progress: map['progress'] ?? 0,
      inProgress: map['inProgress'] ?? false,
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
