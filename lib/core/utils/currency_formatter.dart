import 'package:bepay/core/constants/app_constants.dart';

String formatMoney({required int amountMinor, required String currencyCode}) {
  final negative = amountMinor < 0;
  final absolute = amountMinor.abs();
  final major = _groupThousands(absolute ~/ 100);
  final minor = (absolute % 100).toString().padLeft(2, '0');
  final symbol = switch (currencyCode) {
    AppStrings.inrCode => AppStrings.inrSymbol,
    AppStrings.usdCode => AppStrings.usdSymbol,
    _ => '$currencyCode ',
  };
  return '${negative ? '-' : ''}$symbol$major.$minor';
}

String moneySemanticsLabel({
  required int amountMinor,
  required String currencyCode,
}) {
  final negative = amountMinor < 0;
  final absolute = amountMinor.abs();
  final major = _groupThousands(absolute ~/ 100);
  final minor = (absolute % 100).toString().padLeft(2, '0');
  final name = switch (currencyCode) {
    AppStrings.inrCode => AppStrings.inrSpokenName,
    AppStrings.usdCode => AppStrings.usdSpokenName,
    _ => currencyCode,
  };
  final sign = negative ? AppStrings.negativeSpokenPrefix : '';
  return '$sign$major.$minor $name';
}

String _groupThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    if (index > 0 && remaining % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
