import 'package:bepay/features/transactions/domain/models/cached_first_page.dart';

abstract interface class FirstPageCache {
  Future<CachedFirstPage?> read();

  Future<void> save(CachedFirstPage page);
}
