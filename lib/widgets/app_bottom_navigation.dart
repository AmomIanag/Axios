import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const labels = ['Início', 'Transações', 'Metas', 'Assistente'];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          width: double.infinity,
          child: Row(
            children: List.generate(labels.length, (index) {
              final selected = index == currentIndex;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: labels[index],
                  child: InkWell(
                    key: ValueKey('nav-$index'),
                    onTap: () => onChanged(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: selected ? 9 : 7,
                          height: selected ? 9 : 7,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.gold : AppColors.gray,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          labels[index],
                          maxLines: 1,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: selected
                                    ? AppColors.gold
                                    : AppColors.gray,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
