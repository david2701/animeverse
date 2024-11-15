// lib/providers/providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/model_anime.dart';
import '../models/anime_status.dart';
import '../scraping_services.dart';
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
final selectedGenresProvider = StateProvider<List<String>>((ref) => []);
final selectedYearsProvider = StateProvider<RangeValues?>((ref) => null);
final selectedTypesProvider = StateProvider<List<String>>((ref) => []);
final selectedStatusProvider = StateProvider<String?>((ref) => null);
final selectedSortOrderProvider = StateProvider<String?>((ref) => null);

// Provider para agrupar todos los filtros
final filtersProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'genres': ref.watch(selectedGenresProvider),
    'types': ref.watch(selectedTypesProvider),
    'yearRange': ref.watch(selectedYearsProvider),
    'status': ref.watch(selectedStatusProvider),
    'sortOrder': ref.watch(selectedSortOrderProvider),
    'searchQuery': ref.watch(searchQueryProvider),
  };
});

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
    _initialize();
  }

  void _initialize() {
    // Escuchar cambios en los filtros
    _ref.listen<Map<String, dynamic>>(filtersProvider, (previous, next) {
      _applyFilters();
    });
    loadInitialAnimes();
  }

  List<Anime> _allAnimes = [];

  Future<void> loadInitialAnimes() async {
    try {
      final cacheService = _ref.read(cacheServiceProvider);
      final animes = await cacheService.getOrUpdateAnimes();

      _allAnimes = animes;
      state = AsyncValue.data(animes);
      _ref.read(hasMoreContentProvider.notifier).state = animes.isNotEmpty;

      _applyFilters();
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
        _allAnimes.addAll(newAnimes);
        _applyFilters();
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
      _allAnimes.clear();
      await loadInitialAnimes();
    } catch (error) {
      debugPrint('Error refreshing animes: $error');
    }
  }

  void _applyFilters() {
    final filters = _ref.read(filtersProvider);

    List<Anime> filteredAnimes = _allAnimes;

    // Filtrar por géneros
    final List<String> selectedGenres = filters['genres'] as List<String>;
    if (selectedGenres.isNotEmpty) {
      filteredAnimes = filteredAnimes.where((Anime anime) {
        return anime.genres.any((String genre) => selectedGenres.contains(genre));
      }).toList();
    }

    // Filtrar por tipos
    final List<String> selectedTypes = filters['types'] as List<String>;
    if (selectedTypes.isNotEmpty) {
      filteredAnimes = filteredAnimes.where((Anime anime) {
        return selectedTypes.contains(anime.type);
      }).toList();
    }

    // Filtrar por años
    final RangeValues? selectedYears = filters['yearRange'] as RangeValues?;
    if (selectedYears != null) {
      final int startYear = selectedYears.start.toInt();
      final int endYear = selectedYears.end.toInt();
      filteredAnimes = filteredAnimes.where((Anime anime) {
        final int? year = int.tryParse(anime.year);
        if (year == null) return false; // O decide cómo manejar los años no válidos
        return year >= startYear && year <= endYear;
      }).toList();
    }

    // Ordenar si es necesario
    final String? selectedSortOrder = filters['sortOrder'] as String?;
    if (selectedSortOrder != null) {
      if (selectedSortOrder == 'recent') {
        filteredAnimes.sort((Anime a, Anime b) {
          final int yearA = int.tryParse(a.year) ?? 0;
          final int yearB = int.tryParse(b.year) ?? 0;
          return yearB.compareTo(yearA);
        });
      } else if (selectedSortOrder == '-recent') {
        filteredAnimes.sort((Anime a, Anime b) {
          final int yearA = int.tryParse(a.year) ?? 0;
          final int yearB = int.tryParse(b.year) ?? 0;
          return yearA.compareTo(yearB);
        });
      }
    }

    // Filtrar por estado
    final String? selectedStatus = filters['status'] as String?;
    if (selectedStatus != null) {
      filteredAnimes = filteredAnimes.where((Anime anime) {
        return anime.status == selectedStatus;
      }).toList();
    }

    // Filtrar por búsqueda
    final String searchQuery = filters['searchQuery'] as String;
    if (searchQuery.isNotEmpty) {
      filteredAnimes = filteredAnimes.where((Anime anime) {
        return anime.title.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    state = AsyncValue.data(filteredAnimes);
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
