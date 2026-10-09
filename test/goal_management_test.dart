import 'package:axios/data/mock_financial_data.dart';
import 'package:axios/models/app_user.dart';
import 'package:axios/repositories/demo_auth_repository.dart';
import 'package:axios/repositories/in_memory_goal_repository.dart';
import 'package:axios/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('edita, registra aporte e exclui meta sem perder precisão', () async {
    final repository = InMemoryGoalRepository(
      initialGoals: [MockFinancialData.goals.first],
    );
    final controller = AppController(
      DemoAuthRepository(
        initialUser: const AppUser(
          id: 'user',
          email: 'user@axios.app',
          displayName: 'Usuário',
        ),
      ),
      repository,
      firebaseAvailable: false,
    )..initialize();
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final original = controller.goals.single;
    expect(
      await controller.updateGoal(
        goal: original,
        name: 'Viagem editada',
        currentAmount: 1500,
        targetAmount: 6000,
        deadlineMonths: 8,
      ),
      isTrue,
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.goals.single.monthlyContribution, 562.5);

    expect(
      await controller.addGoalContribution(controller.goals.single, 250.25),
      isTrue,
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.goals.single.currentAmount, 1750.25);

    expect(await controller.deleteGoal(controller.goals.single.id), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(controller.goals, isEmpty);
  });
}
