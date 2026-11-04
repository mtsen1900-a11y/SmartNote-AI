import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

import 'core/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'ui_refinement/guest/guest_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.initSession();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      defaultDevice: Devices.android.samsungGalaxyS20,
      isToolbarVisible: true,
      builder: (context) => SmartNoteApp(authService: authService),
    ),
  );
}

class SmartNoteApp extends StatefulWidget {
  final AuthService authService;

  const SmartNoteApp({super.key, required this.authService});

  @override
  State<SmartNoteApp> createState() => _SmartNoteAppState();
}

class _SmartNoteAppState extends State<SmartNoteApp> {
  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onAuthChanged);
    GuestSession().addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthChanged);
    GuestSession().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isAuthorized = widget.authService.isAuthenticated || GuestSession().isGuestMode;
    return MaterialApp(
      title: 'SmartNoteAI - Nền tảng Tri thức Thông minh',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: isAuthorized
          ? HomeScreen(authService: widget.authService)
          : AuthScreen(
              authService: widget.authService,
              onAuthenticated: () => setState(() {}),
            ),
    );
  }
}
