import 'package:tablebid/models/menu_cache_model.dart';
import 'package:tablebid/services/menu_cache_api.dart';

class CacheMenu {
    static final CacheMenu instance = CacheMenu._();
    CacheMenu._();
    MenuCacheModel? _cache;
    MenuCacheModel? get cache => _cache;
    // instance.cache

    Future<MenuCacheModel> load(
      String companyId,
      {bool forceRefresh = false}
      ) async {
      // 캐시 있으면 그거 반환
      if (!forceRefresh && _cache?.companyId == companyId) {
        return _cache!;
      }
      // 없으면 api 호출해서 새 거 반환
      final data = await MenuCacheApi().getMenuCache(companyId);
      _cache = data;
      return data;
    }
    // 캐시 비우는 함수
    void clear() {
      _cache = null;
    }
  }