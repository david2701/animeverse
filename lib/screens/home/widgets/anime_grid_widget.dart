// lib/screens/home/widgets/anime_grid_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/model_anime.dart';
import '../../../providers.dart';
import 'anime_card_widget.dart';

class AnimeGridWidget extends ConsumerWidget {
  const AnimeGridWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animeListAsyncValue = ref.watch(animeListProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedGenres = ref.watch(selectedGenresProvider);
    final isLoadingMore = ref.watch(isLoadingMoreProvider);
    final hasMoreContent = ref.watch(hasMoreContentProvider);
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo is ScrollEndNotification) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.7) {
            if (!isLoadingMore && hasMoreContent) {
              ref.read(animeListProvider.notifier).loadMoreAnimes();
            }
          }
        }
        return true;
      },
      child: animeListAsyncValue.when(
        data: (animes) => _buildGrid(
          context,
          animes,
          searchQuery,
          selectedGenres,
          isLoadingMore,
          hasMoreContent,
          isTablet,
        ),
        loading: () => _buildLoadingGrid(isTablet),
        error: (error, stack) => _buildError(context, error, ref),
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context,
      List<Anime> animes,
      String searchQuery,
      Set<String> selectedGenres,
      bool isLoadingMore,
      bool hasMoreContent,
      bool isTablet,
      ) {
    if (animes.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(context),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _calculateCrossAxisCount(context),
              childAspectRatio: 0.7,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: animes.length,
            itemBuilder: (context, index) {
              return AnimeCardWidget(
                anime: animes[index],
                isTablet: isTablet,
              );
            },
          ),
          if (isLoadingMore)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (!hasMoreContent && animes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No hay más contenido disponible',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos de búsqueda',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid(bool isTablet) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 4 : 2,
          childAspectRatio: 0.7,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) => _buildShimmerCard(context),
          childCount: 8,
        ),
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          height: 12,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error, WidgetRef ref) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ocurrió un error al cargar los animes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(animeListProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar de nuevo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;      // Pantallas muy grandes
    if (width > 900) return 5;       // Tablets grandes/Desktop
    if (width > 600) return 4;       // Tablets
    if (width > 400) return 3;       // Teléfonos en landscape
    return 2;                        // Teléfonos en portrait
  }
}