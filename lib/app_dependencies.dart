import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'data/mock_financial_data.dart';
import 'models/app_user.dart';
import 'repositories/demo_auth_repository.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/firestore_goal_repository.dart';
import 'repositories/in_memory_goal_repository.dart';
import 'services/firebase_bootstrap.dart';
import 'state/app_controller.dart';

class AppDependencies {
  AppDependencies._(this.controller);

  final AppController controller;

  static Future<AppDependencies> bootstrap() async {
    final firebase = await FirebaseBootstrap.initialize();
    final controller = firebase.available
        ? AppController(
            FirebaseAuthRepository(FirebaseAuth.instance),
            FirestoreGoalRepository(FirebaseFirestore.instance),
            firebaseAvailable: true,
          )
        : AppController(
            DemoAuthRepository(),
            InMemoryGoalRepository(initialGoals: MockFinancialData.goals),
            firebaseAvailable: false,
            firebaseMessage: firebase.message,
          );
    controller.initialize();
    return AppDependencies._(controller);
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
    return AppDependencies._(controller);
  }
}
