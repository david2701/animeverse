// anime_user_data_service.dart
import 'package:hive/hive.dart';
import 'models/model_anime.dart';

enum AnimeUserStatus {
  none,
  favorite,
  watching,
  completed
}

class AnimeUserData {
  AnimeUserStatus status;
  Set<int> watchedEpisodes;
  DateTime lastUpdated;

  AnimeUserData({
    this.status = AnimeUserStatus.none,
    Set<int>? watchedEpisodes,
    DateTime? lastUpdated,
  }) :
        watchedEpisodes = watchedEpisodes ?? {},
        lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'status': status.index,
    'watchedEpisodes': watchedEpisodes.toList(),
    'lastUpdated': lastUpdated.millisecondsSinceEpoch,
  };

  factory AnimeUserData.fromJson(Map<String, dynamic> json) {
    return AnimeUserData(
      status: AnimeUserStatus.values[json['status'] ?? 0],
      watchedEpisodes: (json['watchedEpisodes'] as List?)
          ?.map((e) => e as int).toSet() ?? {},
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
          json['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}

class AnimeUserDataService {
  final Box _userDataBox;
  static const String userDataPrefix = 'userData_';

  AnimeUserDataService(this._userDataBox);

  String _getKey(String animeId) => '$userDataPrefix$animeId';

  Future<void> updateAnimeStatus(String animeId, AnimeUserStatus status) async {
    final userData = getUserData(animeId);
    userData.status = status;
    userData.lastUpdated = DateTime.now();
    await _userDataBox.put(_getKey(animeId), userData.toJson());
  }

  Future<void> toggleEpisodeWatched(String animeId, int episodeIndex) async {
    final userData = getUserData(animeId);
    if (userData.watchedEpisodes.contains(episodeIndex)) {
      userData.watchedEpisodes.remove(episodeIndex);
    } else {
      userData.watchedEpisodes.add(episodeIndex);
    }
    userData.lastUpdated = DateTime.now();
    await _userDataBox.put(_getKey(animeId), userData.toJson());
  }

  AnimeUserData getUserData(String animeId) {
    final data = _userDataBox.get(_getKey(animeId));
    if (data != null) {
      return AnimeUserData.fromJson(Map<String, dynamic>.from(data));
    }
    return AnimeUserData();
  }

  bool isEpisodeWatched(String animeId, int episodeIndex) {
    return getUserData(animeId).watchedEpisodes.contains(episodeIndex);
  }

  AnimeUserStatus getAnimeStatus(String animeId) {
    return getUserData(animeId).status;
  }
}