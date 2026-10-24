import 'package:flutter_test/flutter_test.dart';

import 'package:bepay/features/transactions/data/cache/memory_first_page_cache.dart';
import 'package:bepay/features/transactions/data/datasources/fake_transaction_data_source.dart';
import 'package:bepay/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';
import 'package:bepay/features/transactions/domain/models/cached_first_page.dart';
import 'package:bepay/features/transactions/domain/usecases/fetch_transactions.dart';
import 'package:bepay/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:bepay/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:bepay/features/transactions/presentation/bloc/transaction_state.dart';
import 'pausable_transaction_repository.dart';

void main() {
  test('loads the first page and pages through to the end', () async {
    final bloc = TransactionHistoryBloc(
      fetchTransactions: _fetch(
        FakeTransactionDataSource(delay: Duration.zero),
      ),
    );
    addTearDown(bloc.close);

    bloc.add(const TransactionHistoryStarted());
    await _until(() => bloc.state.status == HistoryLoadStatus.success);

    expect(bloc.state.transactions, hasLength(10));
    expect(bloc.state.nextCursor, isNotNull);
    expect(bloc.state.hasReachedEnd, isFalse);

    var pages = 0;
    while (!bloc.state.hasReachedEnd) {
      final before = bloc.state.transactions.length;
      bloc.add(const TransactionHistoryLoadMoreRequested());
      await _until(
        () =>
            bloc.state.hasReachedEnd || bloc.state.transactions.length > before,
      );
      pages += 1;
      expect(pages, lessThan(8));
    }

    expect(bloc.state.transactions, hasLength(36));
    expect(bloc.state.nextCursor, isNull);
    expect(
      bloc.state.transactions.map((item) => item.id).toSet(),
      hasLength(36),
    );
    for (var index = 0; index < bloc.state.transactions.length - 1; index++) {
      expect(
        compareTransactions(
          bloc.state.transactions[index],
          bloc.state.transactions[index + 1],
        ),
        lessThanOrEqualTo(0),
      );
    }
  });

  test(
    'keeps loaded rows when the next page fails, then retry appends once',
    () async {
      final bloc = TransactionHistoryBloc(
        fetchTransactions: _fetch(
          FakeTransactionDataSource(delay: Duration.zero, failOnCalls: {2}),
        ),
      );
      addTearDown(bloc.close);

      bloc.add(const TransactionHistoryStarted());
      await _until(() => bloc.state.status == HistoryLoadStatus.success);
      final firstIds = _ids(bloc);
      expect(firstIds, hasLength(10));

      bloc.add(const TransactionHistoryLoadMoreRequested());
      await _until(() => bloc.state.failureKind == HistoryFailureKind.nextPage);

      expect(_ids(bloc), firstIds);
      expect(bloc.state.isLoadingMore, isFalse);
      expect(bloc.state.nextCursor, isNotNull);

      bloc.add(const TransactionHistoryRetryRequested());
      await _until(() => bloc.state.transactions.length > firstIds.length);

      expect(bloc.state.failureKind, HistoryFailureKind.none);
      expect(bloc.state.transactions, hasLength(20));
      expect(_ids(bloc).take(10).toList(), firstIds);
      expect(_ids(bloc).toSet(), hasLength(20));
    },
  );

  test(
    'ignores an older response when the filter changes mid-request',
    () async {
      final source = PausableTransactionRepository(
        TransactionRepositoryImpl(
          FakeTransactionDataSource(delay: Duration.zero),
        ),
      );
      final bloc = TransactionHistoryBloc(
        fetchTransactions: FetchTransactions(source),
      );
      addTearDown(() async {
        source.releaseAll();
        await pumpEventQueue();
        await bloc.close();
      });

      bloc.add(const TransactionHistoryStarted());
      await _until(() => source.calls == 1);

      bloc.add(const TransactionFilterChanged(TransactionStatus.pending));
      await _until(() => source.calls == 2);

      source.release(1);
      await _until(
        () =>
            bloc.state.status == HistoryLoadStatus.success &&
            bloc.state.activeFilter == TransactionStatus.pending,
      );
      final pendingIds = _ids(bloc);
      expect(bloc.state.transactions, isNotEmpty);
      expect(
        bloc.state.transactions.map((item) => item.status),
        everyElement(TransactionStatus.pending),
      );

      source.release(0);
      await pumpEventQueue();

      expect(_ids(bloc), pendingIds);
      expect(bloc.state.activeFilter, TransactionStatus.pending);
    },
  );

  test(
    'refresh replaces the list and a stale next page does not append',
    () async {
      final source = PausableTransactionRepository(
        TransactionRepositoryImpl(
          FakeTransactionDataSource(delay: Duration.zero),
        ),
      );
      final bloc = TransactionHistoryBloc(
        fetchTransactions: FetchTransactions(source),
      );
      addTearDown(() async {
        source.releaseAll();
        await pumpEventQueue();
        await bloc.close();
      });

      bloc.add(const TransactionHistoryStarted());
      await _until(() => source.calls == 1);
      source.release(0);
      await _until(() => bloc.state.transactions.length == 10);
      final firstIds = _ids(bloc);

      bloc.add(const TransactionHistoryLoadMoreRequested());
      await _until(() => source.calls == 2);
      bloc.add(const TransactionHistoryRefreshed());
      await _until(() => source.calls == 3);

      source.release(1);
      await pumpEventQueue();
      expect(_ids(bloc), firstIds);
      expect(bloc.state.isRefreshing, isTrue);

      source.release(2);
      await _until(() => !bloc.state.isRefreshing);
      expect(_ids(bloc), firstIds);
      expect(bloc.state.transactions, hasLength(10));
      expect(bloc.state.failureKind, HistoryFailureKind.none);
    },
  );

  test('drops duplicate next-page requests while one is in flight', () async {
    final source = PausableTransactionRepository(
      TransactionRepositoryImpl(
        FakeTransactionDataSource(delay: Duration.zero),
      ),
    );
    final bloc = TransactionHistoryBloc(
      fetchTransactions: FetchTransactions(source),
    );
    addTearDown(() async {
      source.releaseAll();
      await pumpEventQueue();
      await bloc.close();
    });

    bloc.add(const TransactionHistoryStarted());
    await _until(() => source.calls == 1);
    source.release(0);
    await _until(() => bloc.state.transactions.length == 10);

    bloc.add(const TransactionHistoryLoadMoreRequested());
    bloc.add(const TransactionHistoryLoadMoreRequested());
    bloc.add(const TransactionHistoryLoadMoreRequested());
    await pumpEventQueue();

    expect(source.calls, 2);

    source.release(1);
    await _until(() => bloc.state.transactions.length == 20);
    expect(source.calls, 2);
    expect(_ids(bloc).toSet(), hasLength(20));
  });

  test('refresh failure keeps the rows already shown', () async {
    final bloc = TransactionHistoryBloc(
      fetchTransactions: _fetch(
        FakeTransactionDataSource(delay: Duration.zero, failOnCalls: {2}),
      ),
    );
    addTearDown(bloc.close);

    bloc.add(const TransactionHistoryStarted());
    await _until(() => bloc.state.status == HistoryLoadStatus.success);
    final firstIds = _ids(bloc);

    bloc.add(const TransactionHistoryRefreshed());
    await _until(() => bloc.state.failureKind == HistoryFailureKind.refresh);

    expect(_ids(bloc), firstIds);
    expect(bloc.state.status, HistoryLoadStatus.success);
    expect(bloc.state.isRefreshing, isFalse);

    bloc.add(const TransactionHistoryRetryRequested());
    await _until(
      () =>
          bloc.state.failureKind == HistoryFailureKind.none &&
          !bloc.state.isRefreshing,
    );
    expect(bloc.state.transactions, hasLength(10));
  });

  test('reports an empty first page without treating it as an error', () async {
    final bloc = TransactionHistoryBloc(
      fetchTransactions: _fetch(
        FakeTransactionDataSource(delay: Duration.zero, transactions: const []),
      ),
    );
    addTearDown(bloc.close);

    bloc.add(const TransactionHistoryStarted());
    await _until(() => bloc.state.status == HistoryLoadStatus.success);

    expect(bloc.state.isEmpty, isTrue);
    expect(bloc.state.hasReachedEnd, isTrue);
    expect(bloc.state.failureKind, HistoryFailureKind.none);
  });

  test('search keeps the filter and replaces the list with matches', () async {
    final bloc = TransactionHistoryBloc(
      fetchTransactions: _fetch(
        FakeTransactionDataSource(delay: Duration.zero),
      ),
    );
    addTearDown(bloc.close);

    bloc.add(const TransactionHistoryStarted());
    await _until(() => bloc.state.status == HistoryLoadStatus.success);

    bloc.add(const TransactionFilterChanged(TransactionStatus.completed));
    await _until(
      () =>
          bloc.state.activeFilter == TransactionStatus.completed &&
          bloc.state.transactions.isNotEmpty &&
          bloc.state.transactions.every(
            (item) => item.status == TransactionStatus.completed,
          ),
    );

    bloc.add(const TransactionSearchChanged('  indigo '));
    await _until(
      () =>
          bloc.state.query == 'indigo' &&
          bloc.state.transactions.isNotEmpty &&
          bloc.state.transactions.every(
            (item) => item.merchantName == 'Indigo Cafe',
          ),
    );

    expect(bloc.state.activeFilter, TransactionStatus.completed);
    expect(bloc.state.transactions, hasLength(lessThanOrEqualTo(10)));
    expect(
      bloc.state.transactions.every(
        (item) => item.status == TransactionStatus.completed,
      ),
      isTrue,
    );
  });

  test('shows the saved first page until the fresh page arrives', () async {
    final cache = MemoryFirstPageCache();
    await cache.save(
      CachedFirstPage(
        transactions: [
          Transaction(
            id: 'cached',
            merchantName: 'Cached Shop',
            amountMinor: 100,
            currencyCode: 'INR',
            status: TransactionStatus.completed,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        query: '',
        nextCursor: '10',
      ),
    );
    final gateway = PausableTransactionRepository(
      TransactionRepositoryImpl(
        FakeTransactionDataSource(delay: Duration.zero),
      ),
    );
    final bloc = TransactionHistoryBloc(
      fetchTransactions: FetchTransactions(gateway),
      firstPageCache: cache,
    );
    addTearDown(bloc.close);

    bloc.add(const TransactionHistoryStarted());
    await _until(
      () => bloc.state.transactions.any((item) => item.id == 'cached'),
    );

    expect(bloc.state.isRefreshing, isTrue);
    expect(bloc.state.query, isEmpty);
    expect(gateway.calls, 1);

    gateway.release(0);
    await _until(
      () =>
          !bloc.state.isRefreshing &&
          bloc.state.transactions.first.merchantName == 'Indigo Cafe',
    );

    expect(bloc.state.transactions.any((item) => item.id == 'cached'), isFalse);
    final saved = await cache.read();
    expect(saved, isNotNull);
    expect(saved!.transactions, hasLength(10));
    expect(saved.transactions.first.merchantName, 'Indigo Cafe');
    expect(saved.query, isEmpty);
  });
}

FetchTransactions _fetch(FakeTransactionDataSource source) {
  return FetchTransactions(TransactionRepositoryImpl(source));
}

List<String> _ids(TransactionHistoryBloc bloc) {
  return bloc.state.transactions.map((item) => item.id).toList();
}

Future<void> _until(bool Function() condition) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (condition()) return;
    await pumpEventQueue();
  }
  expect(condition(), isTrue);
}
