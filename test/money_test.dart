import 'package:axios/models/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta valores brasileiros em centavos exatos', () {
    expect(Money.parseBrazilian(r'R$ 1.250,50').cents, 125050);
    expect(Money.parseBrazilian('39,90').cents, 3990);
    expect(Money.tryParseUserInput('0,01')?.cents, 1);
  });
}
