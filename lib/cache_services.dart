// lib/services/cache_services.dart

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/model_anime.dart';
import '../services/anime_scraper_service_base.dart';

class AnimeCacheService {
  final Box _animeBox;
  final AnimeScraperServiceBase _animeService;
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

      // If we have enough items and don't need to update
      if (totalCached >= page * ITEMS_PER_PAGE && !needsGlobalUpdate) {
        debugPrint('📦 Using cache (${totalCached} items stored)');
        return _getCachedAnimes(page);
      }

      debugPrint('🔄 Updating data for page $page');
      final result = await _updateCache(page, totalCached);

      debugPrint('''
        📊 Cache status:
        - Total items: ${result.mergedAnimes.length}
        - New/Updated: ${result.updatedCount}
        - From cache: ${result.mergedAnimes.length - result.updatedCount}
        - Total stored: ${await _getTotalCachedItems()}
      ''');

      return result.mergedAnimes;
    } catch (e) {
      debugPrint('❌ Error during update: $e');
      return _getCachedAnimes(page);
    }
  }

  Future<bool> _needsGlobalUpdate() async {
    final lastUpdate = _animeBox.get(LAST_UPDATE_KEY, defaultValue: 0) as int;
    if (lastUpdate == 0) return true;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final difference = DateTime.now().difference(lastUpdateTime).inHours;

    if (difference > CACHE_DURATION_HOURS) {
      debugPrint('📌 Cache expired (last: ${difference}h ago)');
      return true;
    }

    try {
      final serverTimestamp = await _animeService.getLastModifiedTimestamp();
      final hasChanges = serverTimestamp > lastUpdate;

      if (hasChanges) {
        debugPrint('📌 Changes detected on the server');
      }

      return hasChanges;
    } catch (e) {
      debugPrint('⚠️ Error checking server: $e');
      return false;
    }
  }

  Future<UpdateResult> _updateCache(int page, int totalCached) async {
    // Calculate how many pages we need to fetch
    final currentPages = (totalCached / ITEMS_PER_PAGE).ceil();
    final targetPage = page;
    final updatedAnimes = <Anime>[];
    var updateCount = 0;

    // Fetch missing pages
    for (var i = currentPages + 1; i <= targetPage; i++) {
      final newAnimes = await _animeService.fetchAllAnimes(page: i);
      if (newAnimes.isEmpty) break;

      updatedAnimes.addAll(newAnimes);
      await _savePageToCache(newAnimes, i);
      updateCount += newAnimes.length;
    }

    // Update total and last update time
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

      debugPrint('✅ Page $page saved to cache');
    } catch (e) {
      debugPrint('❌ Error saving page $page: $e');
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

      debugPrint('📖 Read ${animes.length} animes from page $page');
      return animes;
    } catch (e) {
      debugPrint('❌ Error reading cache: $e');
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
      debugPrint('🗑️ Cache completely cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
      rethrow;
    }
  }

  Future<void> _clearPageCache(int page) async {
    final prefixes = ['animeList_', 'cacheTimestamp_', 'cacheVersion_'];
    for (var prefix in prefixes) {
      await _animeBox.delete('${prefix}page_$page');
    }
  }

  // Method to preload multiple pages
  Future<void> preloadPages(int numberOfPages) async {
    debugPrint('🔄 Preloading $numberOfPages pages...');

    for (var i = 1; i <= numberOfPages; i++) {
      await getOrUpdateAnimes(page: i);
    }

    final stats = await getCacheStats();
    debugPrint('''
      ✅ Preloading completed:
      - Total items: ${stats['totalItems']}
      - Pages: ${stats['totalPages']}
      - Last update: ${stats['lastUpdate']}
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