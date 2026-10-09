import 'dart:math' as math;

class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.currentAmount,
    required this.targetAmount,
    required this.deadlineMonths,
    required this.monthlyContribution,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double currentAmount;
  final double targetAmount;
  final int deadlineMonths;
  final double monthlyContribution;
  final DateTime createdAt;

  int get currentAmountInCents => (currentAmount * 100).round();
  int get targetAmountInCents => (targetAmount * 100).round();
  int get monthlyContributionInCents => (monthlyContribution * 100).round();
  int get remainingAmountInCents =>
      math.max(0, targetAmountInCents - currentAmountInCents);

  double get remainingAmount => math.max(0, targetAmount - currentAmount);

  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0, 1).toDouble();
  }

  int get progressPercent => (progress * 100).round();

  double monthlyNeededFor(int months) {
    if (months <= 0) return remainingAmount;
    return remainingAmount / months;
  }

  int get monthsToComplete {
    if (remainingAmount == 0) return 0;
    if (monthlyContribution <= 0) return 0;
    return (remainingAmount / monthlyContribution).ceil();
  }

  Goal copyWith({
    String? id,
    String? name,
    double? currentAmount,
    double? targetAmount,
    int? deadlineMonths,
    double? monthlyContribution,
    DateTime? createdAt,
  }) => Goal(
    id: id ?? this.id,
    name: name ?? this.name,
    currentAmount: currentAmount ?? this.currentAmount,
    targetAmount: targetAmount ?? this.targetAmount,
    deadlineMonths: deadlineMonths ?? this.deadlineMonths,
    monthlyContribution: monthlyContribution ?? this.monthlyContribution,
    createdAt: createdAt ?? this.createdAt,
  );
}
