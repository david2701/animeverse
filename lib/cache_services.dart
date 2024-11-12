import 'package:animeverse/scraping_services.dart';
import 'package:hive/hive.dart';
import 'model_anime.dart';

class AnimeCacheService {
  final Box _animeBox;
  final AnimeScraperService _animeService;

  AnimeCacheService(this._animeBox, this._animeService);

  Future<List<Anime>> getOrUpdateAnimes({int page = 1}) async {
    final cacheKey = 'animeList_page_$page';
    final timestampKey = 'cacheTimestamp_page_$page';

    if (_animeBox.containsKey(cacheKey) && !isCacheExpired(timestampKey)) {
      return getCachedAnimes(page);
    } else {
      final animes = await _animeService.fetchAllAnimes(page: page);
      await cacheAnimes(animes, page);
      return animes;
    }
  }

  List<Anime> getCachedAnimes(int page) {
    final cacheKey = 'animeList_page_$page';
    final animeJsonList = _animeBox.get(cacheKey, defaultValue: []);
    return (animeJsonList as List)
        .map((animeJson) => Anime.fromJson(Map<String, dynamic>.from(animeJson)))
        .toList();
  }

  bool isCacheExpired(String timestampKey) {
    final cacheTimestamp = _animeBox.get(timestampKey, defaultValue: 0);
    final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
    return DateTime.now().difference(cacheDateTime).inHours > 12;
  }

  Future<void> cacheAnimes(List<Anime> animes, int page) async {
    final cacheKey = 'animeList_page_$page';
    final timestampKey = 'cacheTimestamp_page_$page';

    final animeJsonList = animes.map((anime) => anime.toJson()).toList();
    await _animeBox.put(cacheKey, animeJsonList);
    await _animeBox.put(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }
}
