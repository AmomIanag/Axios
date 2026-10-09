import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/financial_summary.dart';
import '../models/financial_transaction.dart';
import '../models/goal.dart';
import '../repositories/auth_repository.dart';
import '../repositories/goal_repository.dart';
import '../repositories/in_memory_transaction_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/financial_engine.dart';

enum GoalsStatus { loading, loaded, empty, error }

enum TransactionsStatus { loading, loaded, empty, error }

class AppController extends ChangeNotifier {
  AppController(
    this._authRepository,
    this._goalRepository, {
    TransactionRepository? transactionRepository,
    required this.firebaseAvailable,
    this.firebaseMessage,
  }) : _transactionRepository =
           transactionRepository ?? InMemoryTransactionRepository();

  final AuthRepository _authRepository;
  final GoalRepository _goalRepository;
  final TransactionRepository _transactionRepository;
  final FinancialEngine _financialEngine = const FinancialEngine();
  final bool firebaseAvailable;
  final String? firebaseMessage;

  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<List<Goal>>? _goalsSubscription;
  StreamSubscription<List<FinancialTransaction>>? _transactionsSubscription;
  AppUser? user;
  bool authBusy = false;
  String? authError;
  GoalsStatus goalsStatus = GoalsStatus.loading;
  String? goalsError;
  List<Goal> goals = const [];
  TransactionsStatus transactionsStatus = TransactionsStatus.loading;
  String? transactionsError;
  bool transactionBusy = false;
  List<FinancialTransaction> transactions = const [];
  FinancialPeriod selectedPeriod = FinancialPeriod(
    DateTime.now().year,
    DateTime.now().month,
  );
  bool _periodWasSelected = false;

  List<FinancialTransaction> get periodTransactions =>
      _financialEngine.forPeriod(transactions, selectedPeriod);

  FinancialSummary get financialSummary =>
      _financialEngine.summary(transactions, period: selectedPeriod);

  Map<String, int> get expensesByCategory => {
    for (final entry
        in _financialEngine
            .expensesByCategory(transactions, period: selectedPeriod)
            .entries)
      entry.key.label: entry.value,
  };

  int get estimatedSavingCapacityInCents =>
      financialSummary.estimatedSavingCapacityMoney.cents;

  void initialize() {
    user = _authRepository.currentUser;
    _authSubscription = _authRepository.authStateChanges.listen(_onAuthChanged);
    if (user != null) _subscribeUserData(user!);
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async => _runAuthAction(
    () => _authRepository.signIn(email: email, password: password),
  );

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async => _runAuthAction(
    () =>
        _authRepository.register(name: name, email: email, password: password),
  );

  Future<void> signOut() async => _authRepository.signOut();

  void selectPeriod(FinancialPeriod period) {
    if (selectedPeriod == period) return;
    selectedPeriod = period;
    _periodWasSelected = true;
    notifyListeners();
  }

  Future<bool> addTransaction(FinancialTransaction transaction) =>
      _runTransactionAction(
        (userId) => _transactionRepository.addTransaction(userId, transaction),
      );

  Future<bool> updateTransaction(FinancialTransaction transaction) =>
      _runTransactionAction(
        (userId) =>
            _transactionRepository.updateTransaction(userId, transaction),
      );

  Future<bool> deleteTransaction(String transactionId) => _runTransactionAction(
    (userId) => _transactionRepository.deleteTransaction(userId, transactionId),
  );

  Future<TransactionImportResult?> importTransactions(
    List<FinancialTransaction> items, {
    required ImportMode mode,
    required DateTime periodStart,
    required DateTime periodEndExclusive,
  }) async {
    final currentUser = user;
    if (currentUser == null || transactionBusy) return null;
    transactionBusy = true;
    transactionsError = null;
    notifyListeners();
    try {
      return await _transactionRepository.importTransactions(
        currentUser.id,
        items,
        mode: mode,
        periodStart: periodStart,
        periodEndExclusive: periodEndExclusive,
      );
    } catch (_) {
      transactionsError = 'Não foi possível importar o extrato sem alterar os dados existentes.';
      notifyListeners();
      return null;
    } finally {
      transactionBusy = false;
      notifyListeners();
    }
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
      final remaining = (targetAmount - currentAmount)
          .clamp(0, double.infinity)
          .toDouble();
      await _goalRepository.addGoal(
        currentUser.id,
        Goal(
          id: '',
          name: name.trim(),
          currentAmount: currentAmount,
          targetAmount: targetAmount,
          deadlineMonths: deadlineMonths,
          monthlyContribution: remaining / deadlineMonths,
          createdAt: DateTime.now(),
        ),
      );
      return true;
    } catch (_) {
      _setGoalActionError('Não foi possível salvar a meta. Tente novamente.');
      return false;
    }
  }

