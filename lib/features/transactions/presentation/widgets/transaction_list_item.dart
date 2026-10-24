import 'package:flutter/material.dart';

import 'package:bepay/core/constants/app_constants.dart';
import 'package:bepay/core/utils/currency_formatter.dart';
import 'package:bepay/core/utils/date_formatter.dart';
import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';

extension TransactionStatusStyle on TransactionStatus {
  String get label => switch (this) {
    TransactionStatus.completed => AppStrings.statusCompleted,
    TransactionStatus.pending => AppStrings.statusPending,
    TransactionStatus.failed => AppStrings.statusFailed,
  };

  IconData get icon => switch (this) {
    TransactionStatus.completed => Icons.check_circle_outline,
    TransactionStatus.pending => Icons.schedule,
    TransactionStatus.failed => Icons.error_outline,
  };
}

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({required this.transaction, this.onTap, super.key});

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  transaction.merchantName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatTransactionDate(transaction.createdAt),
                  style: muted,
                ),
                if (transaction.reference != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.referenceLabel(transaction.reference!),
                    style: muted,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      amount,
                      semanticsLabel: moneySemanticsLabel(
                        amountMinor: transaction.amountMinor,
                        currencyCode: transaction.currencyCode,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                status.icon,
                                size: 16,
                                color: foreground,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
