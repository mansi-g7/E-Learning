import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/app_settings_controller.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettingsController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Learning',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B53D6)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F6FB),
          surfaceTintColor: Colors.transparent,
          foregroundColor: Color(0xFF162033),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1524),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B53D6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1524),
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF182033),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      themeMode: settings.themeMode,
      locale: settings.locale,
      home: const AppBootstrap(),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}
