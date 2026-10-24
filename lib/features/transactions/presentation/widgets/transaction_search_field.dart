import 'package:flutter/material.dart';

import 'package:bepay/core/constants/app_constants.dart';

class TransactionSearchField extends StatelessWidget {
  const TransactionSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        key: const Key('transaction-search'),
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: AppStrings.searchLabel,
          hintText: AppStrings.searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (controller.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                key: const Key('transaction-search-clear'),
                tooltip: AppStrings.clearSearch,
                onPressed: onClear,
                icon: const Icon(Icons.close),
              );
            },
          ),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
