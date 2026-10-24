import 'package:bepay/features/transactions/data/datasources/fake_transaction_data_source.dart';
import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';
import 'package:bepay/features/transactions/domain/models/transaction_page.dart';
import 'package:bepay/features/transactions/domain/repositories/transaction_repository.dart';

final class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._dataSource);

  final FakeTransactionDataSource _dataSource;

  @override
  Future<TransactionPage> fetchTransactions({
    String? cursor,
    TransactionStatus? status,
    String? query,
  }) {
    return _dataSource.fetchTransactions(
      cursor: cursor,
      status: status,
      query: query,
    );
  }
}
