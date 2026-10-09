import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/goal.dart';
import '../models/money.dart';
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

  Widget _buildState(BuildContext context) => switch (controller.goalsStatus) {
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
    GoalsStatus.loaded => _GoalsList(
      controller: controller,
      goals: controller.goals,
      onEdit: (goal) => _showGoalForm(context, goal),
      onContribution: (goal) => _showContribution(context, goal),
      onDelete: (goal) => _confirmDelete(context, goal),
    ),
  };

  Future<void> _showGoalForm(BuildContext context, [Goal? goal]) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.background,
        builder: (_) => _GoalFormSheet(controller: controller, goal: goal),
      );

  Future<void> _showContribution(BuildContext context, Goal goal) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.background,
        builder: (_) => _ContributionSheet(controller: controller, goal: goal),
      );

  Future<void> _confirmDelete(BuildContext context, Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir meta?'),
        content: Text('A meta “${goal.name}” será removida permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await controller.deleteGoal(goal.id);
    if (!context.mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(controller.goalsError ?? 'Erro ao excluir meta.')),
    );
  }
}

class _GoalFormSheet extends StatefulWidget {
  const _GoalFormSheet({required this.controller, this.goal});

  final AppController controller;
  final Goal? goal;

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _currentController;
  late final TextEditingController _targetController;
  late final TextEditingController _monthsController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _nameController = TextEditingController(text: goal?.name);
    _currentController = TextEditingController(
      text: goal?.currentAmount.toStringAsFixed(2) ?? '0',
    );
    _targetController = TextEditingController(
      text: goal?.targetAmount.toStringAsFixed(2),
    );
    _monthsController = TextEditingController(
      text: goal?.deadlineMonths.toString() ?? '12',
    );
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
    final current = Money.tryParseUserInput(_currentController.text)!;
    final target = Money.tryParseUserInput(_targetController.text)!;
    if (current.cents > target.cents) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O acumulado não pode superar o objetivo.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final existing = widget.goal;
    final saved = existing == null
        ? await widget.controller.addGoal(
            name: _nameController.text,
            currentAmount: current.asDouble,
            targetAmount: target.asDouble,
            deadlineMonths: int.parse(_monthsController.text),
          )
        : await widget.controller.updateGoal(
            goal: existing,
            name: _nameController.text,
            currentAmount: current.asDouble,
            targetAmount: target.asDouble,
            deadlineMonths: int.parse(_monthsController.text),
          );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.controller.goalsError ?? 'Erro ao salvar meta.'),
      ),
    );
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
                  widget.goal == null ? 'Nova meta' : 'Editar meta',
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
                  validator: (value) {
                    final money = Money.tryParseUserInput(value ?? '');
                    return money == null || money.cents < 0
                        ? 'Informe um valor válido.'
                        : null;
                  },
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
                  validator: (value) {
                    final money = Money.tryParseUserInput(value ?? '');
                    return money == null || money.cents <= 0
                        ? 'Informe um valor maior que zero.'
                        : null;
                  },
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
}

class _ContributionSheet extends StatefulWidget {
  const _ContributionSheet({required this.controller, required this.goal});

  final AppController controller;
  final Goal goal;

  @override
  State<_ContributionSheet> createState() => _ContributionSheetState();
}

class _ContributionSheetState extends State<_ContributionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final amount = Money.tryParseUserInput(_amountController.text)!;
    final saved = await widget.controller.addGoalContribution(
      widget.goal,
      amount.asDouble,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.controller.goalsError ?? 'Erro ao salvar aporte.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registrar aporte',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Meta: ${widget.goal.name}'),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('goal-contribution-field'),
              controller: _amountController,
              enabled: !_saving,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor do aporte',
                prefixText: r'R$ ',
              ),
              validator: (value) {
                final money = Money.tryParseUserInput(value ?? '');
                return money == null || money.cents <= 0
                    ? 'Informe um valor maior que zero.'
                    : null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('save-contribution-button'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Registrar aporte'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GoalsList extends StatelessWidget {
  const _GoalsList({
    required this.controller,
    required this.goals,
    required this.onEdit,
    required this.onContribution,
    required this.onDelete,
  });

  final AppController controller;
  final List<Goal> goals;
  final ValueChanged<Goal> onEdit;
  final ValueChanged<Goal> onContribution;
  final ValueChanged<Goal> onDelete;

  @override
  Widget build(BuildContext context) {
    final featured = goals.first;
    final neededInCents = featured.deadlineMonths <= 0
        ? featured.remainingAmountInCents
        : (featured.remainingAmountInCents / featured.deadlineMonths).ceil();
    final insufficient =
        neededInCents > controller.estimatedSavingCapacityInCents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < goals.length; index++) ...[
          GoalCard(goal: goals[index]),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: goals[index].remainingAmountInCents == 0
                    ? null
                    : () => onContribution(goals[index]),
                icon: const Icon(Icons.savings_outlined),
                label: const Text('Aporte'),
              ),
              IconButton(
                tooltip: 'Editar meta',
                onPressed: () => onEdit(goals[index]),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Excluir meta',
                onPressed: () => onDelete(goals[index]),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (index < goals.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
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
                '${AppFormatters.cents(neededInCents)} por mês',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                featured.remainingAmountInCents == 0
                    ? 'Meta concluída. O objetivo já foi integralmente acumulado.'
                    : 'Considerando os ${AppFormatters.currency(featured.currentAmount)} '
                          'já acumulados, faltam ${AppFormatters.currency(featured.remainingAmount)}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (insufficient && featured.remainingAmountInCents > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'O valor mensal necessário supera a capacidade estimada de '
                  '${AppFormatters.cents(controller.estimatedSavingCapacityInCents)} '
                  'no período selecionado.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
  Widget build(BuildContext context) => Padding(
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
