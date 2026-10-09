import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'state/app_controller.dart';

class AxiosApp extends StatelessWidget {
  const AxiosApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Axios',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.user == null) {
            return LoginScreen(controller: controller);
          }
          return MainShell(controller: controller);
        },
      ),
    );
  }
}
