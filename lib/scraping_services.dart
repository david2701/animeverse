// lib/services/anime_scraper_service.dart

import 'package:animeverse/services/anime_scraper_service_base.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'dart:convert';
import '../models/model_anime.dart';

class AnimeScraperService implements AnimeScraperServiceBase {
  // HTTP headers to simulate a browser request
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
  Future<List<Anime>> searchAnimes(String query, {int page = 1}) async {
    final List<Anime> animes = [];
    final url = 'https://tioanime.com/directorio?q=${Uri.encodeComponent(query)}&p=$page';
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final document = html.parse(response.body);
      final animeElements = document.querySelectorAll('.animes .anime');

      // Process each anime element
      for (var element in animeElements) {
        try {
          final title = element.querySelector('.title')?.text.trim() ?? 'Unknown Title';
          final detailUrl = element.querySelector('a')?.attributes['href'] ?? '';
          final coverImageUrl = element.querySelector('.thumb img')?.attributes['src'] ?? '';

          final fullDetailUrl = detailUrl.startsWith('http')
              ? detailUrl
              : 'https://tioanime.com$detailUrl';
          final fullCoverImageUrl = coverImageUrl.startsWith('http')
              ? coverImageUrl
              : 'https://tioanime.com$coverImageUrl';

          final anime = Anime(
            title: title,
            coverImageUrl: fullCoverImageUrl,
            detailUrl: fullDetailUrl,
            type: '', // Will be set in fetchAnimeDetails
            year: '', // Will be set in fetchAnimeDetails
            status: '', // Will be set in fetchAnimeDetails
            genres: [], // Will be set in fetchAnimeDetails
            nextEpisodeDate: '', // Will be set in fetchAnimeDetails
            episodes: [], // Will be populated in fetchAnimeDetails
            synopsis: '', // Will be set in fetchAnimeDetails
          );

          animes.add(anime);
        } catch (e) {
          print('Error processing individual anime: $e');
        }
      }
    } catch (e) {
      print('Error searching animes: $e');
      throw Exception('Failed to search animes: $e');
    }
    return animes;
  }

  @override
  Future<List<Anime>> fetchAllAnimes({int page = 1}) async {
    final List<Anime> animes = [];
    final url = 'https://tioanime.com/directorio?p=$page';
    try {
      print('Making GET request to: $url');
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final document = html.parse(response.body);
      final animeElements = document.querySelectorAll('.animes .anime');
      print('Number of animes found: ${animeElements.length}');

      // Process each anime element
      for (var element in animeElements) {
        try {
          print('\nProcessing a new anime...');
          final title = element.querySelector('.title')?.text.trim() ?? 'Unknown Title';
          final detailUrl = element.querySelector('a')?.attributes['href'] ?? '';
          final coverImageUrl = element.querySelector('.thumb img')?.attributes['src'] ?? '';

          final fullDetailUrl = detailUrl.startsWith('http')
              ? detailUrl
              : 'https://tioanime.com$detailUrl';
          final fullCoverImageUrl = coverImageUrl.startsWith('http')
              ? coverImageUrl
              : 'https://tioanime.com$coverImageUrl';

          print('Title: $title');
          print('Detail URL: $fullDetailUrl');
          print('Cover URL: $fullCoverImageUrl');

          final anime = await fetchAnimeDetails(fullDetailUrl);
          final animeWithDetails = anime.copyWith(
            title: title,
            coverImageUrl: fullCoverImageUrl,
            detailUrl: fullDetailUrl,
          );

          animes.add(animeWithDetails);
        } catch (e) {
          print('Error processing individual anime: $e');
        }
      }
    } catch (e) {
      print('Error fetching animes: $e');
      throw Exception('Failed to fetch animes: $e');
    }
    return animes;
  }

  @override
  Future<Anime> fetchAnimeDetails(String animeUrl) async {
    try {
      print('\nMaking GET request to: $animeUrl');
      final response = await http.get(Uri.parse(animeUrl), headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final document = html.parse(response.body);
      print('Starting detail extraction from URL: $animeUrl');

      // Basic anime information
      final title = document.querySelector('h1.title')?.text.trim() ?? 'Unknown Title';
      final type = document.querySelector('.anime-type-peli')?.text.trim() ?? 'N/A';
      final year = document.querySelector('.year')?.text.trim() ?? 'N/A';
      final status = document.querySelector('.status')?.text.trim() ?? 'N/A';
      final genres = document
          .querySelectorAll('.genres a')
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      print('Title: $title');
      print('Type: $type');
      print('Year: $year');
      print('Status: $status');
      print('Genres: ${genres.join(', ')}');

      // Synopsis (if available)
      final synopsisElement = document.querySelector('.synopsis');
      final synopsis = synopsisElement?.text.trim() ?? '';
      print('Synopsis: ${synopsis.isNotEmpty ? synopsis : 'Not available'}');

      // Next episode date
      final nextEpisodeElement = document.querySelector('.next-episode span');
      final nextEpisodeDate = nextEpisodeElement?.text.trim();
      print('Next Episode Date: ${nextEpisodeDate ?? 'Not available'}');

      // Extract episodes from scripts
      final episodes = await _extractEpisodesFromScripts(document, animeUrl);

      // Video options will be fetched when the user accesses the episode details

      return Anime(
        title: title,
        coverImageUrl: '', // Will be updated in fetchAllAnimes
        detailUrl: animeUrl,
        type: type,
        year: year,
        status: status,
        genres: genres,
        nextEpisodeDate: nextEpisodeDate,
        episodes: episodes,
        synopsis: synopsis,
      );
    } catch (e) {
      print('Error fetching anime details: $e');
      throw Exception('Failed to fetch anime details: $e');
    }
  }

  /// Method to extract episodes from embedded scripts in the page.
  Future<List<Episode>> _extractEpisodesFromScripts(Document document, String animeUrl) async {
    final scripts = document.getElementsByTagName('script');

    String episodesScriptContent = '';
    for (var script in scripts) {
      if (script.text.contains('var episodes =')) {
        episodesScriptContent = script.text;
        print('Episodes script found.');
        break;
      }
    }

    if (episodesScriptContent.isEmpty) {
      print('No script found with episode data.');
      return [];
    }

    try {
      // Extract variables: episodes, episodes_details, and anime_info
      final episodesData = _extractJavaScriptArray(episodesScriptContent, 'episodes');
      final episodesDetailsData = _extractJavaScriptArray(episodesScriptContent, 'episodes_details');
      final animeInfoData = _extractJavaScriptArray(episodesScriptContent, 'anime_info');

      print('JavaScript variables extracted successfully.');

      // Convert JavaScript array strings to Dart lists
      final List<dynamic> episodes = json.decode(episodesData);
      final List<dynamic> episodesDetails = json.decode(episodesDetailsData);
      final List<dynamic> animeInfo = json.decode(animeInfoData);

      print('JavaScript arrays converted to Dart lists.');
      print('Episodes: $episodes');
      print('Episode Details: $episodesDetails');
      print('Anime Info: $animeInfo');

      // Build the episode list
      List<Episode> episodeList = [];
      for (int i = 0; i < episodes.length; i++) {
        final episodeNumber = episodes[i];
        final episodeDetail = episodesDetails[i];

        final episodeTitle = '${animeInfo[2]} - Episode $episodeNumber';
        final videoUrl = 'https://tioanime.com/ver/${animeInfo[1]}-$episodeNumber';
        final thumbnailUrl = 'https://tioanime.com/uploads/thumbs/${animeInfo[0]}.jpg';
        final releaseDate = episodeDetail;

        print('Episode $i: $episodeTitle');
        print('Video URL: $videoUrl');
        print('Thumbnail URL: $thumbnailUrl');
        print('Release Date: $releaseDate');

        // Create an episode with empty videoOptions; will be filled later
        episodeList.add(Episode(
          title: episodeTitle,
          videoUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
          videoOptions: [],
        ));
      }

      print('Total episodes processed: ${episodeList.length}');
      return episodeList;
    } catch (e) {
      print('Error extracting episodes from scripts: $e');
      return [];
    }
  }

  /// Method to extract JavaScript array variables from <script> tags
  String _extractJavaScriptArray(String scriptContent, String variableName) {
    final regex = RegExp('$variableName\\s*=\\s*(\\[.*?\\]);', dotAll: true);
    final match = regex.firstMatch(scriptContent);

    if (match != null && match.groupCount >= 1) {
      String arrayString = match.group(1)!;

      // Replace single quotes with double quotes for valid JSON
      arrayString = arrayString.replaceAll("'", '"');

      print('Array extracted for variable "$variableName": $arrayString');

      return arrayString;
    } else {
      throw Exception('Could not extract variable $variableName from script.');
    }
  }

  @override
  Future<void> fetchVideoOptionsForEpisode(Episode episode) async {
    try {
      print('Making GET request for video options to: ${episode.videoUrl}');
      final response = await http.get(Uri.parse(episode.videoUrl), headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      // Print the full HTML of the video options page
      print('HTML of the video options page for episode "${episode.title}":');
      print(response.body);

      // Extract the 'videos' variable from the script
      final document = html.parse(response.body);
      final scripts = document.getElementsByTagName('script');
      String videosScriptContent = '';

      for (var script in scripts) {
        if (script.text.contains('var videos =')) {
          videosScriptContent = script.text;
          print('Videos script found.');
          break;
        }
      }

      if (videosScriptContent.isEmpty) {
        print('No script found with video data.');
        return;
      }

      // Extract the 'videos' variable
      final videosData = _extractJavaScriptArray(videosScriptContent, 'videos');

      // Parse the video data
      final List<dynamic> videosList = json.decode(videosData);

      // Map to VideoOption from model_anime.dart
      List<VideoOption> videoOptions = videosList.map((video) {
        if (video is List && video.length >= 2) {
          return VideoOption(
            optionName: video[0],
            url: video[1],
            requiresConfirmation: video.length >= 4 ? video[3] == 1 : false,
          );
        } else {
          return null;
        }
      }).whereType<VideoOption>().toList();

      print('Extracted video options:');
      for (var vo in videoOptions) {
        print('Option: ${vo.optionName}, URL: ${vo.url}, Requires Confirmation: ${vo.requiresConfirmation}');
      }

      // Update videoOptions in the episode
      print('Updating videoOptions for episode: ${episode.title}');
      episode.videoOptions.clear();
      episode.videoOptions.addAll(videoOptions);
      print('Number of video options updated: ${episode.videoOptions.length}');
    } catch (e) {
      print('Error fetching video options: $e');
      throw Exception('Failed to fetch video options: $e');
    }
  }

  @override
  Future<int> getLastModifiedTimestamp() async {
    try {
      // For now, we simply return the current timestamp
      // In a real implementation, this would come from the server
      return DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      debugPrint('Error getting modification timestamp: $e');
      return 0;
    }
  }
}