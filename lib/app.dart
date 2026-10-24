import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bepay/core/constants/app_constants.dart';
import 'package:bepay/features/transactions/data/datasources/fake_transaction_data_source.dart';
import 'package:bepay/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:bepay/features/transactions/domain/repositories/first_page_cache.dart';
import 'package:bepay/features/transactions/domain/usecases/fetch_transactions.dart';
import 'package:bepay/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:bepay/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:bepay/features/transactions/presentation/screens/transaction_history_screen.dart';

class BePayApp extends StatelessWidget {
  const BePayApp({
    required this.dataSource,
    this.firstPageCache,
    this.onArmFailure,
    super.key,
  });

  final FakeTransactionDataSource dataSource;
  final FirstPageCache? firstPageCache;
  final VoidCallback? onArmFailure;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: BlocProvider(
        create: (_) => TransactionHistoryBloc(
          fetchTransactions: FetchTransactions(
            TransactionRepositoryImpl(dataSource),
          ),
          firstPageCache: firstPageCache,
        )..add(const TransactionHistoryStarted()),
        child: TransactionHistoryScreen(onArmFailure: onArmFailure),
      ),
    );
  }
}
