import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/financial_transaction.dart';
import '../models/money.dart';
import '../models/transaction_category.dart';
import '../repositories/transaction_repository.dart';
import '../services/statement_import.dart';
import '../services/pluggy_service.dart';
import '../state/app_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/screen_header.dart';
import 'pluggy_connect_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.controller,
    this.importCoordinator = const StatementImportCoordinator(),
    this.pluggyClient,
  });

  final AppController controller;
  final StatementImportCoordinator importCoordinator;
  final PluggyBackendClient? pluggyClient;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _filter = TransactionFilter.all;
  TransactionCategory? _category;
  String _query = '';
  bool _preparingImport = false;
  bool _connectingPluggy = false;
  PluggyBackendClient? _ownedPluggyClient;

  @override
  void dispose() {
    _ownedPluggyClient?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final visibleTransactions = filterTransactions(
            widget.controller.transactions,
            filter: _filter,
            category: _category,
            query: _query,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScreenHeader(
                      title: 'Transações',
                      subtitle: 'Acompanhe suas movimentações',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.controller.firebaseAvailable)
                            IconButton(
                              key: const ValueKey('connect-pluggy-button'),
                              tooltip: 'Conectar Pluggy Sandbox',
                              onPressed: _connectingPluggy
                                  ? null
                                  : _connectPluggy,
                              icon: _connectingPluggy
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.account_balance_outlined),
                            ),
                          IconButton(
                            key: const ValueKey('import-pdf-button'),
                            tooltip: 'Importar extrato PDF',
                            onPressed: _preparingImport ? null : _importPdf,
                            icon: _preparingImport
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf_outlined),
                          ),
                          IconButton(
                            key: const ValueKey('new-transaction-button'),
                            tooltip: 'Adicionar transação',
                            onPressed: () => _showTransactionForm(),
                            icon: const Icon(Icons.add_circle_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const ValueKey('transaction-search'),
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Buscar transação',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Todas',
                            selected: _filter == TransactionFilter.all,
                            onTap: () =>
                                setState(() => _filter = TransactionFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Receitas',
                            selected: _filter == TransactionFilter.income,
                            onTap: () => setState(
                              () => _filter = TransactionFilter.income,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Despesas',
                            selected: _filter == TransactionFilter.expense,
                            onTap: () => setState(
                              () => _filter = TransactionFilter.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<TransactionCategory?>(
                      key: const ValueKey('transaction-category-filter'),
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<TransactionCategory?>(
                          value: null,
                          child: Text('Todas as categorias'),
                        ),
                        ...TransactionCategory.values.map(
                          (category) => DropdownMenuItem<TransactionCategory?>(
                            value: category,
                            child: Text(category.label),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _category = value),
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _buildBody(visibleTransactions)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(List<FinancialTransaction> visibleTransactions) {
    if (widget.controller.transactionsStatus == TransactionsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.controller.transactionsStatus == TransactionsStatus.error) {
      return _EmptyTransactions(
        icon: Icons.cloud_off_rounded,
        title:
            widget.controller.transactionsError ??
            'Não foi possível carregar as transações.',
      );
    }
    if (visibleTransactions.isEmpty) {
      return const _EmptyTransactions(
        icon: Icons.receipt_long_outlined,
        title: 'Nenhuma transação encontrada',
        subtitle: 'Adicione uma movimentação ou ajuste os filtros.',
      );
    }
    return ListView.separated(
      key: const PageStorageKey('transactions-list'),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: visibleTransactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final transaction = visibleTransactions[index];
        return _TransactionCard(
          transaction: transaction,
          onEdit: () => _showTransactionForm(transaction),
          onDelete: () => _confirmDelete(transaction),
        );
      },
    );
  }

  Future<void> _showTransactionForm([FinancialTransaction? transaction]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => _TransactionFormSheet(
        controller: widget.controller,
        transaction: transaction,
      ),
    );
  }

  Future<void> _confirmDelete(FinancialTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir transação?'),
        content: Text(
          '“${transaction.description}” será removida permanentemente.',
        ),
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
    final success = await widget.controller.deleteTransaction(transaction.id);
    if (!mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.controller.transactionsError ?? 'Erro.')),
    );
  }

  Future<void> _importPdf() async {
    setState(() => _preparingImport = true);
    try {
      final prepared = await widget.importCoordinator.pickAndPrepare();
      if (!mounted || prepared == null) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => StatementImportPreviewScreen(
            controller: widget.controller,
            prepared: prepared,
          ),
        ),
      );
    } on StatementImportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível preparar a importação do PDF.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _preparingImport = false);
    }
  }

  Future<void> _connectPluggy() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O SDK oficial Pluggy Connect para Flutter não oferece Web. '
            'Use o fluxo Android nesta etapa.',
          ),
        ),
      );
      return;
    }
    setState(() => _connectingPluggy = true);
    try {
      final client =
          widget.pluggyClient ?? (_ownedPluggyClient ??= PluggyBackendClient());
      final connectToken = await client.createConnectToken();
      if (!mounted) return;
      final itemId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => PluggyConnectScreen(connectToken: connectToken),
        ),
      );
      if (!mounted || itemId == null) return;
      await client.linkItem(itemId);
      final prepared = await client.loadTransactions(itemId);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => StatementImportPreviewScreen(
            controller: widget.controller,
            prepared: prepared,
          ),
        ),
      );
    } on PluggyIntegrationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível conectar ao Pluggy Sandbox.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _connectingPluggy = false);
    }
  }
}

