import 'package:animeverse/scraping_services.dart';
import 'package:flutter/material.dart';
import 'models/model_anime.dart';

class AnimeFetcherScreen extends StatefulWidget {
  @override
  _AnimeFetcherScreenState createState() => _AnimeFetcherScreenState();
}

class _AnimeFetcherScreenState extends State<AnimeFetcherScreen> {
  final TextEditingController _urlController = TextEditingController();
  final AnimeScraperService _scraperService = AnimeScraperService();
  Anime? _fetchedAnime;
  bool _isLoading = false;
  String? _errorMessage;

  void _fetchAnime() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa una URL.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fetchedAnime = null;
    });

    try {
      final anime = await _scraperService.fetchAnimeDetails(url);
      setState(() {
        _fetchedAnime = anime;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAnimeDetails() {
    if (_fetchedAnime == null) return Container();

    return Expanded(
      child: ListView(
        children: [
          Text(
            _fetchedAnime!.title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          // Puedes agregar más detalles del anime aquí
          SizedBox(height: 20),
          Text(
            'Episodios:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ..._fetchedAnime!.episodes.map((episode) => ListTile(
            title: Text(episode.title),
            subtitle: Text(episode.videoUrl),
          )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Anime Fetcher'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Ingrese la URL del Anime',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchAnime,
                child: _isLoading
                    ? CircularProgressIndicator(
                  color: Colors.white,
                )
                    : Text('Obtener Capítulos'),
              ),
              SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              if (_fetchedAnime != null) _buildAnimeDetails(),
            ],
          ),
        ));
  }
}
