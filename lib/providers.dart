// lib/providers/providers.dart
import 'package:animeverse/scraping_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/model_anime.dart';
import '../models/anime_status.dart';
import 'cache_services.dart';

// MARK: - Storage Providers
final userDataBoxProvider = StateProvider<Box?>((ref) => null);
final animeBoxProvider = StateProvider<Box?>((ref) => null);

// MARK: - Navigation Providers
final navigationIndexProvider = StateProvider<int>((ref) => 0);
final isSearchVisibleProvider = StateProvider<bool>((ref) => false);

// MARK: - Theme Provider
final darkModeProvider = StateProvider<bool>((ref) => false);

// MARK: - Pagination & Loading Providers
final currentPageProvider = StateProvider<int>((ref) => 1);
final isLoadingMoreProvider = StateProvider<bool>((ref) => false);
final hasMoreContentProvider = StateProvider<bool>((ref) => true);

// MARK: - Search & Filter Providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedGenresProvider = StateProvider<Set<String>>((ref) => {});
final selectedYearsProvider = StateProvider<Set<String>>((ref) => {});
final selectedTypesProvider = StateProvider<Set<String>>((ref) => {});
final selectedStatusProvider = StateProvider<Set<String>>((ref) => {});
final selectedSeasonProvider = StateProvider<Set<String>>((ref) => {});

// MARK: - Services Providers
final cacheServiceProvider = Provider<AnimeCacheService>((ref) {
  final animeBox = ref.watch(animeBoxProvider);
  if (animeBox == null) throw Exception('AnimeBox not initialized');
  return AnimeCacheService(animeBox, AnimeScraperService());
});

// MARK: - Anime List Providers
final animeListProvider =
    StateNotifierProvider<AnimeListNotifier, AsyncValue<List<Anime>>>((ref) {
  return AnimeListNotifier(ref);
});

class AnimeListNotifier extends StateNotifier<AsyncValue<List<Anime>>> {
  final Ref _ref;

  AnimeListNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadInitialAnimes();
  }

  Future<void> loadInitialAnimes() async {
    try {
      final cacheService = _ref.read(cacheServiceProvider);
      final animes = await cacheService.getOrUpdateAnimes();

      state = AsyncValue.data(animes);
      _ref.read(hasMoreContentProvider.notifier).state = animes.isNotEmpty;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMoreAnimes() async {
    if (_ref.read(isLoadingMoreProvider) || !_ref.read(hasMoreContentProvider))
      return;

    _ref.read(isLoadingMoreProvider.notifier).state = true;
    try {
      final currentPage = _ref.read(currentPageProvider);
      final cacheService = _ref.read(cacheServiceProvider);
      final newAnimes =
          await cacheService.getOrUpdateAnimes(page: currentPage + 1);

      if (newAnimes.isNotEmpty) {
        _ref.read(currentPageProvider.notifier).state = currentPage + 1;
        state.whenData((currentAnimes) {
          state = AsyncValue.data([...currentAnimes, ...newAnimes]);
        });
      } else {
        _ref.read(hasMoreContentProvider.notifier).state = false;
      }
    } catch (error) {
      debugPrint('Error loading more animes: $error');
    } finally {
      _ref.read(isLoadingMoreProvider.notifier).state = false;
    }
  }

  Future<void> refreshAnimes() async {
    try {
      final cacheService = _ref.read(cacheServiceProvider);
      await cacheService.clearCache();
      _ref.read(currentPageProvider.notifier).state = 1;
      _ref.read(hasMoreContentProvider.notifier).state = true;
      await loadInitialAnimes();
    } catch (error) {
      debugPrint('Error refreshing animes: $error');
    }
  }

  void filterAnimes() {
    state.whenData((animes) {
      final searchQuery = _ref.read(searchQueryProvider);
      final selectedGenres = _ref.read(selectedGenresProvider);
      final selectedYears = _ref.read(selectedYearsProvider);
      final selectedTypes = _ref.read(selectedTypesProvider);

      final filteredAnimes = animes.where((anime) {
        final matchesSearch = searchQuery.isEmpty ||
            anime.title.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesGenres = selectedGenres.isEmpty ||
            anime.genres.any((genre) => selectedGenres.contains(genre));
        final matchesYear =
            selectedYears.isEmpty || selectedYears.contains(anime.year);
        final matchesType =
            selectedTypes.isEmpty || selectedTypes.contains(anime.type);

        return matchesSearch && matchesGenres && matchesYear && matchesType;
      }).toList();

      state = AsyncValue.data(filteredAnimes);
    });
  }
}

// MARK: - Recent Animes Provider
final recentAnimesProvider = Provider<AsyncValue<List<Anime>>>((ref) {
  return ref.watch(animeListProvider).whenData(
        (animes) => animes.take(20).toList(),
      );
});

// MARK: - Anime Status Providers
final animeStatusProvider =
    Provider.family<AnimeStatus, String>((ref, animeId) {
  final box = ref.watch(userDataBoxProvider);
  if (box == null) return AnimeStatus.none;

  final userData = box.get('userData_$animeId');
  if (userData == null) return AnimeStatus.none;

  final status = userData['status'] as int?;
  if (status == null || status < 0 || status >= AnimeStatus.values.length) {
    return AnimeStatus.none;
  }

  return AnimeStatus.values[status];
});

final animeStatusNotifierProvider =
    StateNotifierProvider.family<AnimeStatusNotifier, AnimeStatus, String>(
  (ref, animeId) => AnimeStatusNotifier(ref, animeId),
);

class AnimeStatusNotifier extends StateNotifier<AnimeStatus> {
  final Ref _ref;
  final String _animeId;

  AnimeStatusNotifier(this._ref, this._animeId) : super(AnimeStatus.none) {
    _initializeStatus();
  }

  void _initializeStatus() {
    final box = _ref.read(userDataBoxProvider);
    if (box != null) {
      final userData = box.get('userData_$_animeId');
      if (userData != null) {
        state = AnimeStatus.values[userData['status'] ?? 0];
      }
    }
  }

  Future<void> updateStatus(AnimeStatus newStatus) async {
    final box = _ref.read(userDataBoxProvider);
    if (box != null) {
      await box.put('userData_$_animeId', {'status': newStatus.index});
      state = newStatus;

// Invalidar providers relacionados
      _ref.invalidate(animeStatusProvider(_animeId));
      _ref.invalidate(favoriteAnimesProvider);
    }
  }
}

// MARK: - Favorites & User Data Providers
final favoriteAnimesProvider =
    Provider<AsyncValue<Map<String, List<Anime>>>>((ref) {
  return ref.watch(animeListProvider).whenData((animes) {
    final box = ref.watch(userDataBoxProvider);
    if (box == null) return {'favorite': [], 'watching': [], 'completed': []};

    final Map<String, List<Anime>> organizedAnimes = {
      'favorite': [],
      'watching': [],
      'completed': [],
    };

    for (final anime in animes) {
      final userData = box.get('userData_${anime.id}');
      if (userData != null) {
        final status = userData['status'] as int;
        switch (status) {
          case 1:
            organizedAnimes['favorite']!.add(anime);
            break;
          case 2:
            organizedAnimes['watching']!.add(anime);
            break;
          case 3:
            organizedAnimes['completed']!.add(anime);
            break;
        }
      }
    }

    return organizedAnimes;
  });
});

// MARK: - User Stats Provider
final userStatsProvider = Provider<Map<String, int>>((ref) {
  final favoritesAsync = ref.watch(favoriteAnimesProvider);

  return favoritesAsync.when(
    data: (favorites) => {
      'totalFavorites': favorites['favorite']?.length ?? 0,
      'watching': favorites['watching']?.length ?? 0,
      'completed': favorites['completed']?.length ?? 0,
    },
    loading: () => {
      'totalFavorites': 0,
      'watching': 0,
      'completed': 0,
    },
    error: (_, __) => {
      'totalFavorites': 0,
      'watching': 0,
      'completed': 0,
    },
  );
});

// MARK: - Initialization
Future<void> initializeProviders(ProviderContainer container) async {
  final animeBox = await Hive.openBox('animeBox');
  final userDataBox = await Hive.openBox('userDataBox');

  container.read(animeBoxProvider.notifier).state = animeBox;
  container.read(userDataBoxProvider.notifier).state = userDataBox;
}
