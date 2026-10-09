import 'package:intl/intl.dart';

import '../../models/money.dart';

abstract final class AppFormatters {
  static final _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 2,
  );
  static const _months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  static String currency(double value) => _currency.format(value);

  static String money(Money value) => _currency.format(value.asDouble);

  static String cents(int value) => _currency.format(value / 100);

  static String compactCurrency(double value) => NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 0,
  ).format(value);

  static String transactionDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')} ${_months[value.month - 1]}';

  static String monthYear(DateTime value) =>
      '${_months[value.month - 1]} ${value.year}';
}
