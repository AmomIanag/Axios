import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import 'app_card.dart';

class SpendingChart extends StatelessWidget {
  const SpendingChart({super.key, required this.values});

  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = entries.isEmpty ? 1.0 : entries.first.value;
    return AppCard(
      child: SizedBox(
        height: 176,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: entries.map((entry) {
            final ratio = entry.value / maxValue;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.compactCurrency(entry.value),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      label:
                          '${entry.key}: ${AppFormatters.currency(entry.value)}',
                      child: Container(
                        height: 96 * ratio + 12,
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
