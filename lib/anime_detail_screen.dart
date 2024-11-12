import 'package:flutter/material.dart';
import 'model_anime.dart';
import 'video_player_screen.dart';

class AnimeDetailScreen extends StatefulWidget {
  final Anime anime;

  const AnimeDetailScreen({required this.anime, Key? key}) : super(key: key);

  @override
  _AnimeDetailScreenState createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildAnimeInfo(),
          ),
          _buildEpisodesList(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.anime.title,
          style: const TextStyle(
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.anime.coverImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error cargando imagen de portada: $error');
                return Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.image_not_supported, size: 100, color: Colors.white),
                );
              },
            ),
            // Gradiente oscuro para mejorar la legibilidad del título
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            _buildPopupMenuItem('favorite', 'Add to Favorites', Icons.favorite),
            _buildPopupMenuItem('watching', 'Mark as Watching', Icons.remove_red_eye),
            _buildPopupMenuItem('completed', 'Mark as Completed', Icons.check_circle),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, String text, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildAnimeInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Year', widget.anime.year),
          _buildInfoRow('Type', widget.anime.type),
          _buildInfoRow('Status', widget.anime.status),
          const SizedBox(height: 12),
          _buildGenres(),
          const SizedBox(height: 16),
          if (widget.anime.nextEpisodeDate != null)
            _buildNextEpisodeInfo(),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _buildEpisodesHeader(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGenres() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.anime.genres.map((genre) {
        return Chip(
          label: Text(genre),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextEpisodeInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Próximo episodio: ${widget.anime.nextEpisodeDate}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Episodes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${widget.anime.episodes.length} total',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList() {
    if (widget.anime.episodes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay episodios disponibles',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final episode = widget.anime.episodes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.all(8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  episode.thumbnailUrl,
                  width: 80,
                  height: 45,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error cargando thumbnail del episodio: $error');
                    return Container(
                      width: 80,
                      height: 45,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
              ),
              title: Text(
                episode.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.play_circle_outline),
              onTap: () => _onEpisodeTap(episode),
            ),
          );
        },
        childCount: widget.anime.episodes.length,
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'favorite':
        _showSnackBar('Agregado a Favoritos');
        break;
      case 'watching':
        _showSnackBar('Marcado como Viendo');
        break;
      case 'completed':
        _showSnackBar('Marcado como Completado');
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _onEpisodeTap(Episode episode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(episode: episode),
      ),
    );
  }
}