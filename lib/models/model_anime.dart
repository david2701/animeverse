// model_anime.dart

import 'package:crypto/crypto.dart';
import 'dart:convert';

class Anime {
  final String id; // Nuevo campo ID interno
  final String title;
  final String coverImageUrl;
  final String detailUrl;
  final String type;
  final String year;
  final String status;
  final List<String> genres;
  final String? nextEpisodeDate;
  final List<Episode> episodes;
  final String synopsis;

  Anime({
    String? id, // Opcional en el constructor
    required this.title,
    required this.coverImageUrl,
    required this.detailUrl,
    required this.type,
    required this.year,
    required this.status,
    required this.genres,
    this.nextEpisodeDate,
    required this.episodes,
    this.synopsis = '',
  }) : id = id ?? _generateId(detailUrl);

  // Método estático para generar ID
  static String _generateId(String detailUrl) {
    // Generamos un hash MD5 de la URL y tomamos los primeros 10 caracteres
    final bytes = utf8.encode(detailUrl);
    final digest = md5.convert(bytes);
    return digest.toString().substring(0, 10);
  }

  // Método copyWith actualizado
  Anime copyWith({
    String? id,
    String? title,
    String? coverImageUrl,
    String? detailUrl,
    String? type,
    String? year,
    String? status,
    List<String>? genres,
    String? nextEpisodeDate,
    List<Episode>? episodes,
    String? synopsis,
  }) {
    return Anime(
      id: id ?? this.id,
      title: title ?? this.title,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      detailUrl: detailUrl ?? this.detailUrl,
      type: type ?? this.type,
      year: year ?? this.year,
      status: status ?? this.status,
      genres: genres ?? this.genres,
      nextEpisodeDate: nextEpisodeDate ?? this.nextEpisodeDate,
      episodes: episodes ?? this.episodes,
      synopsis: synopsis ?? this.synopsis,
    );
  }

  // Método toJson actualizado
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverImageUrl': coverImageUrl,
      'detailUrl': detailUrl,
      'type': type,
      'year': year,
      'status': status,
      'synopsis': synopsis,
      'genres': genres,
      'nextEpisodeDate': nextEpisodeDate,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }

  // Método fromJson actualizado
  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['id'] ?? _generateId(json['detailUrl']), // Genera ID si no existe
      title: json['title'],
      coverImageUrl: json['coverImageUrl'],
      detailUrl: json['detailUrl'],
      type: json['type'],
      year: json['year'],
      status: json['status'],
      synopsis: json['synopsis'] as String? ?? '',
      genres: List<String>.from(json['genres']),
      nextEpisodeDate: json['nextEpisodeDate'],
      episodes: List<Episode>.from(
          json['episodes'].map((e) => Episode.fromJson(e))),
    );
  }

  // Método de igualdad para comparar animes
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Anime &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
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

// lib/models/model_anime.dart

class VideoOption {
  final String optionName;
  final String url;
  final bool requiresConfirmation;

  VideoOption({
    required this.optionName,
    required this.url,
    this.requiresConfirmation = false,
  });

  Map<String, dynamic> toJson() => {
    'optionName': optionName,
    'url': url,
    'requiresConfirmation': requiresConfirmation,
  };

  factory VideoOption.fromJson(Map<String, dynamic> json) {
    return VideoOption(
      optionName: json['optionName'] ?? 'Opción Desconocida',
      url: json['url'] ?? '',
      requiresConfirmation: json['requiresConfirmation'] ?? false,
    );
  }
}