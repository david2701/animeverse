import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'dart:convert';
import 'models/model_anime.dart';

class AnimeScraperService {
  // Encabezados HTTP para simular una solicitud de navegador
  final Map<String, String> _headers = {
    'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36',
    'Accept':
    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'es-ES,es;q=0.9',
    'Connection': 'keep-alive',
  };

  Future<int> getLastModifiedTimestamp() async {
    try {
      // Por ahora, simplemente devolvemos el timestamp actual
      // En una implementación real, esto vendría del servidor
      return DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      debugPrint('Error obteniendo timestamp de modificación: $e');
      return 0;
    }
  }

  /// Método para obtener todos los animes de un directorio específico.
  /// [page]: número de página para la paginación del directorio.
  Future<List<Anime>> fetchAllAnimes({int page = 1}) async {
    final List<Anime> animes = [];
    final url = 'https://tioanime.com/directorio?p=$page';
    try {
      print('Realizando solicitud GET a: $url');
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('Error HTTP: ${response.statusCode}');
      }

      final document = html.parse(response.body);
      final animeElements = document.querySelectorAll('.animes .anime');
      print('Número de animes encontrados en directorio: ${animeElements.length}');

      for (var element in animeElements) {
        try {
          final title = element.querySelector('.title')?.text.trim() ?? 'Título Desconocido';
          final detailUrl = element.querySelector('a')?.attributes['href'] ?? '';
          final coverImageUrl = element.querySelector('.thumb img')?.attributes['src'] ?? '';

          final fullDetailUrl = detailUrl.startsWith('http')
              ? detailUrl
              : 'https://tioanime.com$detailUrl';
          final fullCoverImageUrl = coverImageUrl.startsWith('http')
              ? coverImageUrl
              : 'https://tioanime.com$coverImageUrl';

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

  /// Método para obtener los detalles de un anime específico.
  /// [animeUrl]: URL de la página de detalles del anime.
  Future<Anime> fetchAnimeDetails(String animeUrl) async {
    try {
      print('Realizando solicitud GET a: $animeUrl');
      final response = await http.get(Uri.parse(animeUrl), headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('Error HTTP: ${response.statusCode}');
      }

      final document = html.parse(response.body);
      print('Iniciando extracción de detalles desde URL: $animeUrl');

      // Información básica del anime
      final title = document.querySelector('h1.title')?.text.trim() ?? 'Título Desconocido';
      final type = document.querySelector('.anime-type-peli')?.text.trim() ?? 'N/A';
      final year = document.querySelector('.year')?.text.trim() ?? 'N/A';
      final status = document.querySelector('.status')?.text.trim() ?? 'N/A';
      final genres = document
          .querySelectorAll('.genres a')
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Fecha del próximo episodio
      final nextEpisodeElement = document.querySelector('.next-episode span');
      final nextEpisodeDate = nextEpisodeElement?.text.trim();

      // Extraer episodios desde los scripts
      final episodes = await _extractEpisodesFromScripts(document, animeUrl);

      return Anime(
        title: title,
        coverImageUrl: '',
        // Se actualizará en fetchAllAnimes
        detailUrl: animeUrl,
        type: type,
        year: year,
        status: status,
        genres: genres,
        nextEpisodeDate: nextEpisodeDate,
        episodes: episodes,
      );
    } catch (e) {
      print('Error fetching anime details: $e');
      throw Exception('Failed to fetch anime details: $e');
    }
  }

  /// Método para extraer los episodios desde los scripts embebidos en la página.
  Future<List<Episode>> _extractEpisodesFromScripts(Document document, String animeUrl) async {
    final scripts = document.getElementsByTagName('script');

    String episodesScriptContent = '';
    for (var script in scripts) {
      if (script.text.contains('var episodes =')) {
        episodesScriptContent = script.text;
        break;
      }
    }

    if (episodesScriptContent.isEmpty) {
      print('No se encontró el script con los datos de los episodios.');
      return [];
    }

    try {
      // Extraer las variables episodes, episodes_details y anime_info
      final episodesData = _extractJavaScriptArray(episodesScriptContent, 'episodes');
      final episodesDetailsData = _extractJavaScriptArray(episodesScriptContent, 'episodes_details');
      final animeInfoData = _extractJavaScriptArray(episodesScriptContent, 'anime_info');

      // Convertir las cadenas de arrays JavaScript a listas de Dart
      final List<dynamic> episodes = json.decode(episodesData);
      final List<dynamic> episodesDetails = json.decode(episodesDetailsData);
      final List<dynamic> animeInfo = json.decode(animeInfoData);

      // Construir la lista de episodios
      List<Episode> episodeList = [];
      for (int i = 0; i < episodes.length; i++) {
        final episodeNumber = episodes[i];
        final episodeDetail = episodesDetails[i];

        final episodeTitle = '${animeInfo[2]} - Episodio $episodeNumber';
        final videoUrl = 'https://tioanime.com/ver/${animeInfo[1]}-$episodeNumber';
        final thumbnailUrl = 'https://tioanime.com/uploads/thumbs/${animeInfo[0]}.jpg';
        final releaseDate = episodeDetail;

        episodeList.add(Episode(
          title: episodeTitle,
          videoUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
          videoOptions: [],
        ));
      }

      print('Total de episodios procesados: ${episodeList.length}');
      return episodeList;
    } catch (e) {
      print('Error al extraer episodios desde los scripts: $e');
      return [];
    }
  }

  /// Método para extraer arrays de variables JavaScript en los <script>
  String _extractJavaScriptArray(String scriptContent, String variableName) {
    final regex = RegExp('$variableName\\s*=\\s*(\\[.*?\\]);', dotAll: true);
    final match = regex.firstMatch(scriptContent);

    if (match != null && match.groupCount >= 1) {
      String arrayString = match.group(1)!;

      // Reemplazar comillas simples por comillas dobles para JSON válido
      arrayString = arrayString.replaceAll("'", '"');

      return arrayString;
    } else {
      throw Exception('No se pudo extraer la variable $variableName del script.');
    }
  }

  /// Método para obtener las opciones de video de un episodio específico.
  /// [episode]: instancia de [Episode] para la cual se obtendrán las opciones de video.
  Future<void> fetchEpisodeOptions(Episode episode) async {
    try {
      print('Realizando solicitud GET para opciones de video a: ${episode.videoUrl}');
      final response = await http.get(Uri.parse(episode.videoUrl), headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('Error HTTP: ${response.statusCode}');
      }

      final document = html.parse(response.body);
      final optionsElements = document.querySelectorAll('#episode-options .nav-link');
      print('Encontradas ${optionsElements.length} opciones de video');

      final options = optionsElements.map((element) {
        final optionName = element.attributes['title']?.trim() ?? 'Opción Desconocida';
        final dataId = element.attributes['data-id'] ?? '';
        final videoUrl = 'https://tioanime.com/ver/${episode.videoUrl.split('/').last}?opcion=$dataId';

        print('Opción de video: $optionName - URL: $videoUrl');

        return VideoOption(
          url: videoUrl,
          optionName: optionName,
        );
      }).toList();

      episode.videoOptions.clear(); // Limpia opciones existentes
      episode.videoOptions.addAll(options);
    } catch (e) {
      print('Error obteniendo opciones de video: $e');
      throw Exception('Failed to fetch video options: $e');
    }
  }
}
