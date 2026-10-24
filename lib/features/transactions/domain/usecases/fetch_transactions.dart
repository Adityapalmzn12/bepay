import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';
import 'package:bepay/features/transactions/domain/models/transaction_page.dart';
import 'package:bepay/features/transactions/domain/repositories/transaction_repository.dart';

final class FetchTransactions {
  const FetchTransactions(this._repository);

  final TransactionRepository _repository;

  Future<TransactionPage> call({
    String? cursor,
    TransactionStatus? status,
    String? query,
  }) {
    return _repository.fetchTransactions(
      cursor: cursor,
      status: status,
      query: query,
    );
  }
}
