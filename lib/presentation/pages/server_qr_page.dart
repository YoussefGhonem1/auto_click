import 'package:flutter/material.dart';
import '../../domain/services/qr_code_service.dart';
import '../../domain/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class ServerQRPage extends StatefulWidget {
  const ServerQRPage({super.key});

  @override
  State<ServerQRPage> createState() => _ServerQRPageState();
}

class _ServerQRPageState extends State<ServerQRPage> {
  final AuthService _authService = AuthService();
  String? _serverId;

  @override
  void initState() {
    super.initState();
    _loadServerId();
  }

  Future<void> _loadServerId() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      setState(() {
        _serverId = currentUser.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server QR Code'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: _serverId == null
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Server Info Card
                  Card(
                    color: colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.dns,
                            size: 48,
                            color: AppColors.getDeviceColor(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Server ID',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _serverId!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code Card
                  Card(
                    color: colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Registration QR Code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Scan this code from the management device to add this server to admin management',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          QRCodeService.generateServerRegistrationQRCode(
                            _serverId!,
                            size: 250,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Instructions Card
                  Card(
                    color: colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usage Instructions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionItem(
                            '1',
                            'Open the management app on the admin device',
                          ),
                          _buildInstructionItem(
                            '2',
                            'Go to the server management page',
                          ),
                          _buildInstructionItem(
                            '3',
                            'Tap the QR code scan button',
                          ),
                          _buildInstructionItem(
                            '4',
                            'Scan this code from the server screen',
                          ),
                          _buildInstructionItem(
                            '5',
                            'The server will be added automatically to admin management',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.getInfoColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
