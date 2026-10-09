import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/goal.dart';
import '../state/app_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/goal_card.dart';
import '../widgets/screen_header.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => CustomScrollView(
          key: const PageStorageKey('goals-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ScreenHeader(
                          title: 'Minhas metas',
                          subtitle: 'Acompanhe seus objetivos financeiros',
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          key: const ValueKey('new-goal-button'),
                          onPressed: () => _showGoalForm(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Nova meta'),
                        ),
                        const SizedBox(height: 20),
                        _buildState(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildState(BuildContext context) {
    return switch (controller.goalsStatus) {
      GoalsStatus.loading => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      GoalsStatus.error => _GoalsMessage(
        icon: Icons.cloud_off_rounded,
        title: controller.goalsError ?? 'Não foi possível carregar suas metas.',
      ),
      GoalsStatus.empty => const _GoalsMessage(
        icon: Icons.flag_outlined,
        title: 'Você ainda não tem metas.',
        subtitle: 'Crie a primeira para montar seu plano.',
      ),
      GoalsStatus.loaded => _GoalsList(goals: controller.goals),
    };
  }

  Future<void> _showGoalForm(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => _NewGoalSheet(controller: controller),
    );
  }
}

class _NewGoalSheet extends StatefulWidget {
  const _NewGoalSheet({required this.controller});

  final AppController controller;

  @override
  State<_NewGoalSheet> createState() => _NewGoalSheetState();
}

class _NewGoalSheetState extends State<_NewGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _currentController;
  late final TextEditingController _targetController;
  late final TextEditingController _monthsController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _currentController = TextEditingController(text: '0');
    _targetController = TextEditingController();
    _monthsController = TextEditingController(text: '12');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentController.dispose();
    _targetController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    final current = _parseMoney(_currentController.text);
    final target = _parseMoney(_targetController.text);
    if (current >= target) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O objetivo deve ser maior que o valor acumulado.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final saved = await widget.controller.addGoal(
      name: _nameController.text,
      currentAmount: current,
      targetAmount: target,
      deadlineMonths: int.parse(_monthsController.text),
    );
    if (!mounted) return;

    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nova meta',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('goal-name-field'),
                  controller: _nameController,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nome da meta'),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Informe o nome da meta.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('goal-current-amount-field'),
                  controller: _currentController,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor já acumulado',
                    prefixText: r'R$ ',
                  ),
                  validator: _validateMoney,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('goal-target-amount-field'),
                  controller: _targetController,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor objetivo',
                    prefixText: r'R$ ',
                  ),
                  validator: _validateMoney,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('goal-deadline-months-field'),
                  controller: _monthsController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prazo em meses',
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    return parsed == null || parsed <= 0
                        ? 'Informe um prazo válido.'
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('save-goal-button'),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar meta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateMoney(String? value) =>
      _parseMoney(value ?? '') <= 0 ? 'Informe um valor maior que zero.' : null;

  double _parseMoney(String value) {
    final trimmed = value.trim();
    final normalized = trimmed.contains(',')
        ? trimmed.replaceAll('.', '').replaceAll(',', '.')
        : trimmed;
    return double.tryParse(normalized) ?? 0;
  }
}

class _GoalsList extends StatelessWidget {
  const _GoalsList({required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final featured = goals.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < goals.length; index++) ...[
          GoalCard(goal: goals[index]),
          if (index < goals.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 20),
        AppCard(
          color: AppColors.goldSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plano da meta ${featured.name}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppFormatters.currency(featured.monthlyContribution)} por mês',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Considerando os ${AppFormatters.currency(featured.currentAmount)} '
                'já acumulados, faltam ${AppFormatters.currency(featured.remainingAmount)}. '
                'Nesse ritmo, a meta pode ser alcançada em '
                '${featured.monthsToComplete} meses.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _GoalsMessage extends StatelessWidget {
  const _GoalsMessage({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.gray),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
