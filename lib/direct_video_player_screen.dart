import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';

class DirectVideoPlayerScreen extends StatefulWidget {
  final String videoPath; // Ruta local del video

  const DirectVideoPlayerScreen({required this.videoPath, Key? key}) : super(key: key);

  @override
  _DirectVideoPlayerScreenState createState() => _DirectVideoPlayerScreenState();
}

class _DirectVideoPlayerScreenState extends State<DirectVideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
    );
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    if (File(widget.videoPath).existsSync()) {
      File(widget.videoPath).deleteSync();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reproducción de Video'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Chewie(controller: _chewieController!),
      ),
    );
  }
}// TODO Implement this library.