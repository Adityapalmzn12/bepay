import 'package:shared_preferences/shared_preferences.dart';

import 'package:bepay/features/transactions/domain/models/cached_first_page.dart';
import 'package:bepay/features/transactions/domain/repositories/first_page_cache.dart';

final class SharedPreferencesFirstPageCache implements FirstPageCache {
  const SharedPreferencesFirstPageCache(this._preferences);

  static const storageKey = 'last_successful_first_page';

  final SharedPreferences _preferences;

  @override
  Future<CachedFirstPage?> read() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    return CachedFirstPage.decode(raw);
  }

  @override
  Future<void> save(CachedFirstPage page) {
    return _preferences.setString(storageKey, page.encode());
  }
}
