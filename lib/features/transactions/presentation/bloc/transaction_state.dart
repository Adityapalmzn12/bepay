import 'package:equatable/equatable.dart';

import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';

enum HistoryLoadStatus { initial, loading, success, failure }

enum HistoryFailureKind { none, initial, refresh, nextPage }

final class _Keep {
  const _Keep();
}

const _keep = _Keep();

final class TransactionHistoryState extends Equatable {
  const TransactionHistoryState({
    this.status = HistoryLoadStatus.initial,
    this.transactions = const [],
    this.activeFilter,
    this.query = '',
    this.nextCursor,
    this.hasReachedEnd = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.failureKind = HistoryFailureKind.none,
  });

  final HistoryLoadStatus status;
  final List<Transaction> transactions;
  final TransactionStatus? activeFilter;
  final String query;
  final String? nextCursor;
  final bool hasReachedEnd;
  final bool isLoadingMore;
  final bool isRefreshing;
  final HistoryFailureKind failureKind;

  bool get isInitialLoading =>
      transactions.isEmpty &&
      !isRefreshing &&
      (status == HistoryLoadStatus.initial ||
          status == HistoryLoadStatus.loading);

  bool get isInitialFailure =>
      status == HistoryLoadStatus.failure && transactions.isEmpty;

  bool get isEmpty =>
      status == HistoryLoadStatus.success &&
      transactions.isEmpty &&
      !isRefreshing;

  TransactionHistoryState copyWith({
    HistoryLoadStatus? status,
    List<Transaction>? transactions,
    Object? activeFilter = _keep,
    String? query,
    Object? nextCursor = _keep,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    bool? isRefreshing,
    HistoryFailureKind? failureKind,
  }) {
    return TransactionHistoryState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      activeFilter: identical(activeFilter, _keep)
          ? this.activeFilter
          : activeFilter as TransactionStatus?,
      query: query ?? this.query,
      nextCursor: identical(nextCursor, _keep)
          ? this.nextCursor
          : nextCursor as String?,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      failureKind: failureKind ?? this.failureKind,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    activeFilter,
    query,
    nextCursor,
    hasReachedEnd,
    isLoadingMore,
    isRefreshing,
    failureKind,
  ];

  @override
  bool? get stringify => true;
}
