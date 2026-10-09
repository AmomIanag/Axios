import 'package:axios/app_dependencies.dart';
import 'package:axios/models/app_user.dart';
import 'package:axios/models/goal.dart';
import 'package:axios/repositories/auth_repository.dart';
import 'package:axios/repositories/goal_repository.dart';
import 'package:axios/repositories/in_memory_transaction_repository.dart';
import 'package:axios/services/firebase_bootstrap.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('seleção de dependências', () {
    test('falha do Firebase não aciona o modo demonstração', () async {
      var authFactoryCalled = false;
      var goalFactoryCalled = false;

      await expectLater(
        AppDependencies.bootstrap(
          initializeFirebase: () async => const FirebaseBootstrapResult(
            available: false,
            message: 'Firebase indisponível para o teste.',
          ),
          createAuthRepository: () {
            authFactoryCalled = true;
            return _FakeAuthRepository();
          },
          createGoalRepository: () {
            goalFactoryCalled = true;
            return _FakeGoalRepository();
          },
        ),
        throwsA(
          isA<FirebaseInitializationException>().having(
            (error) => error.message,
            'message',
            'Firebase indisponível para o teste.',
          ),
        ),
      );

      expect(authFactoryCalled, isFalse);
      expect(goalFactoryCalled, isFalse);
    });

    test('Firebase inicializado seleciona os repositórios injetados', () async {
      const user = AppUser(id: 'uid-real', email: 'usuario@axios.app');
      final dependencies = await AppDependencies.bootstrap(
        initializeFirebase: () async =>
            const FirebaseBootstrapResult(available: true),
        createAuthRepository: () => _FakeAuthRepository(initialUser: user),
        createGoalRepository: _FakeGoalRepository.new,
        createTransactionRepository: InMemoryTransactionRepository.new,
      );
      addTearDown(dependencies.controller.dispose);

      expect(dependencies.mode, AppMode.firebase);
      expect(dependencies.controller.firebaseAvailable, isTrue);
      expect(dependencies.controller.user?.id, 'uid-real');
    });

    test('modo demonstração só é criado explicitamente', () {
      final dependencies = AppDependencies.demo();
      addTearDown(dependencies.controller.dispose);

      expect(dependencies.mode, AppMode.demo);
      expect(dependencies.controller.firebaseAvailable, isFalse);
    });
  });

  group('erros de autenticação', () {
    test('credencial inválida produz erro compreensível', () async {
      final dependencies = await AppDependencies.bootstrap(
        initializeFirebase: () async =>
            const FirebaseBootstrapResult(available: true),
        createAuthRepository: () => _FakeAuthRepository(
          signInError: FirebaseAuthException(code: 'invalid-credential'),
        ),
        createGoalRepository: _FakeGoalRepository.new,
        createTransactionRepository: InMemoryTransactionRepository.new,
      );
      addTearDown(dependencies.controller.dispose);

      final success = await dependencies.controller.signIn(
        email: 'usuario@axios.app',
        password: 'senha-invalida',
      );

      expect(success, isFalse);
      expect(dependencies.controller.user, isNull);
      expect(dependencies.controller.authError, 'E-mail ou senha incorretos.');
    });

    test('e-mail duplicado produz erro compreensível', () async {
      final dependencies = await AppDependencies.bootstrap(
        initializeFirebase: () async =>
            const FirebaseBootstrapResult(available: true),
        createAuthRepository: () => _FakeAuthRepository(
          registerError: FirebaseAuthException(code: 'email-already-in-use'),
        ),
        createGoalRepository: _FakeGoalRepository.new,
        createTransactionRepository: InMemoryTransactionRepository.new,
      );
      addTearDown(dependencies.controller.dispose);

      final success = await dependencies.controller.register(
        name: 'Usuário',
        email: 'usuario@axios.app',
        password: '123456',
      );

      expect(success, isFalse);
      expect(
        dependencies.controller.authError,
        'Este e-mail já possui uma conta.',
      );
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.initialUser, this.signInError, this.registerError});

  final AppUser? initialUser;
  final FirebaseAuthException? signInError;
  final FirebaseAuthException? registerError;

  @override
  AppUser? get currentUser => initialUser;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (registerError != null) throw registerError!;
  }

  @override
  Future<void> signOut() async {}
}

class _FakeGoalRepository implements GoalRepository {
  @override
  Future<void> addGoal(String userId, Goal goal) async {}

  @override
  Future<void> updateGoal(String userId, Goal goal) async {}

  @override
  Future<void> deleteGoal(String userId, String goalId) async {}

  @override
  Future<void> seedDefaultsIfEmpty(String userId, List<Goal> defaults) async {}

  @override
  Stream<List<Goal>> watchGoals(String userId) => const Stream.empty();
}
