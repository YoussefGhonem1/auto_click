import 'dart:convert';
import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'auth_service.dart';
import 'user_service.dart';
import 'server_management_service.dart';
import 'qr_code_service.dart';
import '../models/user_role.dart';

class QRScannerService {
  /// Scan QR code and connect to server (for server users)
  static Future<String?> scanServerQRCode(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => const QRScannerDialog(),
    );
  }

  /// Scan QR code and add server to admin management (for admin users)
  static Future<String?> scanServerRegistrationQRCode(
    BuildContext context,
  ) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => const ServerRegistrationQRScannerDialog(),
    );
  }

  /// Validate and connect to server using QR data (for server users)
  static Future<bool> connectToServer(String qrData) async {
    try {
      // Parse QR data
      final data = QRCodeService.parseQRData(qrData);
      if (data == null) {
        throw Exception('Invalid QR data');
      }

      // Validate QR data
      if (!QRCodeService.isValidServerQRData(qrData)) {
        throw Exception('QR code expired or invalid');
      }

      final serverId = data['serverId'] as String?;
      if (serverId == null) {
        throw Exception('Server ID not found');
      }

      // Connect to the server
      return await _connectToServerById(serverId);
    } catch (e) {
      throw Exception('Failed to connect to server: ${e.toString()}');
    }
  }

  /// Validate and add server to admin management using QR data (for admin users)
  static Future<bool> addServerToAdmin(String qrData) async {
    try {
      // Parse QR data
      final data = QRCodeService.parseQRData(qrData);
      if (data == null) {
        throw Exception('Invalid QR data');
      }

      // Validate QR data
      if (!QRCodeService.isValidServerRegistrationQRData(qrData)) {
        throw Exception('QR code expired or invalid');
      }

      final serverId = data['serverId'] as String?;
      if (serverId == null) {
        throw Exception('Server ID not found');
      }

      // Add server to admin management
      return await _addServerToAdminById(serverId);
    } catch (e) {
      throw Exception('Failed to add server: ${e.toString()}');
    }
  }

  /// Validate and add server to admin management using QR data with custom name (for admin users)
  static Future<bool> addServerToAdminWithName(
    String qrData,
    String serverName,
  ) async {
    try {
      // Parse QR data
      final data = QRCodeService.parseQRData(qrData);
      if (data == null) {
        throw Exception('Invalid QR data');
      }

      // Validate QR data
      if (!QRCodeService.isValidServerRegistrationQRData(qrData)) {
        throw Exception('QR code expired or invalid');
      }

      final serverId = data['serverId'] as String?;
      if (serverId == null) {
        throw Exception('Server ID not found');
      }

      // Add server to admin management with custom name
      return await _addServerToAdminByIdWithName(serverId, serverName);
    } catch (e) {
      throw Exception('Failed to add server: ${e.toString()}');
    }
  }

  /// Connect to server by ID
  static Future<bool> _connectToServerById(String serverId) async {
    try {
      final authService = AuthService();
      final userService = UserService();

      // Check if server exists and is active
      final server = await userService.getUserByUid(serverId);
      if (server == null) {
        throw Exception('Server not found');
      }

      if (server.role != UserRole.server) {
        throw Exception('ID does not belong to a server');
      }

      if (!server.isActive) {
        throw Exception('Server is not active');
      }

      // Update current user to connect to this server
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('You must log in first');
      }

      // Update the server's connection status
      await userService.updateServerConnectionStatus(serverId, true);

      return true;
    } catch (e) {
      throw Exception('Failed to connect: ${e.toString()}');
    }
  }

  /// Add server to admin management by ID
  static Future<bool> _addServerToAdminById(String serverId) async {
    try {
      final serverManagementService = ServerManagementService();

      // Add server to admin's managed servers
      return await serverManagementService.addServerToAdmin(serverId);
    } catch (e) {
      throw Exception('Failed to add server: ${e.toString()}');
    }
  }

  /// Add server to admin management by ID with custom name
  static Future<bool> _addServerToAdminByIdWithName(
    String serverId,
    String serverName,
  ) async {
    try {
      final serverManagementService = ServerManagementService();

      // Add server to admin's managed servers with custom name
      return await serverManagementService.addServerToAdminWithName(
        serverId,
        serverName,
      );
    } catch (e) {
      throw Exception('Failed to add server: ${e.toString()}');
    }
  }
}

