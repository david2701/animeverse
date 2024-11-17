// lib/services/flv_anime_scraper_service.dart

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'dart:convert';
import '../models/model_anime.dart';
import 'anime_scraper_service_base.dart';

class FLVAnimeScraperService implements AnimeScraperServiceBase {
  final String baseUrl = 'https://www3.animeflv.net';

  final Map<String, String> _headers = {
    'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)'
        ' Chrome/112.0.0.0 Safari/537.36',
    'Accept':
    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'es-ES,es;q=0.9',
    'Connection': 'keep-alive',
  };

  @override
  Future<List<Anime>> fetchAllAnimes({int page = 1}) async {
    return getPopular(page: page);
  }

  @override
  Future<List<Anime>> searchAnimes(String query, {int page = 1}) async {
    final url = '$baseUrl/browse?q=${Uri.encodeComponent(query)}&page=$page';
    return _fetchAnimesFromUrl(url);
  }

  @override
  Future<Anime> fetchAnimeDetails(String animeUrl) async {
    return getDetail(animeUrl);
  }

  @override
  Future<void> fetchVideoOptionsForEpisode(Episode episode) async {
    await getVideoList(episode);
  }

  @override
  Future<int> getLastModifiedTimestamp() async {
    return DateTime.now().millisecondsSinceEpoch;
  }

  // Additional methods specific to FLVAnimeScraperService

  Future<List<Anime>> getPopular({int page = 1}) async {
    final url = '$baseUrl/browse?order=rating&page=$page';
    return _fetchAnimesFromUrl(url);
  }

  Future<List<Anime>> getLatestUpdates({int page = 1}) async {
    final url = '$baseUrl/browse?order=added&page=$page';
    return _fetchAnimesFromUrl(url);
  }

