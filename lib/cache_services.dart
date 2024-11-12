import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../scraping_services.dart';
import '../models/model_anime.dart';

class AnimeCacheService {
  final Box _animeBox;
  final AnimeScraperService _animeService;
  static const int CACHE_DURATION_HOURS = 24;
  static const String CACHE_VERSION = "1.0";
  static const String TOTAL_ITEMS_KEY = 'total_cached_items';
  static const String LAST_UPDATE_KEY = 'last_global_update';
  static const int ITEMS_PER_PAGE = 20;

  AnimeCacheService(this._animeBox, this._animeService);

  Future<List<Anime>> getOrUpdateAnimes({int page = 1}) async {
    try {
      final totalCached =
          _animeBox.get(TOTAL_ITEMS_KEY, defaultValue: 0) as int;
      final needsGlobalUpdate = await _needsGlobalUpdate();

// Si tenemos suficientes items y no necesitamos actualizar
      if (totalCached >= page * ITEMS_PER_PAGE && !needsGlobalUpdate) {
        debugPrint('📦 Usando caché (${totalCached} items almacenados)');
        return _getCachedAnimes(page);
      }

      debugPrint('🔄 Actualizando datos para página $page');
      final result = await _updateCache(page, totalCached);

      debugPrint('''
        📊 Estado del caché:
        - Total elementos: ${result.mergedAnimes.length}
        - Nuevos/Actualizados: ${result.updatedCount}
        - Desde caché: ${result.mergedAnimes.length - result.updatedCount}
        - Total almacenado: ${await _getTotalCachedItems()}
      ''');

      return result.mergedAnimes;
    } catch (e) {
      debugPrint('❌ Error en actualización: $e');
      return _getCachedAnimes(page);
    }
  }

  Future<bool> _needsGlobalUpdate() async {
    final lastUpdate = _animeBox.get(LAST_UPDATE_KEY, defaultValue: 0) as int;
    if (lastUpdate == 0) return true;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final difference = DateTime.now().difference(lastUpdateTime).inHours;

    if (difference > CACHE_DURATION_HOURS) {
      debugPrint('📌 Caché expirado (último: ${difference}h atrás)');
      return true;
    }

    try {
      final serverTimestamp = await _animeService.getLastModifiedTimestamp();
      final hasChanges = serverTimestamp > lastUpdate;

      if (hasChanges) {
        debugPrint('📌 Detectados cambios en el servidor');
      }

      return hasChanges;
    } catch (e) {
      debugPrint('⚠️ Error verificando servidor: $e');
      return false;
    }
  }

  Future<UpdateResult> _updateCache(int page, int totalCached) async {
// Calcular cuántas páginas necesitamos obtener
    final currentPages = (totalCached / ITEMS_PER_PAGE).ceil();
    final targetPage = page;
    final updatedAnimes = <Anime>[];
    var updateCount = 0;

// Obtener las páginas que faltan
    for (var i = currentPages + 1; i <= targetPage; i++) {
      final newAnimes = await _animeService.fetchAllAnimes(page: i);
      if (newAnimes.isEmpty) break;

      updatedAnimes.addAll(newAnimes);
      await _savePageToCache(newAnimes, i);
      updateCount += newAnimes.length;
    }

// Actualizar el total y la última actualización
    final newTotal = totalCached + updateCount;
    await _animeBox.put(TOTAL_ITEMS_KEY, newTotal);
    await _animeBox.put(LAST_UPDATE_KEY, DateTime.now().millisecondsSinceEpoch);

    return UpdateResult(
      mergedAnimes: _getCachedAnimes(page),
      updatedCount: updateCount,
    );
  }

  Future<void> _savePageToCache(List<Anime> animes, int page) async {
    final cacheKey = 'animeList_page_$page';
    final timestampKey = 'cacheTimestamp_page_$page';
    final versionKey = 'cacheVersion_page_$page';

    try {
      final animeJsonList = animes.map((anime) => anime.toJson()).toList();

      await _animeBox.putAll({
        cacheKey: animeJsonList,
        timestampKey: DateTime.now().millisecondsSinceEpoch,
        versionKey: CACHE_VERSION,
      });

      debugPrint('✅ Página $page guardada en caché');
    } catch (e) {
      debugPrint('❌ Error guardando página $page: $e');
      await _clearPageCache(page);
      rethrow;
    }
  }

  List<Anime> _getCachedAnimes(int page) {
    try {
      final cacheKey = 'animeList_page_$page';
      final animeJsonList = _animeBox.get(cacheKey);

      if (animeJsonList == null) return [];

      final animes = (animeJsonList as List).map((animeJson) {
        final convertedJson = _convertKeysToString(animeJson);
        return Anime.fromJson(convertedJson);
      }).toList();

      debugPrint('📖 Leídos ${animes.length} animes de la página $page');
      return animes;
    } catch (e) {
      debugPrint('❌ Error leyendo caché: $e');
      return [];
    }
  }


  dynamic _convertKeysToString(dynamic data) {
    if (data is Map) {
      return data.map<String, dynamic>((key, value) {
        return MapEntry(key.toString(), _convertKeysToString(value));
      });
    } else if (data is List) {
      return data.map((item) => _convertKeysToString(item)).toList();
    } else {
      return data;
    }
  }


  Future<int> _getTotalCachedItems() async {
    return _animeBox.get(TOTAL_ITEMS_KEY, defaultValue: 0) as int;
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    final totalItems = await _getTotalCachedItems();
    final lastUpdate = _animeBox.get(LAST_UPDATE_KEY, defaultValue: 0) as int;
    final totalPages = (totalItems / ITEMS_PER_PAGE).ceil();

    return {
      'totalItems': totalItems,
      'totalPages': totalPages,
      'lastUpdate': DateTime.fromMillisecondsSinceEpoch(lastUpdate),
      'cacheVersion': CACHE_VERSION,
      'isExpired': DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(lastUpdate))
              .inHours >
          CACHE_DURATION_HOURS,
    };
  }

  Future<void> clearCache() async {
    try {
      await _animeBox.clear();
      debugPrint('🗑️ Caché limpiado completamente');
    } catch (e) {
      debugPrint('❌ Error limpiando caché: $e');
      rethrow;
    }
  }

  Future<void> _clearPageCache(int page) async {
    final prefixes = ['animeList_', 'cacheTimestamp_', 'cacheVersion_'];
    for (var prefix in prefixes) {
      await _animeBox.delete('${prefix}page_$page');
    }
  }

// Método para pre-cargar varias páginas
  Future<void> preloadPages(int numberOfPages) async {
    debugPrint('🔄 Pre-cargando $numberOfPages páginas...');

    for (var i = 1; i <= numberOfPages; i++) {
      await getOrUpdateAnimes(page: i);
    }

    final stats = await getCacheStats();
    debugPrint('''
      ✅ Pre-carga completada:
      - Total items: ${stats['totalItems']}
      - Páginas: ${stats['totalPages']}
      - Última actualización: ${stats['lastUpdate']}
    ''');
  }
}

class UpdateResult {
  final List<Anime> mergedAnimes;
  final int updatedCount;

  UpdateResult({
    required this.mergedAnimes,
    required this.updatedCount,
  });
}
