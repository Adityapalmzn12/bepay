import 'package:flutter/material.dart';

import 'package:bepay/core/constants/app_constants.dart';
import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_error_view.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_loading_view.dart';

class TransactionListView extends StatelessWidget {
  const TransactionListView({
    required this.transactions,
    required this.isLoadingMore,
    required this.showLoadMoreError,
    required this.showEndOfList,
    required this.onRetry,
    required this.onTransactionTap,
    super.key,
  });

  final List<Transaction> transactions;
  final bool isLoadingMore;
  final bool showLoadMoreError;
  final bool showEndOfList;
  final VoidCallback onRetry;
  final ValueChanged<Transaction> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverList.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return TransactionListItem(
              key: ValueKey(transaction.id),
              transaction: transaction,
              onTap: () => onTransactionTap(transaction),
            );
          },
        ),
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: TransactionLoadingMore(label: AppStrings.loadingMore),
          ),
        if (showLoadMoreError)
          SliverToBoxAdapter(
            child: TransactionFooterMessage(
              message: AppStrings.loadMoreError,
              actionLabel: AppStrings.tryAgain,
              actionKey: const Key('retry-next-page'),
              onAction: onRetry,
            ),
          ),
        if (showEndOfList)
          const SliverToBoxAdapter(
            child: TransactionFooterMessage(message: AppStrings.endOfList),
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
        ),
      ],
    );
  }
}
