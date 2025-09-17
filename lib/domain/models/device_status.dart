class DeviceStatus {
  final bool isTikTokInstalled;
  final bool isAccessibilityEnabled;
  final int connectedDevicesCount;

  const DeviceStatus({
    required this.isTikTokInstalled,
    required this.isAccessibilityEnabled,
    required this.connectedDevicesCount,
  });

  bool get isSystemReady => isTikTokInstalled && isAccessibilityEnabled;

  DeviceStatus copyWith({
    bool? isTikTokInstalled,
    bool? isAccessibilityEnabled,
    int? connectedDevicesCount,
  }) {
    return DeviceStatus(
      isTikTokInstalled: isTikTokInstalled ?? this.isTikTokInstalled,
      isAccessibilityEnabled:
          isAccessibilityEnabled ?? this.isAccessibilityEnabled,
      connectedDevicesCount:
          connectedDevicesCount ?? this.connectedDevicesCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceStatus &&
          runtimeType == other.runtimeType &&
          isTikTokInstalled == other.isTikTokInstalled &&
          isAccessibilityEnabled == other.isAccessibilityEnabled &&
          connectedDevicesCount == other.connectedDevicesCount;

  @override
  int get hashCode =>
      isTikTokInstalled.hashCode ^
      isAccessibilityEnabled.hashCode ^
      connectedDevicesCount.hashCode;

  @override
  String toString() {
    return 'DeviceStatus{isTikTokInstalled: $isTikTokInstalled, isAccessibilityEnabled: $isAccessibilityEnabled, connectedDevicesCount: $connectedDevicesCount}';
  }
}
