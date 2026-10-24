import 'package:equatable/equatable.dart';

import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';

final class Transaction extends Equatable {
  Transaction({
    required this.id,
    required this.merchantName,
    required this.amountMinor,
    required this.currencyCode,
    required this.status,
    required this.createdAt,
    this.reference,
  }) : assert(id.isNotEmpty, 'id must not be empty'),
       assert(merchantName.isNotEmpty, 'merchantName must not be empty'),
       assert(currencyCode.length == 3, 'currencyCode must be a 3-letter code'),
       assert(createdAt.isUtc, 'createdAt must be stored in UTC');

  final String id;
  final String merchantName;
  final int amountMinor;
  final String currencyCode;
  final TransactionStatus status;
  final DateTime createdAt;
  final String? reference;

  @override
  List<Object?> get props => [
    id,
    merchantName,
    amountMinor,
    currencyCode,
    status,
    createdAt,
    reference,
  ];
}

int compareTransactions(Transaction a, Transaction b) {
  final byDate = b.createdAt.compareTo(a.createdAt);
  if (byDate != 0) return byDate;
  return b.id.compareTo(a.id);
}
