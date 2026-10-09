enum TransactionCategory {
  income('receita', 'Receita'),
  housing('moradia', 'Moradia'),
  food('alimentacao', 'Alimentação'),
  transport('transporte', 'Transporte'),
  health('saude', 'Saúde'),
  leisure('lazer', 'Lazer'),
  education('educacao', 'Educação'),
  subscriptions('assinaturas', 'Assinaturas'),
  utilities('contas', 'Contas'),
  shopping('compras', 'Compras'),
  services('servicos', 'Serviços'),
  transfer('transferencia', 'Transferência'),
  other('outros', 'Outros');

  const TransactionCategory(this.id, this.label);

  final String id;
  final String label;

  static TransactionCategory fromId(String? value) {
    final normalized = value?.trim().toLowerCase();
    return values.firstWhere(
      (category) =>
          category.id == normalized ||
          category.label.toLowerCase() == normalized,
      orElse: () => TransactionCategory.other,
    );
  }
}