  // Helper method to fetch animes from a given URL.
  Future<List<Anime>> _fetchAnimesFromUrl(String url) async {
    final List<Anime> animes = [];
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final document = html.parse(response.body);

      final animeElements =
      document.querySelectorAll('div.Container ul.ListAnimes li article');

      for (var element in animeElements) {
        try {
          final name = element.querySelector('a h3')?.text.trim() ?? 'Unknown Title';
          final detailUrl =
              element.querySelector('div.Description a.Button')?.attributes['href'] ?? '';
          final thumbnailUrl = element
              .querySelector('a div.Image figure img')
              ?.attributes['src'] ??
              element.querySelector('a div.Image figure img')?.attributes['data-cfsrc'] ??
              '';

          final fullThumbnailUrl = thumbnailUrl.startsWith('http')
              ? thumbnailUrl
              : '$baseUrl$thumbnailUrl';

          final anime = Anime(
            id: '$baseUrl$detailUrl',
            title: name,
            coverImageUrl: fullThumbnailUrl,
            detailUrl: detailUrl, // Relative URL
            type: '', // Will be set in getDetail
            year: '', // Will be set in getDetail
            status: '', // Will be set in getDetail
            genres: [], // Will be set in getDetail
            nextEpisodeDate: '', // Not specified
            episodes: [], // Will be populated in getDetail
            synopsis: '', // Will be set in getDetail
          );

          animes.add(anime);
        } catch (e) {
          debugPrint('Error processing anime: $e');
        }
      }
    } catch (e) {
      debugPrint('Error fetching animes: $e');
      throw Exception('Failed to fetch animes: $e');
    }
    return animes;
  }

  // Fetches anime details for a given URL.
  Future<Anime> getDetail(String animeUrl) async {
    try {
      // Handle relative URLs
      String fullAnimeUrl = animeUrl.startsWith('http')
          ? animeUrl
          : '$baseUrl$animeUrl';

      final response = await http.get(Uri.parse(fullAnimeUrl), headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final document = html.parse(response.body);

      final title = document
          .querySelector('div.Ficha .Container h1.Title')
          ?.text
          .trim() ??
          'Unknown Title';
      final statusText = document.querySelector('p.AnmStts')?.text.trim() ?? 'N/A';
      final status = _parseStatus(statusText);
      final genreElements = document.querySelectorAll('nav.Nvgnrs a');
      final genres = genreElements.map((e) => e.text.trim()).toList();

      final description =
          document.querySelector('div.Description')?.text.trim() ?? '';

      String type = '';
      String year = '';

      // Extract type and year if available
      final typeYearElements = document.querySelectorAll('span.TxtAlt');
      if (typeYearElements.isNotEmpty) {
        type = typeYearElements[0].text.trim();
        if (typeYearElements.length > 1) {
          year = typeYearElements[1].text.trim();
        }
      }

      List<Episode> episodes = [];

      // Extract 'anime_info' and 'episodes' variables from scripts
      String? animeInfoText;
      String? episodesText;

      for (var script in document.getElementsByTagName('script')) {
        if (script.text.contains('var anime_info =')) {
          // Use regex to extract the anime_info variable
          final animeInfoMatch = RegExp(r'var anime_info\s*=\s*(\[.*?\]);', dotAll: true)
              .firstMatch(script.text);
          if (animeInfoMatch != null) {
            animeInfoText = animeInfoMatch.group(1);
          }

          // Use regex to extract the episodes variable
          final episodesMatch = RegExp(r'var episodes\s*=\s*(\[.*?\]);', dotAll: true)
              .firstMatch(script.text);
          if (episodesMatch != null) {
            episodesText = episodesMatch.group(1);
          }

          break;
        }
      }

      if (animeInfoText != null && episodesText != null) {
        // Clean up the animeInfoText to make it valid JSON
        animeInfoText = animeInfoText.replaceAll("'", '"');

        final animeInfo = jsonDecode(animeInfoText);
        final animeUri = animeInfo[2].toString().replaceAll('"', '');

        // Clean up the episodesText to make it valid JSON
        episodesText = episodesText.replaceAll("'", '"');

        final episodesData = jsonDecode(episodesText);

        for (var episodeInfo in episodesData) {
          final episodeNumber = episodeInfo[0];
          final episodeUrl = '$baseUrl/ver/$animeUri-$episodeNumber';
          final episodeTitle = 'Episodio $episodeNumber';
          final thumbnailUrl = ''; // FLVAnime doesn't provide thumbnail URLs for episodes

          episodes.add(Episode(
            title: episodeTitle,
            videoUrl: episodeUrl,
            thumbnailUrl: thumbnailUrl,
            videoOptions: [],
          ));
        }
      } else {
        print('Failed to extract anime_info or episodes from script.');
      }

      return Anime(
        id: fullAnimeUrl,
        title: title,
        coverImageUrl: '', // Will be set in fetchAllAnimes
        detailUrl: animeUrl, // Use the relative URL
        type: type,
        year: year,
        status: status,
        genres: genres,
        nextEpisodeDate: '', // Not specified
        episodes: episodes,
        synopsis: description,
      );
    } catch (e) {
      debugPrint('Error fetching anime details: $e');
      throw Exception('Failed to fetch anime details: $e');
    }
  }

  String _parseStatus(String statusString) {
    if (statusString.contains('En emisión')) {
      return 'Ongoing';
    } else if (statusString.contains('Finalizado')) {
      return 'Completed';
    } else {
      return 'Unknown';
    }
  }

  // Fetches video options for a given episode.
  Future<void> getVideoList(Episode episode) async {
    try {
      final response =
      await http.get(Uri.parse(episode.videoUrl), headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final document = html.parse(response.body);

      String videosScriptContent = '';
      for (var script in document.getElementsByTagName('script')) {
        if (script.text.contains('var videos = {')) {
          videosScriptContent = script.text;
          break;
        }
      }

      if (videosScriptContent.isEmpty) {
        debugPrint('No videos script found.');
        return;
      }

      final videosDataString = videosScriptContent
          .split('var videos =')[1]
          .split(';')[0]
          .trim();

      // Clean up the JavaScript object to make it JSON-compatible
      final videosDataJsonString = videosDataString
          .replaceAll("'", '"')
          .replaceAll(',}', '}')
          .replaceAll(',]', ']');

      final Map<String, dynamic> videosData =
      jsonDecode(videosDataJsonString);

      List<VideoOption> videoOptions = [];

      // Extract video options from the 'SUB', 'LAT', and other keys
      for (String key in ['SUB', 'SUB_ESP', 'LAT', 'ESP']) {
        if (videosData.containsKey(key)) {
          final videoList = videosData[key];
          if (videoList is List) {
            for (var video in videoList) {
              if (video is Map<String, dynamic>) {
                final optionName = video['title'] ?? 'Unknown';
                final url = video['code'] ?? video['url'] ?? '';
                final requiresConfirmation = false;
                videoOptions.add(VideoOption(
                  optionName: optionName,
                  url: url,
                  requiresConfirmation: requiresConfirmation,
                ));
              }
            }
          }
        }
      }

      episode.videoOptions.clear();
      episode.videoOptions.addAll(videoOptions);
    } catch (e) {
      debugPrint('Error fetching video options: $e');
      throw Exception('Failed to fetch video options: $e');
    }
  }
}