import 'dart:async';

import '../models/goal.dart';
import 'goal_repository.dart';

class InMemoryGoalRepository implements GoalRepository {
  InMemoryGoalRepository({List<Goal> initialGoals = const []})
    : _goals = List<Goal>.from(initialGoals);

  final _controller = StreamController<List<Goal>>.broadcast();
  final List<Goal> _goals;

  @override
  Stream<List<Goal>> watchGoals(String userId) async* {
    yield List.unmodifiable(_goals);
    yield* _controller.stream;
  }

  @override
  Future<void> addGoal(String userId, Goal goal) async {
    final id = goal.id.isEmpty
        ? 'goal-${DateTime.now().microsecondsSinceEpoch}'
        : goal.id;
    _goals.add(goal.copyWith(id: id));
    _controller.add(List.unmodifiable(_goals));
  }

  @override
  Future<void> seedDefaultsIfEmpty(String userId, List<Goal> defaults) async {
    if (_goals.isEmpty) {
      _goals.addAll(defaults);
      _controller.add(List.unmodifiable(_goals));
    }
  }
}