  Future<bool> updateGoal({
    required Goal goal,
    required String name,
    required double currentAmount,
    required double targetAmount,
    required int deadlineMonths,
  }) async {
    final currentUser = user;
    if (currentUser == null) return false;
    try {
      final remaining = (targetAmount - currentAmount)
          .clamp(0, double.infinity)
          .toDouble();
      await _goalRepository.updateGoal(
        currentUser.id,
        goal.copyWith(
          name: name.trim(),
          currentAmount: currentAmount,
          targetAmount: targetAmount,
          deadlineMonths: deadlineMonths,
          monthlyContribution: deadlineMonths <= 0
              ? remaining
              : remaining / deadlineMonths,
        ),
      );
      return true;
    } catch (_) {
      _setGoalActionError('Não foi possível atualizar a meta.');
      return false;
    }
  }

  Future<bool> addGoalContribution(Goal goal, double amount) => updateGoal(
    goal: goal,
    name: goal.name,
    currentAmount: (goal.currentAmount + amount).clamp(0, goal.targetAmount),
    targetAmount: goal.targetAmount,
    deadlineMonths: goal.deadlineMonths,
  );

  Future<bool> deleteGoal(String goalId) async {
    final currentUser = user;
    if (currentUser == null) return false;
    try {
      await _goalRepository.deleteGoal(currentUser.id, goalId);
      return true;
    } catch (_) {
      _setGoalActionError('Não foi possível excluir a meta.');
      return false;
    }
  }

  Future<bool> _runTransactionAction(
    Future<void> Function(String userId) action,
  ) async {
    final currentUser = user;
    if (currentUser == null || transactionBusy) return false;
    transactionBusy = true;
    transactionsError = null;
    notifyListeners();
    try {
      await action(currentUser.id);
      return true;
    } catch (_) {
      transactionsError = 'Não foi possível salvar a transação.';
      notifyListeners();
      return false;
    } finally {
      transactionBusy = false;
      notifyListeners();
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
    _transactionsSubscription?.cancel();
    goals = const [];
    transactions = const [];
    goalsStatus = GoalsStatus.loading;
    transactionsStatus = TransactionsStatus.loading;
    _periodWasSelected = false;
    if (nextUser != null) _subscribeUserData(nextUser);
    notifyListeners();
  }

  void _subscribeUserData(AppUser currentUser) {
    _subscribeToGoals(currentUser);
    _subscribeToTransactions(currentUser);
  }

  void _subscribeToGoals(AppUser currentUser) {
    goalsStatus = GoalsStatus.loading;
    _goalsSubscription = _goalRepository.watchGoals(currentUser.id).listen((
      items,
    ) {
      goals = items;
      goalsStatus = items.isEmpty ? GoalsStatus.empty : GoalsStatus.loaded;
      goalsError = null;
      notifyListeners();
    }, onError: (_) => _setGoalsError('Não foi possível carregar suas metas.'));
  }

  void _subscribeToTransactions(AppUser currentUser) {
    transactionsStatus = TransactionsStatus.loading;
    _transactionsSubscription = _transactionRepository
        .watchTransactions(currentUser.id)
        .listen(
          (items) {
            transactions = items;
            transactionsStatus = items.isEmpty
                ? TransactionsStatus.empty
                : TransactionsStatus.loaded;
            transactionsError = null;
            if (!_periodWasSelected && items.isNotEmpty) {
              final latest = items.reduce(
                (a, b) => a.date.isAfter(b.date) ? a : b,
              );
              selectedPeriod = FinancialPeriod(
                latest.date.year,
                latest.date.month,
              );
            }
            notifyListeners();
          },
          onError: (_) {
            transactionsStatus = TransactionsStatus.error;
            transactionsError = 'Não foi possível carregar as transações.';
            notifyListeners();
          },
        );
  }

  void _setGoalsError(String message) {
    goalsError = message;
    goalsStatus = GoalsStatus.error;
    notifyListeners();
  }

  void _setGoalActionError(String message) {
    goalsError = message;
    notifyListeners();
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
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
