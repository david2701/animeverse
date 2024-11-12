import 'package:flutter/material.dart';
import 'model_anime.dart';
import 'video_player_screen.dart';

class EpisodeListScreen extends StatelessWidget {
  final List<Episode> episodes;

  const EpisodeListScreen({required this.episodes, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Episodes')),
      body: ListView.builder(
        itemCount: episodes.length,
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return ListTile(
            title: Text(episode.title),
            leading: Image.network(episode.thumbnailUrl),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VideoPlayerScreen(episode: episode)),
              );
            },
          );
        },
      ),
    );
  }
}
