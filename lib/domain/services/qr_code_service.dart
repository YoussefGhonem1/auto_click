import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeService {
  /// Generate QR code data for server ID (admin side - for server connection)
  static String generateServerQRData(String serverId) {
    final data = {
      'type': 'server_connection',
      'serverId': serverId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(data);
  }

  /// Generate QR code data for server ID (server side - for admin to add server)
  static String generateServerRegistrationQRData(String serverId) {
    final data = {
      'type': 'server_registration',
      'serverId': serverId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(data);
  }

  /// Generate QR code widget for server ID (admin side)
  static Widget generateServerQRCode(String serverId, {double size = 200}) {
    final qrData = generateServerQRData(serverId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
          const SizedBox(height: 16),
          Text(
            'Server ID: $serverId',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan this code from the server device',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Generate QR code widget for server registration (server side)
  static Widget generateServerRegistrationQRCode(
    String serverId, {
    double size = 200,
  }) {
    final qrData = generateServerRegistrationQRData(serverId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
          const SizedBox(height: 16),
          Text(
            'Server ID: $serverId',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan this code from the management device',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Parse QR code data
  static Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;

      // Validate the QR data structure
      if ((data['type'] == 'server_connection' ||
              data['type'] == 'server_registration') &&
          data['serverId'] != null) {
        return data;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extract server ID from QR data
  static String? extractServerId(String qrData) {
    final data = parseQRData(qrData);
    return data?['serverId'] as String?;
  }

  /// Get QR type from data
  static String? getQRType(String qrData) {
    final data = parseQRData(qrData);
    return data?['type'] as String?;
  }

  /// Validate QR code data for server connection (admin -> server)
  static bool isValidServerQRData(String qrData) {
    final data = parseQRData(qrData);
    if (data == null) return false;

    // QR codes never expire - only validate structure
    return data['type'] == 'server_connection' && data['serverId'] != null;
  }

  /// Validate QR code data for server registration (server -> admin)
  static bool isValidServerRegistrationQRData(String qrData) {
    final data = parseQRData(qrData);
    if (data == null) return false;

    // QR codes never expire - only validate structure
    return data['type'] == 'server_registration' && data['serverId'] != null;
  }
}
