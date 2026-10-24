import 'package:equatable/equatable.dart';

import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';

sealed class TransactionHistoryEvent extends Equatable {
  const TransactionHistoryEvent();

  @override
  bool? get stringify => true;
}

final class TransactionHistoryStarted extends TransactionHistoryEvent {
  const TransactionHistoryStarted();

  @override
  List<Object?> get props => const [];
}

final class TransactionFilterChanged extends TransactionHistoryEvent {
  const TransactionFilterChanged(this.status);

  final TransactionStatus? status;

  @override
  List<Object?> get props => [status];
}

final class TransactionSearchChanged extends TransactionHistoryEvent {
  const TransactionSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class TransactionHistoryLoadMoreRequested
    extends TransactionHistoryEvent {
  const TransactionHistoryLoadMoreRequested();

  @override
  List<Object?> get props => const [];
}

final class TransactionHistoryRefreshed extends TransactionHistoryEvent {
  const TransactionHistoryRefreshed();

  @override
  List<Object?> get props => const [];
}

final class TransactionHistoryRetryRequested extends TransactionHistoryEvent {
  const TransactionHistoryRetryRequested();

  @override
  List<Object?> get props => const [];
}
