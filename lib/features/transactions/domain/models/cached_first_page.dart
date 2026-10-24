import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';

final class CachedFirstPage extends Equatable {
  const CachedFirstPage({
    required this.transactions,
    required this.query,
    this.status,
    this.nextCursor,
  });

  final List<Transaction> transactions;
  final String query;
  final TransactionStatus? status;
  final String? nextCursor;

  String encode() => jsonEncode(toJson());

  static CachedFirstPage? decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return CachedFirstPage.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Map<String, Object?> toJson() {
    return {
      'query': query,
      'status': status?.name,
      'nextCursor': nextCursor,
      'transactions': transactions.map(_transactionToJson).toList(),
    };
  }

  factory CachedFirstPage.fromJson(Map<String, dynamic> json) {
    final rows = json['transactions'];
    if (rows is! List) {
      throw const FormatException('Cached page is missing transactions.');
    }
    final statusName = json['status'];
    return CachedFirstPage(
      query: json['query'] as String? ?? '',
      status: statusName is String
          ? TransactionStatus.values.byName(statusName)
          : null,
      nextCursor: json['nextCursor'] as String?,
      transactions: [
        for (final row in rows)
          if (row is Map) _transactionFromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }

  @override
  List<Object?> get props => [transactions, query, status, nextCursor];
}

Map<String, Object?> _transactionToJson(Transaction transaction) {
  return {
    'id': transaction.id,
    'merchantName': transaction.merchantName,
    'amountMinor': transaction.amountMinor,
    'currencyCode': transaction.currencyCode,
    'status': transaction.status.name,
    'createdAt': transaction.createdAt.toIso8601String(),
    'reference': transaction.reference,
  };
}

Transaction _transactionFromJson(Map<String, dynamic> json) {
  final createdAt = DateTime.parse(json['createdAt'] as String).toUtc();
  return Transaction(
    id: json['id'] as String,
    merchantName: json['merchantName'] as String,
    amountMinor: json['amountMinor'] as int,
    currencyCode: json['currencyCode'] as String,
    status: TransactionStatus.values.byName(json['status'] as String),
    createdAt: createdAt,
    reference: json['reference'] as String?,
  );
}
