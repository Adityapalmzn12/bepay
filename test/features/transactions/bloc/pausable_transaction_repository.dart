import 'dart:async';

import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';
import 'package:bepay/features/transactions/domain/models/transaction_page.dart';
import 'package:bepay/features/transactions/domain/repositories/transaction_repository.dart';

final class PausableTransactionRepository implements TransactionRepository {
  PausableTransactionRepository(this._inner);

  final TransactionRepository _inner;
  final List<Completer<void>> _gates = [];

  int calls = 0;

  @override
  Future<TransactionPage> fetchTransactions({
    String? cursor,
    TransactionStatus? status,
    String? query,
  }) async {
    calls += 1;
    final gate = Completer<void>();
    _gates.add(gate);
    await gate.future;
    return _inner.fetchTransactions(
      cursor: cursor,
      status: status,
      query: query,
    );
  }

  void release(int callIndex) {
    _gates[callIndex].complete();
  }

  void releaseAll() {
    for (final gate in _gates) {
      if (!gate.isCompleted) gate.complete();
    }
  }
}
