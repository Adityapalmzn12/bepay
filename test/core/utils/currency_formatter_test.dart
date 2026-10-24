import 'package:flutter_test/flutter_test.dart';

import 'package:bepay/core/utils/currency_formatter.dart';

void main() {
  test('formats INR and USD minor units without floating point', () {
    expect(formatMoney(amountMinor: 129900, currencyCode: 'INR'), '₹1,299.00');
    expect(formatMoney(amountMinor: 2599, currencyCode: 'USD'), r'$25.99');
    expect(formatMoney(amountMinor: 100, currencyCode: 'USD'), r'$1.00');
    expect(formatMoney(amountMinor: 0, currencyCode: 'INR'), '₹0.00');
    expect(formatMoney(amountMinor: -2599, currencyCode: 'USD'), r'-$25.99');
    expect(
      formatMoney(amountMinor: 9007199254740993, currencyCode: 'USD'),
      r'$90,071,992,547,409.93',
    );
  });

  test('speaks the currency name', () {
    expect(
      moneySemanticsLabel(amountMinor: 129900, currencyCode: 'INR'),
      '1,299.00 Indian rupees',
    );
    expect(
      moneySemanticsLabel(amountMinor: 2599, currencyCode: 'USD'),
      '25.99 US dollars',
    );
  });
}
