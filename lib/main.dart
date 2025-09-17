import 'package:auto_click/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Core Imports
import 'core/theme/app_theme.dart';

// Presentation Imports
import 'presentation/widgets/auth_wrapper.dart';

// Domain Imports
import 'domain/services/connection_monitoring_service.dart';
import 'domain/services/tiktok_links_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ConnectionMonitoringService _connectionService =
      ConnectionMonitoringService();
  final TikTokLinksService _tikTokLinksService = TikTokLinksService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectionService.initialize();
    _initializeTikTokLinks();
  }

  /// Initialize TikTok links service when user is authenticated
  void _initializeTikTokLinks() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _tikTokLinksService.initialize();
      } else {
        _tikTokLinksService.clearCache();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: MaterialApp(
        title: 'TikTok Automation Tools',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const AuthWrapper(),
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
