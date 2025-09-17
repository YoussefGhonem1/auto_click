import 'package:flutter/material.dart';
import '../../domain/models/device_status.dart';
import '../../domain/services/automation_service.dart';
import '../../core/theme/app_theme.dart';
import 'section_card.dart';

class DevicesSection extends StatelessWidget {
  final DeviceStatus deviceStatus;
  final AutomationService automationService;
  final VoidCallback onRefresh;

  const DevicesSection({
    super.key,
    required this.deviceStatus,
    required this.automationService,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Connected Devices',
      icon: Icons.devices,
      iconColor: AppColors.getDeviceColor(context),
      subtitle:
          '${deviceStatus.connectedDevicesCount} device${deviceStatus.connectedDevicesCount != 1 ? 's' : ''} connected',
      trailing: IconButton(
        onPressed: onRefresh,
        icon: Icon(
          Icons.refresh,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      children: [],
    );
  }
}
