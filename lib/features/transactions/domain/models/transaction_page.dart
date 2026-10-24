import 'package:equatable/equatable.dart';

import 'package:bepay/features/transactions/domain/entities/transaction.dart';

final class TransactionPage extends Equatable {
  const TransactionPage({this.transactions = const [], this.nextCursor});

  final List<Transaction> transactions;
  final String? nextCursor;

  @override
  List<Object?> get props => [transactions, nextCursor];
}
