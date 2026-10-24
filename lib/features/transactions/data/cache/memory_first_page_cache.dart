import 'package:bepay/features/transactions/domain/models/cached_first_page.dart';
import 'package:bepay/features/transactions/domain/repositories/first_page_cache.dart';

final class MemoryFirstPageCache implements FirstPageCache {
  CachedFirstPage? _page;

  @override
  Future<CachedFirstPage?> read() async => _page;

  @override
  Future<void> save(CachedFirstPage page) async {
    _page = page;
  }
}
