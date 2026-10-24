import 'package:flutter/material.dart';

import 'package:bepay/core/constants/app_constants.dart';
import 'package:bepay/features/transactions/domain/enums/transaction_status.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_list_item.dart';

class TransactionFilterBar extends StatelessWidget {
  const TransactionFilterBar({
    required this.activeFilter,
    required this.onChanged,
    super.key,
  });

  final TransactionStatus? activeFilter;
  final ValueChanged<TransactionStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <(TransactionStatus?, String)>[
      (null, AppStrings.filterAll),
      for (final status in TransactionStatus.values) (status, status.label),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            AppStrings.filter,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              for (final (value, label) in options)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('filter-${label.toLowerCase()}'),
                    label: Text(label),
                    selected: activeFilter == value,
                    showCheckmark: false,
                    onSelected: (isSelected) {
                      if (isSelected) onChanged(value);
                    },
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
