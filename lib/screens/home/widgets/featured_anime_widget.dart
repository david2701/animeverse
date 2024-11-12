import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../anime_detail_screen.dart';
import '../../../models/model_anime.dart';
import '../../../providers.dart';

class FeaturedAnimeWidget extends ConsumerWidget {
  const FeaturedAnimeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animeListAsyncValue = ref.watch(animeListProvider);

    return animeListAsyncValue.when(
      data: (animes) {
        if (animes.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

        final featured = animes.first;
        return SliverToBoxAdapter(
          child: Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => _navigateToDetail(context, ref, featured),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildBackgroundImage(featured),
                    _buildGradientOverlay(),
                    _buildContent(context, featured),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
    );
  }

  Widget _buildBackgroundImage(Anime anime) {
    return Hero(
      tag: 'featured-${anime.id}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(anime.coverImageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Anime anime) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            anime.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              shadows: [
                const Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black,
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTag(context, anime.type),
              const SizedBox(width: 8),
              _buildTag(context, anime.year),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, WidgetRef ref, Anime anime) {
    final userDataBox = ref.read(userDataBoxProvider);
    if (userDataBox != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnimeDetailScreen(
            anime: anime,
            userDataBox: userDataBox,
          ),
        ),
      );
    }
  }
}
