import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'data/mock_financial_data.dart';
import 'models/app_user.dart';
import 'repositories/auth_repository.dart';
import 'repositories/demo_auth_repository.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/firestore_goal_repository.dart';
import 'repositories/goal_repository.dart';
import 'repositories/in_memory_goal_repository.dart';
import 'services/firebase_bootstrap.dart';
import 'state/app_controller.dart';

enum AppMode { firebase, demo }

class FirebaseInitializationException implements Exception {
  const FirebaseInitializationException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef FirebaseInitializer = Future<FirebaseBootstrapResult> Function();
typedef AuthRepositoryFactory = AuthRepository Function();
typedef GoalRepositoryFactory = GoalRepository Function();

class AppDependencies {
  AppDependencies._(this.controller, this.mode);

  final AppController controller;
  final AppMode mode;

  static Future<AppDependencies> bootstrap({
    FirebaseInitializer? initializeFirebase,
    AuthRepositoryFactory? createAuthRepository,
    GoalRepositoryFactory? createGoalRepository,
  }) async {
    final firebase =
        await (initializeFirebase ?? FirebaseBootstrap.initialize)();
    if (!firebase.available) {
      throw FirebaseInitializationException(
        firebase.message ?? 'Não foi possível inicializar o Firebase.',
      );
    }

    final controller = AppController(
      (createAuthRepository ??
          () => FirebaseAuthRepository(FirebaseAuth.instance))(),
      (createGoalRepository ??
          () => FirestoreGoalRepository(FirebaseFirestore.instance))(),
      firebaseAvailable: true,
    );
    controller.initialize();
    return AppDependencies._(controller, AppMode.firebase);
  }

  static AppDependencies demo({bool authenticated = false}) {
    final controller = AppController(
      DemoAuthRepository(
        initialUser: authenticated
            ? const AppUser(
                id: 'demo-user',
                email: 'amom@axios.app',
                displayName: 'Amom',
              )
            : null,
      ),
      InMemoryGoalRepository(initialGoals: MockFinancialData.goals),
      firebaseAvailable: false,
      firebaseMessage: 'Ambiente de teste',
    );
    controller.initialize();
    return AppDependencies._(controller, AppMode.demo);
  }
}
