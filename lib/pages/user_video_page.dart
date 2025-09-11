import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class UserVideoPage extends StatefulWidget {
  const UserVideoPage({super.key});

  @override
  State<UserVideoPage> createState() => _UserVideoPageState();
}

class _UserVideoPageState extends State<UserVideoPage> {
  List<dynamic> _videos = [];

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _fetchVideos() async {
    try {
      const apiUrl = 'https://express-production-c53f.up.railway.app/video/video';
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _videos = json.decode(response.body);
        });
      }
    } catch (e) {
      _showSnackBar("Gagal memuat video", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }

  void _openVideo(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(videoUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Edukasi"), backgroundColor: Colors.blue),
      body: _videos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.video_library, color: Colors.blue),
                    title: Text(video['title'] ?? 'No Title'),
                    subtitle: Text(video['description'] ?? 'No Description'),
                    onTap: () {
                    final url = video['url'];
                    if (url != null && url.contains("youtube.com/watch")) {
                        _openVideo(context, url);
                    } else {
                        _showSnackBar("URL video tidak valid atau tidak didukung", Colors.orange);
                    }
                    }
                  ),
                );
              },
            ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerPage({super.key, required this.videoUrl});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId == null) {
      return const Scaffold(
        body: Center(child: Text("URL YouTube tidak valid")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Tonton Video")),
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(controller: _controller),
        builder: (context, player) {
          return Column(
            children: [
              player,
            ],
          );
        },
      ),
    );
  }
}
