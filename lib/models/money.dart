import 'dart:math' as math;

/// Monetary value represented in integer cents to avoid binary rounding errors.
class Money implements Comparable<Money> {
  const Money(this.cents);

  static const zero = Money(0);

  final int cents;

  double get asDouble => cents / 100;

  Money get absolute => Money(cents.abs());

  static Money? tryParseUserInput(String value) {
    var normalized = value
        .trim()
        .replaceAll(RegExp(r'[^\d,.-]'), '')
        .replaceAll(' ', '');
    if (normalized.isEmpty) return null;

    final lastComma = normalized.lastIndexOf(',');
    final lastDot = normalized.lastIndexOf('.');
    final decimalSeparator = math.max(lastComma, lastDot);
    String integerPart;
    String decimalPart;
    if (decimalSeparator >= 0 &&
        normalized.length - decimalSeparator - 1 <= 2) {
      integerPart = normalized.substring(0, decimalSeparator);
      decimalPart = normalized.substring(decimalSeparator + 1);
    } else {
      integerPart = normalized;
      decimalPart = '';
    }
    final negative = integerPart.startsWith('-');
    integerPart = integerPart.replaceAll(RegExp(r'[^\d]'), '');
    decimalPart = decimalPart.replaceAll(RegExp(r'[^\d]'), '');
    if (integerPart.isEmpty && decimalPart.isEmpty) return null;
    final whole = int.tryParse(integerPart.isEmpty ? '0' : integerPart);
    if (whole == null) return null;
    final fraction =
        int.tryParse(decimalPart.padRight(2, '0').substring(0, 2)) ?? 0;
    final cents = whole * 100 + fraction;
    return Money(negative ? -cents : cents);
  }

  static Money parseBrazilian(String value) {
    final parsed = tryParseUserInput(value);
    if (parsed == null) {
      throw FormatException('Valor monetário inválido: $value');
    }
    return parsed;
  }

  Money operator +(Money other) => Money(cents + other.cents);

  Money operator -(Money other) => Money(cents - other.cents);

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => 'Money($cents)';
}
