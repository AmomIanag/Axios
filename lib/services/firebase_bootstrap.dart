import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({required this.available, this.message});

  final bool available;
  final String? message;
}

abstract final class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        return const FirebaseBootstrapResult(available: true);
      }

      const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
      const appId = String.fromEnvironment('FIREBASE_APP_ID');
      const messagingSenderId = String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      );
      const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
      const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
      const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

      final hasDartDefines =
          apiKey.isNotEmpty &&
          appId.isNotEmpty &&
          messagingSenderId.isNotEmpty &&
          projectId.isNotEmpty;

      if (kIsWeb && !hasDartDefines) {
        return const FirebaseBootstrapResult(
          available: false,
          message: 'Firebase Web ainda não foi configurado.',
        );
      }

      if (hasDartDefines) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: messagingSenderId,
            projectId: projectId,
            authDomain: authDomain.isEmpty ? null : authDomain,
            storageBucket: storageBucket.isEmpty ? null : storageBucket,
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      return const FirebaseBootstrapResult(available: true);
    } catch (error) {
      return FirebaseBootstrapResult(
        available: false,
        message: 'Firebase indisponível: $error',
      );
    }
  }
}
