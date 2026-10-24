import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/domain/models/cached_first_page.dart';
import 'package:bepay/features/transactions/domain/repositories/first_page_cache.dart';
import 'package:bepay/features/transactions/domain/usecases/fetch_transactions.dart';
import 'package:bepay/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:bepay/features/transactions/presentation/bloc/transaction_state.dart';

final class TransactionHistoryBloc
    extends Bloc<TransactionHistoryEvent, TransactionHistoryState> {
  TransactionHistoryBloc({
    required FetchTransactions fetchTransactions,
    FirstPageCache? firstPageCache,
  }) : _fetchTransactions = fetchTransactions,
       _firstPageCache = firstPageCache ?? const _NoFirstPageCache(),
       super(const TransactionHistoryState()) {
    on<TransactionHistoryStarted>(_onStarted, transformer: concurrent());
    on<TransactionFilterChanged>(_onFilterChanged, transformer: concurrent());
    on<TransactionSearchChanged>(_onSearchChanged, transformer: concurrent());
    on<TransactionHistoryRefreshed>(_onRefreshed, transformer: concurrent());
    on<TransactionHistoryRetryRequested>(_onRetry, transformer: concurrent());
    on<TransactionHistoryLoadMoreRequested>(
      _onLoadMore,
      transformer: droppable(),
    );
  }

  final FetchTransactions _fetchTransactions;
  final FirstPageCache _firstPageCache;
  int _requestGeneration = 0;
  int _cacheWriteToken = 0;
  CachedFirstPage? _latestPage;
  bool _loadMoreInFlight = false;

  Future<void> _onStarted(
    TransactionHistoryStarted event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    if (state.status != HistoryLoadStatus.initial) return;

    final cached = await _readCache();
    if (isClosed) return;
    if (cached != null) {
      emit(
        state.copyWith(
          status: HistoryLoadStatus.success,
          transactions: List<Transaction>.unmodifiable(cached.transactions),
          activeFilter: cached.status,
          query: cached.query,
          nextCursor: cached.nextCursor,
          hasReachedEnd: cached.nextCursor == null,
          isRefreshing: true,
          failureKind: HistoryFailureKind.none,
        ),
      );
    }
    await _fetchFirstPage(emit, refresh: cached != null);
  }

  Future<void> _onFilterChanged(
    TransactionFilterChanged event,
    Emitter<TransactionHistoryState> emit,
  ) {
    final isSameFilter = event.status == state.activeFilter;
    if (isSameFilter && state.status != HistoryLoadStatus.failure) {
      return Future<void>.value();
    }
    emit(state.copyWith(activeFilter: event.status));
    return _fetchFirstPage(emit, refresh: false);
  }

  Future<void> _onSearchChanged(
    TransactionSearchChanged event,
    Emitter<TransactionHistoryState> emit,
  ) {
    final query = event.query.trim();
    if (query == state.query && state.status != HistoryLoadStatus.failure) {
      return Future<void>.value();
    }
    emit(state.copyWith(query: query));
    return _fetchFirstPage(emit, refresh: false);
  }

  Future<void> _onRefreshed(
    TransactionHistoryRefreshed event,
    Emitter<TransactionHistoryState> emit,
  ) {
    return _fetchFirstPage(emit, refresh: true);
  }

  Future<void> _onRetry(
    TransactionHistoryRetryRequested event,
    Emitter<TransactionHistoryState> emit,
  ) {
    if (state.failureKind == HistoryFailureKind.nextPage) {
      return _loadNextPage(emit);
    }
    final keepVisibleRows = state.transactions.isNotEmpty;
    return _fetchFirstPage(emit, refresh: keepVisibleRows);
  }

  Future<void> _onLoadMore(
    TransactionHistoryLoadMoreRequested event,
    Emitter<TransactionHistoryState> emit,
  ) {
    if (state.failureKind == HistoryFailureKind.nextPage) {
      return Future<void>.value();
    }
    return _loadNextPage(emit);
  }

  Future<void> _fetchFirstPage(
    Emitter<TransactionHistoryState> emit, {
    required bool refresh,
  }) async {
    final generation = ++_requestGeneration;
    _loadMoreInFlight = false;
    final filter = state.activeFilter;
    final query = state.query;

    if (refresh) {
      emit(
        state.copyWith(
          isRefreshing: true,
          isLoadingMore: false,
          failureKind: HistoryFailureKind.none,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: HistoryLoadStatus.loading,
          transactions: const [],
          nextCursor: null,
          hasReachedEnd: false,
          isLoadingMore: false,
          isRefreshing: false,
          failureKind: HistoryFailureKind.none,
        ),
      );
    }

    try {
      final page = await _fetchTransactions(status: filter, query: query);
      if (!_isCurrent(generation, emit)) return;
      final transactions = List<Transaction>.unmodifiable(page.transactions);
      await _saveFirstPage(
        CachedFirstPage(
          transactions: transactions,
          query: query,
          status: filter,
          nextCursor: page.nextCursor,
        ),
      );
      if (!_isCurrent(generation, emit)) return;
      emit(
        state.copyWith(
          status: HistoryLoadStatus.success,
          transactions: transactions,
          activeFilter: filter,
          query: query,
          nextCursor: page.nextCursor,
          hasReachedEnd: page.nextCursor == null,
          isRefreshing: false,
          isLoadingMore: false,
          failureKind: HistoryFailureKind.none,
        ),
      );
    } on Exception {
      if (!_isCurrent(generation, emit)) return;
      final preserveRows = refresh && state.transactions.isNotEmpty;
      emit(
        state.copyWith(
          status: preserveRows
              ? HistoryLoadStatus.success
              : HistoryLoadStatus.failure,
          isRefreshing: false,
          isLoadingMore: false,
          failureKind: preserveRows
              ? HistoryFailureKind.refresh
              : HistoryFailureKind.initial,
        ),
      );
    }
  }

  Future<void> _loadNextPage(Emitter<TransactionHistoryState> emit) async {
    if (_loadMoreInFlight || !_hasMore(state)) return;

    final cursor = state.nextCursor;
    if (cursor == null) return;

    _loadMoreInFlight = true;
    final generation = ++_requestGeneration;
    final filter = state.activeFilter;
    final query = state.query;
    emit(
      state.copyWith(isLoadingMore: true, failureKind: HistoryFailureKind.none),
    );

    try {
      final page = await _fetchTransactions(
        cursor: cursor,
        status: filter,
        query: query,
      );
      if (!_isCurrent(generation, emit)) return;
      emit(
        state.copyWith(
          status: HistoryLoadStatus.success,
          transactions: _merge(state.transactions, page.transactions),
          nextCursor: page.nextCursor,
          hasReachedEnd: page.nextCursor == null,
          isLoadingMore: false,
          failureKind: HistoryFailureKind.none,
        ),
      );
    } on Exception {
      if (!_isCurrent(generation, emit)) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          failureKind: HistoryFailureKind.nextPage,
        ),
      );
    } finally {
      _loadMoreInFlight = false;
    }
  }

  Future<CachedFirstPage?> _readCache() async {
    try {
      return await _firstPageCache.read();
    } on Exception {
      return null;
    }
  }

  Future<void> _saveFirstPage(CachedFirstPage page) async {
    final token = ++_cacheWriteToken;
    _latestPage = page;
    try {
      await _firstPageCache.save(page);
      if (token != _cacheWriteToken && _latestPage != null) {
        await _firstPageCache.save(_latestPage!);
      }
    } on Exception {
      return;
    }
  }

  bool _hasMore(TransactionHistoryState state) {
    return state.status == HistoryLoadStatus.success &&
        state.nextCursor != null &&
        !state.hasReachedEnd &&
        !state.isRefreshing &&
        !state.isLoadingMore;
  }

  bool _isCurrent(int generation, Emitter<TransactionHistoryState> emit) {
    return !emit.isDone && !isClosed && generation == _requestGeneration;
  }

  List<Transaction> _merge(
    List<Transaction> current,
    List<Transaction> incoming,
  ) {
    final seen = <String>{for (final transaction in current) transaction.id};
    final merged = [...current];
    for (final transaction in incoming) {
      if (seen.add(transaction.id)) merged.add(transaction);
    }
    return List<Transaction>.unmodifiable(merged);
  }
}

final class _NoFirstPageCache implements FirstPageCache {
  const _NoFirstPageCache();

  @override
  Future<CachedFirstPage?> read() async => null;

  @override
  Future<void> save(CachedFirstPage page) async {}
}