// QR Scanner Dialog for server connection (server users)
class QRScannerDialog extends StatefulWidget {
  const QRScannerDialog({super.key});

  @override
  State<QRScannerDialog> createState() => _QRScannerDialogState();
}

class _QRScannerDialogState extends State<QRScannerDialog> {
  MobileScannerController? controller;
  bool _isScanning = true;
  String _lastScannedData = '';

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Scan Server QR Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isScanning ? _buildQRScanner() : _buildScanningResult(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isScanning = true;
                        _lastScannedData = '';
                      });
                    },
                    child: const Text('Retry Scan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _lastScannedData.isNotEmpty
                        ? () => _connectToServer()
                        : null,
                    child: const Text('Connect'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: MobileScanner(
        controller: controller ??= MobileScannerController(),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null &&
                barcode.rawValue != _lastScannedData) {
              setState(() {
                _lastScannedData = barcode.rawValue!;
                _isScanning = false;
              });
              break;
            }
          }
        },
      ),
    );
  }

  Widget _buildScanningResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'QR Code Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Server ID: ${_extractServerId(_lastScannedData) ?? 'Unknown'}',
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  String? _extractServerId(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      return data['serverId'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> _connectToServer() async {
    try {
      final success = await QRScannerService.connectToServer(_lastScannedData);
      if (success && mounted) {
        Navigator.pop(context, _extractServerId(_lastScannedData));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully connected to server'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// QR Scanner Dialog for server registration (admin users)
class ServerRegistrationQRScannerDialog extends StatefulWidget {
  const ServerRegistrationQRScannerDialog({super.key});

  @override
  State<ServerRegistrationQRScannerDialog> createState() =>
      _ServerRegistrationQRScannerDialogState();
}

class _ServerRegistrationQRScannerDialogState
    extends State<ServerRegistrationQRScannerDialog> {
  MobileScannerController? controller;
  bool _isScanning = true;
  String _lastScannedData = '';

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Scan QR Code to Add Server',
                  style: AppTextStyles.heading1.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isScanning ? _buildQRScanner() : _buildScanningResult(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isScanning = true;
                        _lastScannedData = '';
                      });
                    },
                    child: const Text('Retry Scan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _lastScannedData.isNotEmpty
                        ? () => _addServerToAdmin()
                        : null,
                    child: const Text('Add Server'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: MobileScanner(
        controller: controller ??= MobileScannerController(),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null &&
                barcode.rawValue != _lastScannedData) {
              setState(() {
                _lastScannedData = barcode.rawValue!;
                _isScanning = false;
              });
              break;
            }
          }
        },
      ),
    );
  }

  Widget _buildScanningResult() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Server QR Code Found',
            style: AppTextStyles.heading1.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Server ID: ${_extractServerId(_lastScannedData) ?? 'Unknown'}',
            style: AppTextStyles.body1.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String? _extractServerId(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      return data['serverId'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> _addServerToAdmin() async {
    try {
      // Show dialog to enter server name
      final serverName = await _showServerNameDialog();
      if (serverName == null) return; // User cancelled

      final success = await QRScannerService.addServerToAdminWithName(
        _lastScannedData,
        serverName,
      );
      if (success && mounted) {
        Navigator.pop(context, _extractServerId(_lastScannedData));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully added server'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add server: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showServerNameDialog() async {
    final TextEditingController nameController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Enter Server Name',
          style: TextStyle(color: Colors.grey),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            style: TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Server Name',
              hintText: 'Enter server name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter server name';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
