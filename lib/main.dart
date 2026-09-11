import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const AxiosApp());
}

class AxiosApp extends StatelessWidget {
  const AxiosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Axios',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF8F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE6B800),
          primary: const Color(0xFFE6B800),
          onPrimary: const Color(0xFF1F2937),
          surface: const Color(0xFFFAF8F2),
          onSurface: const Color(0xFF1F2937),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
