import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FetApp());
}

class FetApp extends StatelessWidget {
  const FetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FET - Consola de Administración',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF06B6D4),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const LoginPage(),
    );
  }
}
