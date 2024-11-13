// lib/screens/home/widgets/anime_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../anime_detail_screen.dart';
import '../../../models/anime_status.dart';
import '../../../models/model_anime.dart';
import '../../../providers.dart';
import '../providers/home_providers.dart';

class AnimeCardWidget extends ConsumerStatefulWidget {
  final Anime anime;
  final bool isTablet;

  const AnimeCardWidget({
    Key? key,
    required this.anime,
    required this.isTablet,
  }) : super(key: key);

  @override
  ConsumerState<AnimeCardWidget> createState() => _AnimeCardWidgetState();
}

class _AnimeCardWidgetState extends ConsumerState<AnimeCardWidget> {
  @override
  Widget build(BuildContext context) {
    final animeStatus = ref.watch(animeStatusProvider(widget.anime.id));

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(context),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ajuste aquí
          children: [
            // Contenedor de imagen
            Expanded(
              flex: 65,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverImage(),
                  _buildGradientOverlay(),
                  if (animeStatus != AnimeStatus.none)
                    _buildStatusIcon(context, animeStatus),
                ],
              ),
            ),
            // Contenedor de información sin Expanded
            _buildCardInfo(context), // Ajuste aquí
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    return Hero(
      tag: 'anime-cover-${widget.anime.id}',
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(widget.anime.coverImageUrl),
            fit: BoxFit.cover,
            onError: (_, __) =>
            const AssetImage('assets/placeholder.png') as ImageProvider,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, AnimeStatus status) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: _buildIcon(status),
      ),
    );
  }

  Widget _buildIcon(AnimeStatus status) {
    switch (status) {
      case AnimeStatus.favorite:
        return const Icon(Icons.favorite, color: Colors.red, size: 16);
      case AnimeStatus.watching:
        return const Icon(Icons.remove_red_eye, color: Colors.blue, size: 16);
      case AnimeStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Ajuste aquí
        children: [
          Text(
            widget.anime.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.anime.genres.take(2).join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildTypeTag(context),
              const SizedBox(width: 6),
              Text(
                widget.anime.year,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.anime.type,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) async {
    final userDataBox = ref.read(userDataBoxProvider);
    if (userDataBox != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnimeDetailScreen(
            anime: widget.anime,
            userDataBox: userDataBox,
          ),
        ),
      );

      if (mounted) {
        ref.refresh(animeStatusProvider(widget.anime.id));
        ref.refresh(favoriteAnimesProvider);
      }
    }
  }
}
