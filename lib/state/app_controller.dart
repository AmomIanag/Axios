import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/mock_financial_data.dart';
import '../models/app_user.dart';
import '../models/goal.dart';
import '../repositories/auth_repository.dart';
import '../repositories/goal_repository.dart';

enum GoalsStatus { loading, loaded, empty, error }

class AppController extends ChangeNotifier {
  AppController(
    this._authRepository,
    this._goalRepository, {
    required this.firebaseAvailable,
    this.firebaseMessage,
  });

  final AuthRepository _authRepository;
  final GoalRepository _goalRepository;
  final bool firebaseAvailable;
  final String? firebaseMessage;

  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<List<Goal>>? _goalsSubscription;
  AppUser? user;
  bool authBusy = false;
  String? authError;
  GoalsStatus goalsStatus = GoalsStatus.loading;
  String? goalsError;
  List<Goal> goals = const [];

  void initialize() {
    user = _authRepository.currentUser;
    _authSubscription = _authRepository.authStateChanges.listen(_onAuthChanged);
    if (user != null) _subscribeToGoals(user!);
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _runAuthAction(
      () => _authRepository.signIn(email: email, password: password),
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _runAuthAction(
      () => _authRepository.register(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  Future<bool> addGoal({
    required String name,
    required double currentAmount,
    required double targetAmount,
    required int deadlineMonths,
  }) async {
    final currentUser = user;
    if (currentUser == null) return false;
    try {
      goalsError = null;
      await _goalRepository.addGoal(
        currentUser.id,
        Goal(
          id: '',
          name: name.trim(),
          currentAmount: currentAmount,
          targetAmount: targetAmount,
          deadlineMonths: deadlineMonths,
          monthlyContribution:
              (targetAmount - currentAmount).clamp(0, double.infinity) /
              deadlineMonths,
          createdAt: DateTime.now(),
        ),
      );
      return true;
    } catch (error) {
      goalsError = 'Não foi possível salvar a meta. Tente novamente.';
      goalsStatus = GoalsStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (error) {
      authError = _friendlyAuthError(error.code);
      return false;
    } catch (_) {
      authError =
          'Não foi possível concluir. Verifique sua conexão e tente novamente.';
      return false;
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  void _onAuthChanged(AppUser? nextUser) {
    user = nextUser;
    _goalsSubscription?.cancel();
    goals = const [];
    goalsStatus = GoalsStatus.loading;
    if (nextUser != null) _subscribeToGoals(nextUser);
    notifyListeners();
  }

  Future<void> _subscribeToGoals(AppUser currentUser) async {
    goalsStatus = GoalsStatus.loading;
    notifyListeners();
    try {
      await _goalRepository.seedDefaultsIfEmpty(
        currentUser.id,
        MockFinancialData.goals,
      );
      _goalsSubscription = _goalRepository
          .watchGoals(currentUser.id)
          .listen(
            (items) {
              goals = items;
              goalsStatus = items.isEmpty
                  ? GoalsStatus.empty
                  : GoalsStatus.loaded;
              goalsError = null;
              notifyListeners();
            },
            onError: (_) {
              goalsStatus = GoalsStatus.error;
              goalsError = 'Não foi possível carregar suas metas.';
              notifyListeners();
            },
          );
    } catch (_) {
      goalsStatus = GoalsStatus.error;
      goalsError = 'Não foi possível carregar suas metas.';
      notifyListeners();
    }
  }

  String _friendlyAuthError(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'E-mail ou senha incorretos.',
    'email-already-in-use' => 'Este e-mail já possui uma conta.',
    'invalid-email' => 'Digite um e-mail válido.',
    'weak-password' => 'Use uma senha com pelo menos 6 caracteres.',
    'user-disabled' => 'Esta conta foi desativada.',
    'too-many-requests' =>
      'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
    'operation-not-allowed' =>
      'O acesso por e-mail e senha não está disponível no momento.',
    'network-request-failed' => 'Sem conexão. Tente novamente.',
    _ => 'Não foi possível autenticar. Tente novamente.',
  };

  @override
  void dispose() {
    _authSubscription?.cancel();
    _goalsSubscription?.cancel();
    super.dispose();
  }
}
