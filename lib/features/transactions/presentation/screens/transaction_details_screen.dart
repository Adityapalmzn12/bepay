import 'package:flutter/material.dart';

import 'package:bepay/core/constants/app_constants.dart';
import 'package:bepay/core/utils/currency_formatter.dart';
import 'package:bepay/core/utils/date_formatter.dart';
import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_list_item.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({required this.transaction, super.key});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = formatMoney(
      amountMinor: transaction.amountMinor,
      currencyCode: transaction.currencyCode,
    );
    final status = transaction.status;
    final (foreground, background) = switch (status) {
      TransactionStatus.completed => (
        AppColors.completedForeground,
        AppColors.completedBackground,
      ),
      TransactionStatus.pending => (
        AppColors.pendingForeground,
        AppColors.pendingBackground,
      ),
      TransactionStatus.failed => (
        AppColors.failedForeground,
        AppColors.failedBackground,
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.transactionDetailsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            transaction.merchantName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            semanticsLabel: moneySemanticsLabel(
              amountMinor: transaction.amountMinor,
              currencyCode: transaction.currencyCode,
            ),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Icon(status.icon, size: 18, color: foreground),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _DetailRow(
            label: AppStrings.dateLabel,
            value: formatTransactionDate(transaction.createdAt),
          ),
          _DetailRow(
            label: AppStrings.referenceTitle,
            value: transaction.reference ?? AppStrings.noReference,
          ),
          _DetailRow(
            label: AppStrings.transactionIdLabel,
            value: transaction.id,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
