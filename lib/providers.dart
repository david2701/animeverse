import 'package:animeverse/scraping_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'cache_services.dart';
import 'model_anime.dart';

final animeListProvider = FutureProvider<List<Anime>>((ref) async {
  final animeService = AnimeScraperService();
  final animeBox = await Hive.openBox('animeBox');
  final cacheService = AnimeCacheService(animeBox, animeService);

  return await cacheService.getOrUpdateAnimes();
});

