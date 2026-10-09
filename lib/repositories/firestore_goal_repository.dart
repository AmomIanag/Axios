import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/goal.dart';
import 'goal_repository.dart';

class FirestoreGoalRepository implements GoalRepository {
  FirestoreGoalRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _goals(String userId) =>
      _firestore.collection('users').doc(userId).collection('goals');

  @override
  Stream<List<Goal>> watchGoals(String userId) {
    return _goals(userId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => _fromFirestore(document))
              .toList(growable: false),
        );
  }

  @override
  Future<void> addGoal(String userId, Goal goal) async {
    final document = goal.id.isEmpty
        ? _goals(userId).doc()
        : _goals(userId).doc(goal.id);
    await document.set(_toFirestore(goal.copyWith(id: document.id)));
  }

  @override
  Future<void> seedDefaultsIfEmpty(String userId, List<Goal> defaults) async {
    final existing = await _goals(userId).limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = _firestore.batch();
    for (final goal in defaults) {
      batch.set(_goals(userId).doc(goal.id), _toFirestore(goal));
    }
    await batch.commit();
  }

  Goal _fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? const <String, dynamic>{};
    return Goal(
      id: document.id,
      name: data['name'] as String? ?? 'Meta',
      currentAmount: (data['currentAmount'] as num? ?? 0).toDouble(),
      targetAmount: (data['targetAmount'] as num? ?? 0).toDouble(),
      deadlineMonths: (data['deadlineMonths'] as num? ?? 1).toInt(),
      monthlyContribution: (data['monthlyContribution'] as num? ?? 0)
          .toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, Object> _toFirestore(Goal goal) => {
    'name': goal.name,
    'currentAmount': goal.currentAmount,
    'targetAmount': goal.targetAmount,
    'deadlineMonths': goal.deadlineMonths,
    'monthlyContribution': goal.monthlyContribution,
    'createdAt': Timestamp.fromDate(goal.createdAt),
  };
}
