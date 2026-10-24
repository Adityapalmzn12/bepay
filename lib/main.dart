import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bepay/app.dart';
import 'package:bepay/features/transactions/data/cache/shared_preferences_first_page_cache.dart';
import 'package:bepay/features/transactions/data/datasources/fake_transaction_data_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final dataSource = FakeTransactionDataSource();
  runApp(
    BePayApp(
      dataSource: dataSource,
      firstPageCache: SharedPreferencesFirstPageCache(preferences),
      onArmFailure: dataSource.armFailNextRequest,
    ),
  );
}
