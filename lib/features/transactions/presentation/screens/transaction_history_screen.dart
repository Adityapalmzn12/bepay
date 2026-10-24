import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bepay/core/constants/app_constants.dart';
import 'package:bepay/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:bepay/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:bepay/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:bepay/features/transactions/domain/entities/transaction.dart';
import 'package:bepay/features/transactions/presentation/screens/transaction_details_screen.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_empty_view.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_error_view.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_filter_bar.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_list_view.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_loading_view.dart';
import 'package:bepay/features/transactions/presentation/widgets/transaction_search_field.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({this.onArmFailure, super.key});

  final VoidCallback? onArmFailure;

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const _loadMoreThreshold = 280.0;
  static const _searchDelay = Duration(milliseconds: 300);

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.transactionHistoryTitle),
        actions: [
          if (widget.onArmFailure != null)
            TextButton(
              onPressed: () {
                widget.onArmFailure!();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text(AppStrings.failNextArmed)),
                  );
              },
              child: const Text(AppStrings.failNext),
            ),
        ],
      ),
      body: BlocConsumer<TransactionHistoryBloc, TransactionHistoryState>(
        listenWhen: (previous, current) =>
            previous.activeFilter != current.activeFilter ||
            previous.query != current.query,
        listener: (context, state) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
          if (_searchController.text != state.query) {
            _searchController.value = TextEditingValue(
              text: state.query,
              selection: TextSelection.collapsed(offset: state.query.length),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: _onPullRefresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: TransactionSearchField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClear: _clearSearch,
                    ),
                  ),
                  if (state.isRefreshing)
                    const SliverToBoxAdapter(
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  SliverToBoxAdapter(
                    child: TransactionFilterBar(
                      activeFilter: state.activeFilter,
                      onChanged: (status) {
                        context.read<TransactionHistoryBloc>().add(
                          TransactionFilterChanged(status),
                        );
                      },
                    ),
                  ),
                  if (state.failureKind == HistoryFailureKind.refresh)
                    SliverToBoxAdapter(
                      child: TransactionMessageBanner(
                        message: AppStrings.refreshError,
                        actionLabel: AppStrings.tryAgain,
                        actionKey: const Key('retry-refresh'),
                        onAction: () => _retry(context),
                      ),
                    ),
                  if (state.isInitialLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: TransactionLoadingView(
                        label: AppStrings.loadingTransactions,
                      ),
                    )
                  else if (state.isInitialFailure)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: TransactionErrorView(
                        title: AppStrings.loadErrorTitle,
                        message: AppStrings.loadErrorMessage,
                        retryLabel: AppStrings.tryAgain,
                        retryKey: const Key('retry-initial'),
                        onRetry: () => _retry(context),
                      ),
                    )
                  else if (state.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: TransactionEmptyView(
                        title: AppStrings.noTransactionsTitle,
                        message: state.query.isEmpty
                            ? AppStrings.noTransactionsMessage
                            : AppStrings.noSearchResultsMessage,
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  else
                    TransactionListView(
                      transactions: state.transactions,
                      isLoadingMore: state.isLoadingMore,
                      showLoadMoreError:
                          state.failureKind == HistoryFailureKind.nextPage,
                      showEndOfList:
                          state.hasReachedEnd &&
                          state.transactions.isNotEmpty &&
                          !state.isLoadingMore &&
                          state.failureKind != HistoryFailureKind.nextPage,
                      onRetry: () => _retry(context),
                      onTransactionTap: (transaction) =>
                          _openDetails(context, transaction),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _clearSearch() {
    _searchTimer?.cancel();
    _searchController.clear();
    context.read<TransactionHistoryBloc>().add(
      const TransactionSearchChanged(''),
    );
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDelay, () {
      if (!mounted) return;
      context.read<TransactionHistoryBloc>().add(
        TransactionSearchChanged(value),
      );
    });
  }

  void _openDetails(BuildContext context, Transaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionDetailsScreen(transaction: transaction),
      ),
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification) {
      return false;
    }
    if (notification.metrics.extentAfter < _loadMoreThreshold) {
      context.read<TransactionHistoryBloc>().add(
        const TransactionHistoryLoadMoreRequested(),
      );
    }
    return false;
  }

  void _retry(BuildContext context) {
    context.read<TransactionHistoryBloc>().add(
      const TransactionHistoryRetryRequested(),
    );
  }

  Future<void> _onPullRefresh() async {
    final bloc = context.read<TransactionHistoryBloc>();
    if (bloc.isClosed) return;

    final done = Completer<void>();
    var sawRefreshing = false;
    final subscription = bloc.stream.listen(
      (state) {
        if (state.isRefreshing) sawRefreshing = true;
        if (sawRefreshing && !state.isRefreshing && !done.isCompleted) {
          done.complete();
        }
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
    );
    bloc.add(const TransactionHistoryRefreshed());
    try {
      await done.future;
    } finally {
      await subscription.cancel();
    }
  }
}
