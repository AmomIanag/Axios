import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'app_check_bootstrap.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.available,
    this.message,
    this.appCheckActive = false,
  });

  final bool available;
  final String? message;
  final bool appCheckActive;
}

abstract final class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final appCheck = await AppCheckBootstrap.initialize();
      return FirebaseBootstrapResult(
        available: true,
        message: appCheck.message,
        appCheckActive: appCheck.active,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Falha ao inicializar o Firebase: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      return FirebaseBootstrapResult(
        available: false,
        message: error is UnsupportedError
            ? 'O Firebase não está configurado para esta plataforma.'
            : 'Não foi possível conectar ao Firebase. Verifique sua conexão '
                  'e tente novamente.',
      );
    }
  }
}
