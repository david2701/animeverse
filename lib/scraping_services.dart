import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import 'model_anime.dart';

class AnimeScraperService {
  final Dio _dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Connection': 'keep-alive',
      },
    ),
  );

  Future<List<Anime>> fetchAllAnimes({int page = 1}) async {
    final List<Anime> animes = [];
    try {
      final response = await _dio.get('https://tioanime.com/directorio?p=$page');

      if (response.statusCode != 200) {
        throw Exception('Error HTTP: ${response.statusCode}');
      }

      final document = html.parse(response.data);
      final animeElements = document.querySelectorAll('.animes .anime');
      print('Número de animes encontrados en directorio: ${animeElements.length}');

      for (var element in animeElements) {
        try {
          final title = element.querySelector('.title')?.text.trim() ?? 'Título Desconocido';
          final detailUrl = element.querySelector('a')?.attributes['href'] ?? '';
          final coverImageUrl = element.querySelector('.thumb img')?.attributes['src'] ?? '';

          final fullDetailUrl = detailUrl.startsWith('http') ? detailUrl : 'https://tioanime.com$detailUrl';
          final fullCoverImageUrl = coverImageUrl.startsWith('http') ? coverImageUrl : 'https://tioanime.com$coverImageUrl';

          print('Procesando anime: $title');
          print('URL: $fullDetailUrl');
          print('Cover: $fullCoverImageUrl');

          final anime = await fetchAnimeDetails(fullDetailUrl);
          final animeConDetalles = anime.copyWith(
            title: title,
            coverImageUrl: fullCoverImageUrl,
            detailUrl: fullDetailUrl,
          );

          animes.add(animeConDetalles);
        } catch (e) {
          print('Error procesando anime individual: $e');
        }
      }
    } catch (e) {
      print('Error fetching animes: $e');
      throw Exception('Failed to fetch animes: $e');
    }
    return animes;
  }

  Future<Anime> fetchAnimeDetails(String animeUrl) async {
    try {
      final response = await _dio.get(animeUrl);

      if (response.statusCode != 200) {
        throw Exception('Error HTTP: ${response.statusCode}');
      }

      final document = html.parse(response.data);
      print('Iniciando extracción de detalles desde URL: $animeUrl');

      // Información básica
      final title = document.querySelector('h1.title')?.text.trim() ?? '';
      final type = document.querySelector('.anime-type-peli')?.text.trim() ?? 'N/A';
      final year = document.querySelector('.year')?.text.trim() ?? 'N/A';
      final status = document.querySelector('.status')?.text.trim() ?? 'N/A';
      final genres = document.querySelectorAll('.genres a')
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Fecha del próximo episodio
      final nextEpisodeElement = document.querySelector('.next-episode span');
      final nextEpisodeDate = nextEpisodeElement?.text.trim();

      // Extraer episodios
      final episodes = <Episode>[];
      final episodeElements = document.querySelectorAll('ul.episodes-list li');
      print('Encontrados ${episodeElements.length} elementos de episodios');

      for (var element in episodeElements) {
        try {
          final episodeLink = element.querySelector('a.fa-play-circle');
          if (episodeLink != null) {
            final href = episodeLink.attributes['href'] ?? '';
            final videoUrl = href.startsWith('http') ? href : 'https://tioanime.com$href';

            final img = element.querySelector('figure img');
            final thumbnailUrl = img?.attributes['src'] ?? '';
            final fullThumbnailUrl = thumbnailUrl.startsWith('http')
                ? thumbnailUrl
                : 'https://tioanime.com$thumbnailUrl';

            final titleContainer = element.querySelector('.flex-grow-1 p');
            final episodeSpan = element.querySelector('.flex-grow-1 p span');

            String episodeTitle = '';
            if (titleContainer != null && episodeSpan != null) {
              final baseTitle = titleContainer.text.trim();
              final episodeNumber = episodeSpan.text.trim();
              // Mantener el título completo como viene de la página
              episodeTitle = baseTitle;
            } else {
              episodeTitle = 'Episodio Desconocido';
            }

            print('Procesando episodio: $episodeTitle | URL: $videoUrl');

            final episode = Episode(
              title: episodeTitle,
              videoUrl: videoUrl,
              thumbnailUrl: fullThumbnailUrl,
              videoOptions: [],
            );

            episodes.add(episode);
          }
        } catch (e) {
          print('Error procesando episodio individual: $e');
          continue;
        }
      }

      print('Total de episodios procesados: ${episodes.length}');

      return Anime(
        title: title,
        coverImageUrl: '', // Se actualizará en fetchAllAnimes
        detailUrl: animeUrl,
        type: type,
        year: year,
        status: status,
        genres: genres,
        nextEpisodeDate: nextEpisodeDate,
        episodes: episodes,
      );
    } catch (e) {
      print('Error en fetchAnimeDetails: $e');
      throw Exception('Failed to fetch anime details: $e');
    }
  }

  Future<void> fetchEpisodeOptions(Episode episode) async {
    try {
      final response = await _dio.get(episode.videoUrl);

      if (response.statusCode != 200) {
        throw Exception('Error HTTP: ${response.statusCode}');
      }

      final document = html.parse(response.data);
      final optionsElements = document.querySelectorAll('#episode-options .nav-link');
      print('Encontradas ${optionsElements.length} opciones de video');

      final options = optionsElements.map((element) {
        final optionName = element.attributes['data-original-title']?.trim() ?? 'Opción Desconocida';
        final videoUrl = element.attributes['href'] ?? '';
        final fullVideoUrl = videoUrl.startsWith('http') ? videoUrl : 'https://tioanime.com$videoUrl';

        print('Opción de video: $optionName - URL: $fullVideoUrl');

        return VideoOption(
          url: fullVideoUrl,
          optionName: optionName,
        );
      }).toList();

      episode.videoOptions.clear();  // Limpia opciones existentes
      episode.videoOptions.addAll(options);

    } catch (e) {
      print('Error obteniendo opciones de video: $e');
      throw Exception('Failed to fetch video options: $e');
    }
  }
}