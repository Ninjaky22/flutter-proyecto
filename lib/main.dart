import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KioglossApp());
}

class KioglossApp extends StatelessWidget {
  const KioglossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiogloss - Panel de Administración',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const LoginPage(),
    );
  }
}
