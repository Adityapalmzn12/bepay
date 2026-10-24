import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bepay/app.dart';
import 'package:bepay/features/transactions/data/cache/memory_first_page_cache.dart';
import 'package:bepay/features/transactions/data/datasources/fake_transaction_data_source.dart';
import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';
import 'package:bepay/features/transactions/domain/models/cached_first_page.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_list_item.dart';

void main() {
  testWidgets('shows formatted INR and USD amounts and applies a filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      BePayApp(dataSource: FakeTransactionDataSource(delay: Duration.zero)),
    );
    await _pumpUntilFound(tester, find.text('₹1,299.00'));
    await _settlePages(tester);

    expect(find.text('₹1,299.00'), findsOneWidget);
    expect(find.text(r'$25.99'), findsOneWidget);
    expect(_chip(tester, 'filter-all').selected, isTrue);

    await tester.tap(find.byKey(const Key('filter-pending')));
    await _pumpUntil(tester, () {
      final pendingSelected = _chip(tester, 'filter-pending').selected;
      final inrGone = find.text('₹1,299.00').evaluate().isEmpty;
      return pendingSelected && inrGone;
    });
    await _settlePages(tester);

    expect(_chip(tester, 'filter-pending').selected, isTrue);
    expect(find.text('₹1,299.00'), findsNothing);
    expect(find.text(r'$25.99'), findsOneWidget);
    final tiles = tester.widgetList<TransactionListItem>(
      find.byType(TransactionListItem),
    );
    expect(tiles, isNotEmpty);
    expect(
      tiles.every(
        (tile) => tile.transaction.status == TransactionStatus.pending,
      ),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('filter-all')));
    await _pumpUntilFound(tester, find.text('₹1,299.00'));
    await _settlePages(tester);
    expect(_chip(tester, 'filter-all').selected, isTrue);
  });

  testWidgets(
    'retries a failed first page without leaving the error on screen',
    (tester) async {
      await tester.pumpWidget(
        BePayApp(
          dataSource: FakeTransactionDataSource(
            delay: Duration.zero,
            failOnCalls: {1},
          ),
        ),
      );
      await _pumpUntilFound(tester, find.text("Couldn't load transactions"));

      await tester.tap(find.byKey(const Key('retry-initial')));
      await _pumpUntilFound(tester, find.text('₹1,299.00'));
      await _settlePages(tester);

      expect(find.text("Couldn't load transactions"), findsNothing);
      expect(find.text(r'$25.99'), findsOneWidget);
    },
  );

  testWidgets('stays usable on a narrow phone with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      BePayApp(dataSource: FakeTransactionDataSource(delay: Duration.zero)),
    );
    await _pumpUntilFound(tester, find.text('Indigo Cafe'));
    await _settlePages(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.byType(TransactionListItem), findsWidgets);
  });

  testWidgets('searches within the selected filter', (tester) async {
    await tester.pumpWidget(
      BePayApp(dataSource: FakeTransactionDataSource(delay: Duration.zero)),
    );
    await _pumpUntilFound(tester, find.text('Indigo Cafe'));
    await _settlePages(tester);

    await tester.tap(find.byKey(const Key('filter-completed')));
    await _pumpUntil(tester, () => _chip(tester, 'filter-completed').selected);
    await _settlePages(tester);

    await tester.enterText(
      find.byKey(const Key('transaction-search')),
      'indigo',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _pumpUntil(tester, () {
      final tiles = tester.widgetList<TransactionListItem>(
        find.byType(TransactionListItem),
      );
      return tiles.isNotEmpty &&
          tiles.every(
            (tile) =>
                tile.transaction.merchantName == 'Indigo Cafe' &&
                tile.transaction.status == TransactionStatus.completed,
          ) &&
          find.text('Northwind Books').evaluate().isEmpty;
    });

    expect(find.text('Northwind Books'), findsNothing);
  });

  testWidgets('opens the tapped transaction and returns to the list', (
    tester,
  ) async {
    await tester.pumpWidget(
      BePayApp(dataSource: FakeTransactionDataSource(delay: Duration.zero)),
    );
    await _pumpUntilFound(tester, find.text('Indigo Cafe'));
    await _settlePages(tester);

    await tester.tap(find.text('Indigo Cafe').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Transaction'), findsOneWidget);
    expect(find.text('txn_001'), findsOneWidget);
    expect(find.text('REF-1000'), findsOneWidget);
    expect(find.text('₹1,299.00'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Transaction history'), findsOneWidget);
    expect(find.text('txn_001'), findsNothing);
  });

  testWidgets('shows the saved page while a fresh page is loading', (
    tester,
  ) async {
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
            reference: 'REF-CACHE',
          ),
        ],
        query: '',
      ),
    );

    await tester.pumpWidget(
      BePayApp(
        dataSource: FakeTransactionDataSource(
          delay: const Duration(milliseconds: 300),
        ),
        firstPageCache: cache,
      ),
    );
    await _pumpUntilFound(tester, find.text('Cached Shop'));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await _pumpUntilFound(tester, find.text('Indigo Cafe'));
    expect(find.text('Cached Shop'), findsNothing);
  });
}

ChoiceChip _chip(WidgetTester tester, String key) {
  return tester.widget<ChoiceChip>(find.byKey(Key(key)));
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 40));
  }
  expect(condition(), isTrue);
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 40));
  }
  expect(finder, findsWidgets);
}

Future<void> _settlePages(WidgetTester tester) async {
  for (var attempt = 0; attempt < 6; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
