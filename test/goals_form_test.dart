import 'dart:async';

import 'package:axios/app.dart';
import 'package:axios/app_dependencies.dart';
import 'package:axios/data/mock_financial_data.dart';
import 'package:axios/models/app_user.dart';
import 'package:axios/models/goal.dart';
import 'package:axios/repositories/demo_auth_repository.dart';
import 'package:axios/repositories/in_memory_goal_repository.dart';
import 'package:axios/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cria duas metas e mantém a navegação funcional', (tester) async {
    final dependencies = AppDependencies.demo(authenticated: true);
    addTearDown(dependencies.controller.dispose);

    await tester.pumpWidget(AxiosApp(controller: dependencies.controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();

    await _createGoal(
      tester,
      name: 'Reserva de emergência',
      currentAmount: '500',
      targetAmount: '5000',
      months: '9',
      validateBeforeFill: true,
    );
    expect(find.text('Reserva de emergência'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _createGoal(
      tester,
      name: 'Curso de Flutter',
      currentAmount: '200',
      targetAmount: '2000',
      months: '6',
    );
    expect(find.text('Curso de Flutter'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    expect(find.text('Acompanhe suas movimentações'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    expect(find.text('Reserva de emergência'), findsOneWidget);
    expect(find.text('Curso de Flutter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bloqueia novo envio enquanto a meta está sendo salva', (
    tester,
  ) async {
    final repository = _DelayedGoalRepository(
      initialGoals: MockFinancialData.goals,
    );
    final controller = AppController(
      DemoAuthRepository(
        initialUser: const AppUser(
          id: 'demo-user',
          email: 'demo@axios.app',
          displayName: 'Demo',
        ),
      ),
      repository,
      firebaseAvailable: false,
    )..initialize();
    addTearDown(controller.dispose);

    await tester.pumpWidget(AxiosApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();

    await _openAndFillGoalForm(
      tester,
      name: 'Meta sem duplicação',
      currentAmount: '100',
      targetAmount: '1000',
      months: '9',
    );

    final saveButton = find.byKey(const ValueKey('save-goal-button'));
    await tester.tap(saveButton);
    await tester.pump();

    expect(repository.addCalls, 1);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    repository.completeSave();
    await tester.pumpAndSettle();

    expect(repository.addCalls, 1);
    expect(find.text('Meta sem duplicação'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _createGoal(
  WidgetTester tester, {
  required String name,
  required String currentAmount,
  required String targetAmount,
  required String months,
  bool validateBeforeFill = false,
}) async {
  await _openAndFillGoalForm(
    tester,
    name: name,
    currentAmount: currentAmount,
    targetAmount: targetAmount,
    months: months,
    validateBeforeFill: validateBeforeFill,
  );

  await tester.tap(find.byKey(const ValueKey('save-goal-button')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('goal-name-field')), findsNothing);
}

Future<void> _openAndFillGoalForm(
  WidgetTester tester, {
  required String name,
  required String currentAmount,
  required String targetAmount,
  required String months,
  bool validateBeforeFill = false,
}) async {
  await tester.tap(find.byKey(const ValueKey('new-goal-button')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('goal-name-field')), findsOneWidget);
  if (validateBeforeFill) {
    await tester.tap(find.byKey(const ValueKey('save-goal-button')));
    await tester.pump();
    expect(find.text('Informe o nome da meta.'), findsOneWidget);
    expect(find.text('Informe um valor maior que zero.'), findsNWidgets(2));
  }
  await tester.enterText(find.byKey(const ValueKey('goal-name-field')), name);
  await tester.enterText(
    find.byKey(const ValueKey('goal-current-amount-field')),
    currentAmount,
  );
  await tester.enterText(
    find.byKey(const ValueKey('goal-target-amount-field')),
    targetAmount,
  );
  await tester.enterText(
    find.byKey(const ValueKey('goal-deadline-months-field')),
    months,
  );
}

class _DelayedGoalRepository extends InMemoryGoalRepository {
  _DelayedGoalRepository({required super.initialGoals});

  final _saveCompleter = Completer<void>();
  int addCalls = 0;

  @override
  Future<void> addGoal(String userId, Goal goal) async {
    addCalls++;
    await _saveCompleter.future;
    await super.addGoal(userId, goal);
  }

  void completeSave() => _saveCompleter.complete();
}
