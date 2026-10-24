import 'package:bepay/core/constants/app_constants.dart';

final class AppException implements Exception {
  const AppException([this.message = AppStrings.transactionRequestFailed]);

  final String message;

  @override
  String toString() => message;
}

final class TransactionFetchException extends AppException {
  const TransactionFetchException([
    super.message = AppStrings.transactionRequestFailed,
  ]);
}
