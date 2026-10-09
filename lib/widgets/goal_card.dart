import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/goal.dart';
import 'app_card.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, this.compact = false});

  final Goal goal;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.name,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.gray, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${AppFormatters.compactCurrency(goal.currentAmount)} / '
              '${AppFormatters.compactCurrency(goal.targetAmount)}',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontSize: compact ? 21 : 22),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${goal.progressPercent}% concluído',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 7,
              color: AppColors.gold,
              backgroundColor: AppColors.border,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(
              goal.monthsToComplete == 0
                  ? 'Meta concluída'
                  : 'Faltam ${goal.monthsToComplete} meses neste ritmo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