class _TransactionFormSheet extends StatefulWidget {
  const _TransactionFormSheet({required this.controller, this.transaction});

  final AppController controller;
  final FinancialTransaction? transaction;

  @override
  State<_TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<_TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late TransactionType _type;
  late TransactionCategory _category;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.transaction;
    _descriptionController = TextEditingController(text: item?.description);
    _amountController = TextEditingController(
      text: item == null ? '' : item.amount.asDouble.toStringAsFixed(2),
    );
    _type = item?.type ?? TransactionType.expense;
    _category = item?.category ?? TransactionCategory.other;
    _date = item?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final amount = Money.tryParseUserInput(_amountController.text)!;
    setState(() => _saving = true);
    final current = widget.transaction;
    final item = FinancialTransaction(
      id: current?.id ?? '',
      description: _descriptionController.text.trim(),
      category: _type == TransactionType.income
          ? TransactionCategory.income
          : _category,
      date: _date,
      amountInCents: amount.cents.abs(),
      type: _type,
      origin: current?.origin ?? TransactionOrigin.manual,
      externalId: current?.externalId,
      importBatchId: current?.importBatchId,
      fingerprint: current?.fingerprint,
      createdAt: current?.createdAt,
      pending: current?.pending ?? false,
      excludedFromBudget: current?.excludedFromBudget ?? false,
    );
    final success = current == null
        ? await widget.controller.addTransaction(item)
        : await widget.controller.updateTransaction(item);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.controller.transactionsError ?? 'Erro.')),
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
                  widget.transaction == null
                      ? 'Nova transação'
                      : 'Editar transação',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Despesa'),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Receita'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: _saving
                      ? null
                      : (selection) => setState(() => _type = selection.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('transaction-description-field'),
                  controller: _descriptionController,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Informe uma descrição.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('transaction-amount-field'),
                  controller: _amountController,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixText: r'R$ ',
                  ),
                  validator: (value) {
                    final money = Money.tryParseUserInput(value ?? '');
                    return money == null || money.cents <= 0
                        ? 'Informe um valor maior que zero.'
                        : null;
                  },
                ),
                if (_type == TransactionType.expense) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TransactionCategory>(
                    key: const ValueKey('transaction-category-field'),
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: TransactionCategory.values
                        .where((value) => value != TransactionCategory.income)
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _category = value!),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey('transaction-date-field'),
                  onPressed: _saving ? null : _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    '${_date.day.toString().padLeft(2, '0')}/'
                    '${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('save-transaction-button'),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar transação'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (!mounted || selected == null) return;
    setState(() => _date = selected);
  }
}

class StatementImportPreviewScreen extends StatefulWidget {
  const StatementImportPreviewScreen({
    super.key,
    required this.controller,
    required this.prepared,
  });

  final AppController controller;
  final PreparedStatementImport prepared;

  @override
  State<StatementImportPreviewScreen> createState() =>
      _StatementImportPreviewScreenState();
}

