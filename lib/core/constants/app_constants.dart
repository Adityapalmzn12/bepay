import 'package:flutter/material.dart';

abstract final class AppStrings {
  static const appName = 'bepay';

  static const transactionHistoryTitle = 'Transaction history';
  static const failNext = 'Fail next';
  static const failNextArmed = 'The next request will fail once.';

  static const searchLabel = 'Search transactions';
  static const searchHint = 'Merchant or reference';
  static const clearSearch = 'Clear search';

  static const filter = 'Filter';
  static const filterAll = 'All';
  static const statusCompleted = 'Completed';
  static const statusPending = 'Pending';
  static const statusFailed = 'Failed';

  static const tryAgain = 'Try again';
  static const loadingTransactions = 'Loading transactions';
  static const loadingMore = 'Loading more';

  static const noTransactionsTitle = 'No transactions';
  static const noTransactionsMessage = 'Nothing to show for this filter.';
  static const noSearchResultsMessage = 'Nothing matches this search.';

  static const transactionDetailsTitle = 'Transaction';
  static const dateLabel = 'Date';
  static const referenceTitle = 'Reference';
  static const noReference = 'No reference';
  static const transactionIdLabel = 'Transaction ID';

  static const loadErrorTitle = "Couldn't load transactions";
  static const loadErrorMessage = 'Something went wrong. Try again.';
  static const refreshError =
      "Couldn't refresh. Showing the last loaded transactions.";
  static const loadMoreError = "Couldn't load more transactions.";
  static const endOfList = "You've reached the end";

  static const referencePrefix = 'Ref';

  static const inrCode = 'INR';
  static const usdCode = 'USD';
  static const inrSymbol = '₹';
  static const usdSymbol = r'$';
  static const inrSpokenName = 'Indian rupees';
  static const usdSpokenName = 'US dollars';
  static const negativeSpokenPrefix = 'minus ';

  static const am = 'AM';
  static const pm = 'PM';
  static const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const transactionRequestFailed = 'Transaction request failed.';
  static const invalidPageCursor = 'Invalid page cursor.';

  static String referenceLabel(String reference) =>
      '$referencePrefix $reference';
}

abstract final class AppColors {
  static const seed = Color(0xFF0B6E4F);

  static const completedForeground = Color(0xFF085041);
  static const completedBackground = Color(0xFFE7F5EF);

  static const pendingForeground = Color(0xFF7A4E00);
  static const pendingBackground = Color(0xFFFFF3D6);

  static const failedForeground = Color(0xFF9F1C14);
  static const failedBackground = Color(0xFFFDECEC);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.seed);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
    );
  }
}
