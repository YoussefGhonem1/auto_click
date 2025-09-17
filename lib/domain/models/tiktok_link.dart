class TikTokLink {
  final String id;
  final String url;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final bool isActive;

  const TikTokLink({
    required this.id,
    required this.url,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.isActive = true,
  });

  factory TikTokLink.fromMap(Map<String, dynamic> map) {
    return TikTokLink(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      title: map['title'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      userId: map['userId'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      // 'userId': userId,
      'isActive': isActive,
    };
  }

  TikTokLink copyWith({
    String? id,
    String? url,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool? isActive,
  }) {
    return TikTokLink(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
    );
  }

  bool isValidTikTokUrl() {
    return url.contains('tiktok.com') || url.contains('vm.tiktok.com');
  }

  @override
  String toString() {
    return 'TikTokLink(id: $id, url: $url, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, userId: $userId, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TikTokLink &&
        other.id == id &&
        other.url == url &&
        other.title == title &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.userId == userId &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        url.hashCode ^
        title.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        userId.hashCode ^
        isActive.hashCode;
  }
}
