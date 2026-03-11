import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:daef/config/constants.dart';
import 'package:daef/config/router.dart';
import 'package:daef/config/theme.dart';
import 'package:daef/providers/auth_provider.dart';
import 'package:daef/providers/evaluation_provider.dart';
import 'package:daef/providers/notification_provider.dart';
import 'package:daef/providers/social_provider.dart';
import 'package:daef/providers/theme_provider.dart';
import 'package:daef/services/api_client.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  ApiClient.instance.init();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  runApp(const DaefApp());
}

class DaefApp extends StatefulWidget {
  const DaefApp({super.key});

  @override
  State<DaefApp> createState() => _DaefAppState();
}

class _DaefAppState extends State<DaefApp> {
  final _themeProvider = ThemeProvider();
  final _authProvider = AuthProvider();
  late final _router = createRouter(_authProvider);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _themeProvider.load(),
      _authProvider.tryRestoreSession(),
    ]);
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => EvaluationProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, child) => MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
