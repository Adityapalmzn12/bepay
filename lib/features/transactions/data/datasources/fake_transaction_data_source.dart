import 'package:bepay/core/constants/app_constants.dart';
import 'package:bepay/core/errors/app_exception.dart';
import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';
import 'package:bepay/features/transactions/domain/models/transaction_page.dart';

final class FakeTransactionDataSource {
  FakeTransactionDataSource({
    this.delay = const Duration(milliseconds: 600),
    List<Transaction>? transactions,
    Set<int> failOnCalls = const {},
    this.failAllRequests = false,
  }) : _transactions = _sorted(transactions ?? buildSampleTransactions()),
       _failOnCalls = Set<int>.unmodifiable(failOnCalls);

  static const int pageSize = 10;

  final Duration delay;
  final bool failAllRequests;

  final List<Transaction> _transactions;
  final Set<int> _failOnCalls;
  int _callCount = 0;
  bool _failNextRequest = false;

  void armFailNextRequest() {
    _failNextRequest = true;
  }

  Future<TransactionPage> fetchTransactions({
    String? cursor,
    TransactionStatus? status,
    String? query,
  }) async {
    final callNumber = ++_callCount;
    final armed = _failNextRequest;
    if (armed) _failNextRequest = false;
    final shouldFail =
        failAllRequests || armed || _failOnCalls.contains(callNumber);

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldFail) {
      throw const TransactionFetchException();
    }
    return _page(cursor: cursor, status: status, query: query);
  }

  TransactionPage _page({
    required String? cursor,
    required TransactionStatus? status,
    required String? query,
  }) {
    final needle = query?.trim().toLowerCase() ?? '';
    final filtered = _transactions
        .where((transaction) {
          final statusMatches = status == null || transaction.status == status;
          if (!statusMatches) return false;
          if (needle.isEmpty) return true;
          final merchant = transaction.merchantName.toLowerCase();
          final reference = transaction.reference?.toLowerCase() ?? '';
          return merchant.contains(needle) || reference.contains(needle);
        })
        .toList(growable: false);
    final start = _offset(cursor);
    if (start >= filtered.length) {
      return const TransactionPage();
    }
    final end = start + pageSize < filtered.length
        ? start + pageSize
        : filtered.length;
    return TransactionPage(
      transactions: List<Transaction>.unmodifiable(
        filtered.sublist(start, end),
      ),
      nextCursor: end < filtered.length ? '$end' : null,
    );
  }

  int _offset(String? cursor) {
    if (cursor == null) return 0;
    final offset = int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw const TransactionFetchException(AppStrings.invalidPageCursor);
    }
    return offset;
  }

  static List<Transaction> _sorted(List<Transaction> transactions) {
    final copy = [...transactions]..sort(compareTransactions);
    return List<Transaction>.unmodifiable(copy);
  }
}

List<Transaction> buildSampleTransactions() {
  final newest = DateTime.utc(2026, 10, 22, 18, 30);
  return List<Transaction>.unmodifiable(
    List<Transaction>.generate(36, (index) {
      final currencyCode = index.isEven
          ? AppStrings.inrCode
          : AppStrings.usdCode;
      return Transaction(
        id: 'txn_${(index + 1).toString().padLeft(3, '0')}',
        merchantName: _merchants[index % _merchants.length],
        amountMinor: switch (index) {
          0 => 129900,
          1 => 2599,
          _ => 50000 + (index * 1375),
        },
        currencyCode: currencyCode,
        status:
            TransactionStatus.values[index % TransactionStatus.values.length],
        createdAt: newest.subtract(Duration(hours: index)),
        reference: index.isEven ? 'REF-${1000 + index}' : null,
      );
    }),
  );
}

const _merchants = <String>[
  'Indigo Cafe',
  'Metro Grocery',
  'City Transit',
  'Northwind Books',
  'Apex Electronics',
  'Harbor Pharmacy',
  'Lotus Hotels',
  'Brightline Fuel',
  'Pixel Studio',
  'Green Basket',
  'Orbit Airlines',
  'Daily Mart',
];
