class GesturePosition {
  final String name;
  final int x;
  final int y;
  final bool isActive;

  const GesturePosition({
    required this.name,
    required this.x,
    required this.y,
    required this.isActive,
  });

  GesturePosition copyWith({String? name, int? x, int? y, bool? isActive}) {
    return GesturePosition(
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GesturePosition &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          x == other.x &&
          y == other.y &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      name.hashCode ^ x.hashCode ^ y.hashCode ^ isActive.hashCode;

  @override
  String toString() {
    return 'GesturePosition{name: $name, x: $x, y: $y, isActive: $isActive}';
  }
}
