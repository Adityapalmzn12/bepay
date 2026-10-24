import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bepay/features/transactions/data/cache/shared_preferences_first_page_cache.dart';
import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';
import 'package:bepay/features/transactions/domain/models/cached_first_page.dart';

void main() {
  test('stores and restores the last successful first page', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cache = SharedPreferencesFirstPageCache(preferences);
    final page = CachedFirstPage(
      query: 'cafe',
      status: TransactionStatus.completed,
      nextCursor: '10',
      transactions: [
        Transaction(
          id: 'txn_001',
          merchantName: 'Indigo Cafe',
          amountMinor: 129900,
          currencyCode: 'INR',
          status: TransactionStatus.completed,
          createdAt: DateTime.utc(2026, 10, 22, 18, 30),
          reference: 'REF-1000',
        ),
      ],
    );

    await cache.save(page);

    final restored = await SharedPreferencesFirstPageCache(preferences).read();
    expect(restored, page);
    expect(restored!.transactions.single.createdAt.isUtc, isTrue);
  });

  test('ignores a stored value that is not a page', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesFirstPageCache.storageKey: '{',
    });
    final preferences = await SharedPreferences.getInstance();
    final cache = SharedPreferencesFirstPageCache(preferences);

    expect(await cache.read(), isNull);
  });
}
