// lib/notifiers/anime_list_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/model_anime.dart';
import '../providers.dart';
import '../services/anime_scraper_service_base.dart';

class AnimeListNotifier extends StateNotifier<List<Anime>> {
  final AnimeScraperServiceBase scraperService;
  final Ref ref;

  AnimeListNotifier(this.scraperService, this.ref) : super([]);

  Future<void> loadMoreAnimes() async {
    final currentPage = ref.read(currentPageProvider);
    final animes = await scraperService.fetchAllAnimes(page: currentPage);
    state = [...state, ...animes];
    ref.read(currentPageProvider.notifier).state = currentPage + 1;
  }
}