import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';
import 'package:bepay/features/transactions/domain/models/transaction_page.dart';

abstract interface class TransactionRepository {
  Future<TransactionPage> fetchTransactions({
    String? cursor,
    TransactionStatus? status,
    String? query,
  });
}
