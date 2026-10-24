import 'package:flutter_test/flutter_test.dart';

import 'package:bepay/core/errors/app_exception.dart';
import 'package:bepay/features/transactions/data/datasources/fake_transaction_data_source.dart';
import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';

void main() {
  test('sample data is deterministic and covers the contract', () {
    final first = buildSampleTransactions();
    final second = buildSampleTransactions();

    expect(first, second);
    expect(first.length, greaterThanOrEqualTo(30));
    expect(first.map((item) => item.currencyCode).toSet(), {'INR', 'USD'});
    expect(
      first.map((item) => item.status).toSet(),
      TransactionStatus.values.toSet(),
    );
    expect(first.map((item) => item.id).toSet(), hasLength(first.length));
    expect(first.every((item) => item.createdAt.isUtc), isTrue);
    expect(first.any((item) => item.reference == null), isTrue);
    expect(first.any((item) => item.reference != null), isTrue);
    expect(
      first.where(
        (item) => item.amountMinor == 129900 && item.currencyCode == 'INR',
      ),
      hasLength(1),
    );
    expect(
      first.where(
        (item) => item.amountMinor == 2599 && item.currencyCode == 'USD',
      ),
      hasLength(1),
    );
  });

  test('filters the full list before paging and stops at the end', () async {
    final source = FakeTransactionDataSource(delay: Duration.zero);

    final firstPage = await source.fetchTransactions();
    expect(
      firstPage.transactions,
      hasLength(FakeTransactionDataSource.pageSize),
    );
    expect(firstPage.nextCursor, isNotNull);
    expect(
      firstPage.transactions.map((item) => item.status).toSet(),
      TransactionStatus.values.toSet(),
    );

    final pending = await _collect(source, status: TransactionStatus.pending);
    expect(pending, hasLength(12));
    expect(
      pending.every((item) => item.status == TransactionStatus.pending),
      isTrue,
    );
    expect(pending.map((item) => item.id).toSet(), hasLength(pending.length));
    for (var index = 0; index < pending.length - 1; index++) {
      expect(
        compareTransactions(pending[index], pending[index + 1]),
        lessThanOrEqualTo(0),
      );
    }
  });

  test('uses id descending as a tie-breaker for equal timestamps', () async {
    final sameTime = DateTime.utc(2026, 1, 1, 12);
    final source = FakeTransactionDataSource(
      delay: Duration.zero,
      transactions: [
        _transaction(id: 'txn_001', createdAt: sameTime),
        _transaction(
          id: 'txn_999',
          createdAt: sameTime.subtract(const Duration(days: 1)),
        ),
        _transaction(id: 'txn_002', createdAt: sameTime),
      ],
    );

    final page = await source.fetchTransactions();
    expect(page.transactions.map((item) => item.id).toList(), [
      'txn_002',
      'txn_001',
      'txn_999',
    ]);
  });

  test('fails a chosen call once, then lets the retry succeed', () async {
    final source = FakeTransactionDataSource(
      delay: Duration.zero,
      failOnCalls: {1},
    );

    expect(
      source.fetchTransactions(),
      throwsA(isA<TransactionFetchException>()),
    );
    final page = await source.fetchTransactions();
    expect(page.transactions, isNotEmpty);
  });

  test('armFailNextRequest fails only the following call', () async {
    final source = FakeTransactionDataSource(delay: Duration.zero);
    final first = await source.fetchTransactions();
    expect(first.transactions, isNotEmpty);

    source.armFailNextRequest();
    expect(
      source.fetchTransactions(),
      throwsA(isA<TransactionFetchException>()),
    );
    final retried = await source.fetchTransactions();
    expect(retried.transactions, isNotEmpty);
  });

  test('failAllRequests fails every call', () async {
    final source = FakeTransactionDataSource(
      delay: Duration.zero,
      failAllRequests: true,
    );
    expect(
      source.fetchTransactions(),
      throwsA(isA<TransactionFetchException>()),
    );
    expect(
      source.fetchTransactions(),
      throwsA(isA<TransactionFetchException>()),
    );
  });

  test('search and status both apply before paging', () async {
    final source = FakeTransactionDataSource(delay: Duration.zero);

    final byReference = await source.fetchTransactions(query: 'ref-1000');
    expect(byReference.transactions, hasLength(1));
    expect(byReference.transactions.single.reference, 'REF-1000');
    expect(byReference.nextCursor, isNull);

    final indigo = await _collect(source, query: 'Indigo');
    expect(indigo, isNotEmpty);
    expect(indigo.every((item) => item.merchantName == 'Indigo Cafe'), isTrue);

    final completedIndigo = await _collect(
      source,
      status: TransactionStatus.completed,
      query: 'INDIGO',
    );
    expect(completedIndigo, indigo);

    final pendingMetro = await _collect(
      source,
      status: TransactionStatus.pending,
      query: 'metro',
    );
    expect(pendingMetro, isNotEmpty);
    expect(
      pendingMetro.every((item) => item.merchantName == 'Metro Grocery'),
      isTrue,
    );

    final completedMetro = await _collect(
      source,
      status: TransactionStatus.completed,
      query: 'metro',
    );
    expect(completedMetro, isEmpty);
  });

  test('pages the search result rather than the unfiltered list', () async {
    final newest = DateTime.utc(2026, 6, 1);
    final source = FakeTransactionDataSource(
      delay: Duration.zero,
      transactions: [
        for (var index = 0; index < 15; index++)
          Transaction(
            id: 'alpha_$index',
            merchantName: 'Alpha Shop',
            amountMinor: 1000 + index,
            currencyCode: 'INR',
            status: TransactionStatus.completed,
            createdAt: newest.subtract(Duration(hours: index)),
          ),
        Transaction(
          id: 'other',
          merchantName: 'Other Place',
          amountMinor: 50,
          currencyCode: 'USD',
          status: TransactionStatus.completed,
          createdAt: newest,
        ),
      ],
    );

    final first = await source.fetchTransactions(query: 'alpha');
    expect(first.transactions, hasLength(10));
    expect(
      first.transactions.every((item) => item.merchantName == 'Alpha Shop'),
      isTrue,
    );

    final second = await source.fetchTransactions(
      cursor: first.nextCursor,
      query: 'alpha',
    );
    expect(second.transactions, hasLength(5));
    expect(second.nextCursor, isNull);
    expect(second.transactions.every((item) => item.id != 'other'), isTrue);
  });

  test('rejects a cursor that is not an offset', () async {
    final source = FakeTransactionDataSource(delay: Duration.zero);
    expect(
      source.fetchTransactions(cursor: 'next'),
      throwsA(isA<TransactionFetchException>()),
    );
  });
}

Future<List<Transaction>> _collect(
  FakeTransactionDataSource source, {
  TransactionStatus? status,
  String? query,
}) async {
  final collected = <Transaction>[];
  String? cursor;
  var pages = 0;
  while (pages < 10) {
    final page = await source.fetchTransactions(
      cursor: cursor,
      status: status,
      query: query,
    );
    pages += 1;
    if (page.transactions.isEmpty && page.nextCursor == null) break;
    collected.addAll(page.transactions);
    cursor = page.nextCursor;
    if (cursor == null) break;
  }
  expect(cursor, isNull);
  return collected;
}

Transaction _transaction({required String id, required DateTime createdAt}) {
  return Transaction(
    id: id,
    merchantName: 'Merchant $id',
    amountMinor: 100,
    currencyCode: 'INR',
    status: TransactionStatus.completed,
    createdAt: createdAt,
  );
}
