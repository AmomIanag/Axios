import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../widgets/axios_logo.dart';

class FirebaseInitializationErrorScreen extends StatelessWidget {
  const FirebaseInitializationErrorScreen({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AxiosLogo(size: 72),
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: AppColors.graphite,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Não foi possível iniciar o Axios',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: AppColors.gray),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('firebase-retry-button'),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
