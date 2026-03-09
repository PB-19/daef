import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:daef/config/constants.dart';
import 'package:daef/config/theme.dart';
import 'package:daef/screens/home/home_screen.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  runApp(const DaefApp());
}

class DaefApp extends StatefulWidget {
  const DaefApp({super.key});

  @override
  State<DaefApp> createState() => _DaefAppState();
}

class _DaefAppState extends State<DaefApp> {
  @override
  void initState() {
    super.initState();
    // Remove splash once the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
