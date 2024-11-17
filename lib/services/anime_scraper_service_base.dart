import '../models/model_anime.dart';

abstract class AnimeScraperServiceBase {
  Future<List<Anime>> fetchAllAnimes({int page = 1});
  Future<List<Anime>> searchAnimes(String query, {int page = 1});
  Future<Anime> fetchAnimeDetails(String animeUrl);
  Future<void> fetchVideoOptionsForEpisode(Episode episode);
  Future<int> getLastModifiedTimestamp();
}