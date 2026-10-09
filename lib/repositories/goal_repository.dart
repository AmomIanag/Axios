import '../models/goal.dart';

abstract interface class GoalRepository {
  Stream<List<Goal>> watchGoals(String userId);

  Future<void> addGoal(String userId, Goal goal);

  Future<void> updateGoal(String userId, Goal goal);

  Future<void> deleteGoal(String userId, String goalId);

  Future<void> seedDefaultsIfEmpty(String userId, List<Goal> defaults);
}
