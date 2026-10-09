import 'package:flutter/material.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'core/theme/app_theme.dart';
import 'screens/firebase_initialization_error_screen.dart';

typedef DependenciesBootstrap = Future<AppDependencies> Function();

class AxiosBootstrapApp extends StatefulWidget {
  const AxiosBootstrapApp({super.key, this.bootstrap});

  final DependenciesBootstrap? bootstrap;

  @override
  State<AxiosBootstrapApp> createState() => _AxiosBootstrapAppState();
}

class _AxiosBootstrapAppState extends State<AxiosBootstrapApp> {
  late Future<AppDependencies> _dependencies;
  AppDependencies? _activeDependencies;

  @override
  void initState() {
    super.initState();
    _startBootstrap();
  }

  void _startBootstrap() {
    _dependencies = (widget.bootstrap ?? AppDependencies.bootstrap)().then((
      dependencies,
    ) {
      if (mounted) {
        _activeDependencies = dependencies;
      } else {
        dependencies.controller.dispose();
      }
      return dependencies;
    });
  }

  void _retry() {
    setState(_startBootstrap);
  }

  @override
  void dispose() {
    _activeDependencies?.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      future: _dependencies,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return AxiosApp(controller: snapshot.requireData.controller);
        }

        final error = snapshot.error;
        if (error != null) {
          final message = error is FirebaseInitializationException
              ? error.message
              : 'Não foi possível iniciar o Axios. Tente novamente.';
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Axios',
            theme: AppTheme.light,
            home: FirebaseInitializationErrorScreen(
              message: message,
              onRetry: _retry,
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Axios',
          theme: AppTheme.light,
          home: const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          ),
        );
      },
    );
  }
}
