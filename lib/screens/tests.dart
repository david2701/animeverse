// lib/screens/test_screen.dart

import 'package:flutter/material.dart';
import '../models/model_anime.dart';
import '../services/flv_anime_scraper_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final FLVAnimeScraperService _scraperService = FLVAnimeScraperService();

  List<Anime> _animeList = [];
  Anime? _selectedAnime;
  List<VideoOption> _videoOptions = [];
  String _statusMessage = '';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController(text: '1');
  final TextEditingController _detailUrlController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();

  bool _isLoading = false;

  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  Future<void> _getPopular() async {
    setState(() {
      _isLoading = true;
      _animeList.clear();
      _selectedAnime = null;
      _videoOptions.clear();
    });
    try {
      int page = int.tryParse(_pageController.text) ?? 1;
      _updateStatus('Fetching popular animes...');
      final animes = await _scraperService.getPopular(page: page);
      setState(() {
        _animeList = animes;
        _updateStatus('Fetched ${animes.length} animes.');
      });
    } catch (e) {
      _updateStatus('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getLatestUpdates() async {
    setState(() {
      _isLoading = true;
      _animeList.clear();
      _selectedAnime = null;
      _videoOptions.clear();
    });
    try {
      int page = int.tryParse(_pageController.text) ?? 1;
      _updateStatus('Fetching latest updates...');
      final animes = await _scraperService.getLatestUpdates(page: page);
      setState(() {
        _animeList = animes;
        _updateStatus('Fetched ${animes.length} animes.');
      });
    } catch (e) {
      _updateStatus('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchAnimes() async {
    setState(() {
      _isLoading = true;
      _animeList.clear();
      _selectedAnime = null;
      _videoOptions.clear();
    });
    try {
      int page = int.tryParse(_pageController.text) ?? 1;
      String query = _searchController.text.trim();
      if (query.isEmpty) {
        _updateStatus('Please enter a search query.');
        return;
      }
      _updateStatus('Searching for "$query"...');
      final animes = await _scraperService.searchAnimes(query, page: page);
      setState(() {
        _animeList = animes;
        _updateStatus('Found ${animes.length} animes.');
      });
    } catch (e) {
      _updateStatus('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getDetail() async {
    setState(() {
      _isLoading = true;
      _selectedAnime = null;
      _videoOptions.clear();
    });
    try {
      String url = _detailUrlController.text.trim();
      if (url.isEmpty) {
        _updateStatus('Please enter an anime detail URL.');
        return;
      }
      _updateStatus('Fetching anime details...');
      final anime = await _scraperService.getDetail(url);
      setState(() {
        _selectedAnime = anime;
        _updateStatus('Fetched details for "${anime.title}".');
      });
    } catch (e) {
      _updateStatus('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getVideoList() async {
    setState(() {
      _isLoading = true;
      _videoOptions.clear();
    });
    try {
      String url = _videoUrlController.text.trim();
      if (url.isEmpty) {
        _updateStatus('Please enter an episode URL.');
        return;
      }
      _updateStatus('Fetching video options...');
      final videos = await _scraperService.getVideoList(url);
      setState(() {
        _videoOptions = videos;
        _updateStatus('Fetched ${videos.length} video options.');
      });
    } catch (e) {
      _updateStatus('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAnimeList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _animeList.length,
        itemBuilder: (context, index) {
          final anime = _animeList[index];
          return ListTile(
            title: Text(anime.title),
            subtitle: Text(anime.detailUrl),
            onTap: () {
              _detailUrlController.text = anime.detailUrl;
              _getDetail();
            },
          );
        },
      ),
    );
  }

  Widget _buildAnimeDetails() {
    if (_selectedAnime == null) return SizedBox.shrink();

    return Expanded(
      child: ListView(
        children: [
          Text('Title: ${_selectedAnime!.title}', style: TextStyle(fontSize: 18)),
          Text('Type: ${_selectedAnime!.type}'),
          Text('Year: ${_selectedAnime!.year}'),
          Text('Status: ${_selectedAnime!.status}'),
          Text('Genres: ${_selectedAnime!.genres.join(', ')}'),
          Text('Synopsis: ${_selectedAnime!.synopsis}'),
          SizedBox(height: 10),
          Text('Episodes:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ..._selectedAnime!.episodes.map((ep) => ListTile(
            title: Text(ep.title),
            subtitle: Text(ep.videoUrl),
            onTap: () {
              _videoUrlController.text = ep.videoUrl;
              _getVideoList();
            },
          )),
        ],
      ),
    );
  }

  Widget _buildVideoOptions() {
    if (_videoOptions.isEmpty) return SizedBox.shrink();

    return Expanded(
      child: ListView(
        children: _videoOptions.map((vo) {
          return ListTile(
            title: Text(vo.optionName),
            subtitle: Text(vo.url),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _detailUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('FLVAnimeScraperService Test'),
        ),
        body: Column(
          children: [
            if (_statusMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.grey[300],
                child: Text(_statusMessage),
              ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pageController,
                      decoration: InputDecoration(labelText: 'Page'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _getPopular,
                    child: Text('Get Popular'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _getLatestUpdates,
                    child: Text('Get Latest'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(labelText: 'Search Query'),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _searchAnimes,
                    child: Text('Search'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                controller: _detailUrlController,
                decoration: InputDecoration(labelText: 'Anime Detail URL'),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _getDetail,
              child: Text('Get Detail'),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                controller: _videoUrlController,
                decoration: InputDecoration(labelText: 'Episode URL'),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _getVideoList,
              child: Text('Get Video List'),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _animeList.isNotEmpty
                  ? _buildAnimeList()
                  : _selectedAnime != null
                  ? _buildAnimeDetails()
                  : _videoOptions.isNotEmpty
                  ? _buildVideoOptions()
                  : Center(child: Text('No data')),
            ),
          ],
        ));
  }
}