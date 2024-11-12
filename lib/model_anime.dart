// model_anime.dart

class Anime {
  final String title;
  final String coverImageUrl;
  final String detailUrl;
  final String type;
  final String year;
  final String status;
  final List<String> genres;
  final String? nextEpisodeDate; // Nuevo campo para la fecha del próximo episodio
  final List<Episode> episodes;

  Anime({
    required this.title,
    required this.coverImageUrl,
    required this.detailUrl,
    required this.type,
    required this.year,
    required this.status,
    required this.genres,
    this.nextEpisodeDate, // Inicialización opcional
    required this.episodes,
  });

  // Método copyWith para copias modificables del modelo
  Anime copyWith({
    String? title,
    String? coverImageUrl,
    String? detailUrl,
    String? type,
    String? year,
    String? status,
    List<String>? genres,
    String? nextEpisodeDate, // Añadido al copyWith
    List<Episode>? episodes,
  }) {
    return Anime(
      title: title ?? this.title,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      detailUrl: detailUrl ?? this.detailUrl,
      type: type ?? this.type,
      year: year ?? this.year,
      status: status ?? this.status,
      genres: genres ?? this.genres,
      nextEpisodeDate: nextEpisodeDate ?? this.nextEpisodeDate, // Asignación opcional
      episodes: episodes ?? this.episodes,
    );
  }

  // Método para convertir un Anime a JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'coverImageUrl': coverImageUrl,
      'detailUrl': detailUrl,
      'type': type,
      'year': year,
      'status': status,
      'genres': genres,
      'nextEpisodeDate': nextEpisodeDate, // Incluir en JSON
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }

  // Método para crear una instancia de Anime desde JSON
  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      title: json['title'],
      coverImageUrl: json['coverImageUrl'],
      detailUrl: json['detailUrl'],
      type: json['type'],
      year: json['year'],
      status: json['status'],
      genres: List<String>.from(json['genres']),
      nextEpisodeDate: json['nextEpisodeDate'], // Recuperar de JSON
      episodes: List<Episode>.from(
          json['episodes'].map((e) => Episode.fromJson(e))),
    );
  }
}

class Episode {
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final List<VideoOption> videoOptions;

  Episode({
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.videoOptions,
  });

  // Método copyWith para Episode si se necesita
  Episode copyWith({
    String? title,
    String? videoUrl,
    String? thumbnailUrl,
    List<VideoOption>? videoOptions,
  }) {
    return Episode(
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoOptions: videoOptions ?? this.videoOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'videoOptions': videoOptions.map((v) => v.toJson()).toList(),
    };
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      title: json['title'],
      videoUrl: json['videoUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      videoOptions: List<VideoOption>.from(
          json['videoOptions'].map((v) => VideoOption.fromJson(v))),
    );
  }
}

class VideoOption {
  final String url;
  final String optionName;

  VideoOption({required this.url, required this.optionName});

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'optionName': optionName,
    };
  }

  factory VideoOption.fromJson(Map<String, dynamic> json) {
    return VideoOption(
      url: json['url'],
      optionName: json['optionName'],
    );
  }
}