class _StatementImportPreviewScreenState
    extends State<StatementImportPreviewScreen> {
  late List<FinancialTransaction> _items;
  ImportMode _mode = ImportMode.addWithoutDuplicates;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.prepared.result.transactions);
  }

  Set<String> get _existingFingerprints => widget.controller.transactions
      .map((item) => item.fingerprint)
      .whereType<String>()
      .toSet();

  int get _duplicateCount => _items
      .where(
        (item) =>
            item.fingerprint != null &&
            _existingFingerprints.contains(item.fingerprint),
      )
      .length;

  int get _replaceCount => widget.controller.transactions
      .where(
        (item) =>
            item.origin == widget.prepared.origin &&
            !item.date.isBefore(widget.prepared.result.periodStart) &&
            item.date.isBefore(widget.prepared.result.periodEndExclusive),
      )
      .length;

  @override
  Widget build(BuildContext context) {
    final income = _items
        .where((item) => item.type == TransactionType.income)
        .fold(0, (total, item) => total + item.amountInCents);
    final expenses = _items
        .where((item) => item.type == TransactionType.expense)
        .fold(0, (total, item) => total + item.amountInCents);
    return Scaffold(
      appBar: AppBar(title: const Text('Prévia do extrato')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    widget.prepared.fileName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    color: AppColors.goldSoft,
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        Text('${_items.length} lançamentos'),
                        Text('Receitas: ${AppFormatters.cents(income)}'),
                        Text('Despesas: ${AppFormatters.cents(expenses)}'),
                        Text('Possíveis duplicatas: $_duplicateCount'),
                        Text(
                          'Linhas para revisar: '
                          '${widget.prepared.result.unrecognizedLines.length}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadioGroup<ImportMode>(
                    groupValue: _mode,
                    onChanged: (value) => setState(() => _mode = value!),
                    child: Column(
                      children: [
                        const RadioListTile(
                          value: ImportMode.addWithoutDuplicates,
                          title: Text('Adicionar sem duplicar'),
                          subtitle: Text(
                            'Mantém o histórico e ignora lançamentos já existentes.',
                          ),
                        ),
                        RadioListTile(
                          value: ImportMode.replaceImportedPeriod,
                          title: const Text(
                            'Substituir importados deste período',
                          ),
                          subtitle: Text(
                            'Substitui $_replaceCount registro(s) da mesma origem; outras origens são preservadas.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var index = 0; index < _items.length; index++) ...[
                    _PreviewTransactionCard(
                      transaction: _items[index],
                      duplicate:
                          _items[index].fingerprint != null &&
                          _existingFingerprints.contains(
                            _items[index].fingerprint,
                          ),
                      onCategoryChanged: (category) => setState(
                        () => _items[index] = _items[index].copyWith(
                          category: category,
                        ),
                      ),
                      onRemove: () => setState(() => _items.removeAt(index)),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: FilledButton(
                key: const ValueKey('confirm-import-button'),
                onPressed: _saving || _items.isEmpty ? null : _confirmImport,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar importação'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmImport() async {
    if (_mode == ImportMode.replaceImportedPeriod && _replaceCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Substituir importação?'),
          content: Text(
            '$_replaceCount transação(ões) importada(s) por PDF neste período serão removidas antes da nova gravação.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Substituir'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _saving = true);
    final result = await widget.controller.importTransactions(
      _items,
      mode: _mode,
      periodStart: widget.prepared.result.periodStart,
      periodEndExclusive: widget.prepared.result.periodEndExclusive,
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.transactionsError ?? 'Falha na importação.',
          ),
        ),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.inserted} importada(s), '
          '${result.skippedDuplicates} duplicata(s) ignorada(s).',
        ),
      ),
    );
  }
}

class _PreviewTransactionCard extends StatelessWidget {
  const _PreviewTransactionCard({
    required this.transaction,
    required this.duplicate,
    required this.onCategoryChanged,
    required this.onRemove,
  });

  final FinancialTransaction transaction;
  final bool duplicate;
  final ValueChanged<TransactionCategory> onCategoryChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                transaction.description,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (duplicate)
              const Tooltip(
                message: 'Possível duplicata',
                child: Icon(Icons.content_copy_rounded, color: AppColors.gray),
              ),
            IconButton(
              tooltip: 'Remover da prévia',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        Text(
          '${AppFormatters.transactionDate(transaction.date)} • '
          '${AppFormatters.money(transaction.amount)}',
        ),
        const SizedBox(height: 8),
        DropdownButton<TransactionCategory>(
          value: transaction.category,
          isExpanded: true,
          items: TransactionCategory.values
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onCategoryChanged(value);
          },
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: AppColors.gold,
    backgroundColor: AppColors.surface,
    side: BorderSide(color: selected ? AppColors.gold : AppColors.border),
    showCheckmark: false,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    labelStyle: TextStyle(
      fontFamily: 'Inter',
      color: AppColors.graphite,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    ),
  );
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final FinancialTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.goldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: isIncome ? AppColors.success : AppColors.graphite,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category.label} • ${transaction.origin.name.toUpperCase()}'
                  '${transaction.excludedFromBudget ? ' • fora do orçamento' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${AppFormatters.money(transaction.amount)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isIncome ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                AppFormatters.transactionDate(transaction.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Editar',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 19),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Excluir',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.gray),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    ),
  );
}
