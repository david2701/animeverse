import 'package:animeverse/scraping_services.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/model_anime.dart';
import 'video_player_screen.dart';

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

class AnimeDetailScreen extends StatefulWidget {
  final Anime anime;
  final Box userDataBox;

  const AnimeDetailScreen({
    required this.anime,
    required this.userDataBox,
    Key? key,
  }) : super(key: key);

  @override
  _AnimeDetailScreenState createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  bool _isLoading = false;
  late Anime _anime;
  late AnimeUserData _userData;
  final String _userDataPrefix = 'userData_';

  @override
  void initState() {
    super.initState();
    _anime = widget.anime;
    _loadUserData();
    _fetchAnimeDetails();
  }

  void _loadUserData() {
    final data = widget.userDataBox.get('$_userDataPrefix${_anime.id}');
    if (data != null) {
      _userData = AnimeUserData.fromJson(Map<String, dynamic>.from(data));
    } else {
      _userData = AnimeUserData();
    }
  }

  Future<void> _saveUserData() async {
    await widget.userDataBox.put(
      '$_userDataPrefix${_anime.id}',
      _userData.toJson(),
    );
  }

  Future<void> _fetchAnimeDetails() async {
    setState(() => _isLoading = true);
    try {
      final scraperService = AnimeScraperService();
      final fetchedAnime = await scraperService.fetchAnimeDetails(_anime.detailUrl);
      setState(() {
        _anime = _anime.copyWith(
          title: fetchedAnime.title,
          coverImageUrl: fetchedAnime.coverImageUrl.isNotEmpty
              ? fetchedAnime.coverImageUrl
              : _anime.coverImageUrl,
          type: fetchedAnime.type,
          year: fetchedAnime.year,
          status: fetchedAnime.status,
          genres: fetchedAnime.genres,
          nextEpisodeDate: fetchedAnime.nextEpisodeDate,
          episodes: fetchedAnime.episodes,
        );
      });
    } catch (e) {
      print('Error fetching anime details: $e');
      _showErrorSnackBar('Error loading anime details');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeroHeader(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatusButtons(),
                _buildAnimeInfo(),
              ],
            ),
          ),
          _buildEpisodesList(),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return SliverAppBar(
      expandedHeight: 400.0,
      pinned: true,
      flexibleSpace: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: 'anime-cover-${_anime.id}',
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _anime.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.8),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _anime.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMetaTags(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaTags() {
    return Wrap(
      spacing: 8,
      children: [
        _buildMetaTag(
          icon: Icons.new_releases,
          label: _anime.status,
          color: _getStatusColor(_anime.status),
        ),
        _buildMetaTag(
          icon: Icons.calendar_today,
          label: _anime.year,
          color: Colors.blue,
        ),
        _buildMetaTag(
          icon: Icons.movie,
          label: _anime.type,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetaTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'upcoming':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusButton(
            status: AnimeUserStatus.favorite,
            icon: Icons.favorite,
            label: 'Favorite',
            color: Colors.red,
          ),
          _buildStatusButton(
            status: AnimeUserStatus.watching,
            icon: Icons.remove_red_eye,
            label: 'Watching',
            color: Colors.blue,
          ),
          _buildStatusButton(
            status: AnimeUserStatus.completed,
            icon: Icons.check_circle,
            label: 'Completed',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required AnimeUserStatus status,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _userData.status == status;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          setState(() {
            _userData.status = isSelected ? AnimeUserStatus.none : status;
            _userData.lastUpdated = DateTime.now();
          });
          await _saveUserData();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimeInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(),
          const SizedBox(height: 16),
          _buildGenres(),
          if (_anime.nextEpisodeDate != null) ...[
            const SizedBox(height: 16),
            _buildNextEpisodeInfo(),
          ],
          const SizedBox(height: 24),
          _buildEpisodesHeader(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final watchedCount = _userData.watchedEpisodes.length;
    final totalEpisodes = _anime.episodes.length;
    final progress = totalEpisodes > 0 ? (watchedCount / totalEpisodes) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$watchedCount/$totalEpisodes Episodes',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildGenres() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _anime.genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            genre,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextEpisodeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.access_time, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Episode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _anime.nextEpisodeDate ?? 'TBA',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Episodes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${_anime.episodes.length} total',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodesList() {
    if (_anime.episodes.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No episodes available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final episode = _anime.episodes[index];
          final isWatched = _userData.watchedEpisodes.contains(index);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              onTap: () => _onEpisodeTap(episode, index),
              child: Container(
                decoration: BoxDecoration(
                  color: isWatched ? Colors.grey.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              episode.thumbnailUrl,
                              width: 120,
                              height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                height: 68,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          if (isWatched)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'EP ${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        episode.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isWatched ? Colors.grey : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isWatched
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: isWatched ? Colors.green : Colors.grey,
                            ),
                            onPressed: () => _toggleEpisodeWatched(index),
                          ),
                          const Icon(Icons.play_circle_outline, size: 28),
                        ],
                      ),
                    ),
                    if (_userData.status == AnimeUserStatus.watching &&
                        !isWatched &&
                        _isNextUnwatchedEpisode(index))
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEXT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: _anime.episodes.length,
      ),
    );
  }

  bool _isNextUnwatchedEpisode(int index) {
    for (int i = 0; i < index; i++) {
      if (!_userData.watchedEpisodes.contains(i)) {
        return false;
      }
    }
    return !_userData.watchedEpisodes.contains(index);
  }

  Future<void> _toggleEpisodeWatched(int index) async {
    setState(() {
      if (_userData.watchedEpisodes.contains(index)) {
        _userData.watchedEpisodes.remove(index);
      } else {
        _userData.watchedEpisodes.add(index);
      }
      _userData.lastUpdated = DateTime.now();
    });
    await _saveUserData();

    // Si todos los episodios están vistos, sugerir marcar como completado
    if (_userData.status == AnimeUserStatus.watching &&
        _userData.watchedEpisodes.length == _anime.episodes.length) {
      _showMarkAsCompletedDialog();
    }
  }

  void _showMarkAsCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed?'),
        content: const Text(
            'You have watched all episodes. Would you like to mark this anime as completed?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _userData.status = AnimeUserStatus.completed;
                _userData.lastUpdated = DateTime.now();
              });
              await _saveUserData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as completed!')),
                );
              }
            },
            child: const Text('YES'),
          ),
        ],
      ),
    );
  }

  Future<void> _onEpisodeTap(Episode episode, int index) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final scraperService = AnimeScraperService();
      await scraperService.fetchVideoOptionsForEpisode(episode);
      if (mounted) {
        Navigator.pop(context);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(episode: episode),
          ),
        );

        // Si el resultado es true, marcamos el episodio como visto
        if (result == true && mounted) {
          await _toggleEpisodeWatched(index);
        }
      }
    } catch (e) {
      print('Error fetching video options: $e');
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Error fetching video options');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}