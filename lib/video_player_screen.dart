import 'package:flutter/material.dart';
import 'model_anime.dart';

class VideoPlayerScreen extends StatelessWidget {
  final Episode episode;

  const VideoPlayerScreen({required this.episode, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(episode.title)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text('Select a Video Option', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: episode.videoOptions.length,
                itemBuilder: (context, index) {
                  final option = episode.videoOptions[index];
                  return ListTile(
                    title: Text(option.optionName),
                    onTap: () {
                      // Aquí puedes agregar lógica para abrir el video en un reproductor o en un WebView
                      print('Selected video URL: ${option.url}');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
