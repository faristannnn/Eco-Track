import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:login_ui/model/video_model.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<EducationPage> {
  List<Video> video = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVideo();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> fetchVideo() async {
    const apiUrl = 'https://express-production-c53f.up.railway.app/video/video';
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          video = data.map((json) => Video.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat video');
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> showVideoDialog({Video? vidio}) async {
    final titleController       = TextEditingController(text: vidio?.title ?? '');
    final descriptionController = TextEditingController(text: vidio?.description ?? '');
    final urlController         = TextEditingController(text: vidio?.url ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vidio == null ? 'Tambah Video Edukasi' : 'Edit Video Edukasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul Video'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi Video'),
            ),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL Video'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title       = titleController.text.trim();
              final description = descriptionController.text.trim();
              final url         = urlController.text.trim();

              if (title.isEmpty || description.isEmpty || url.isEmpty) return;

              vidio == null
                  ? await addVideo(title, description, url)
                  : await updateVideo(vidio.id, title, description, url);

              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }


  Future<void> addVideo(String title, String description, String url) async {
    const apiUrl = 'https://express-production-c53f.up.railway.app/video/video';
    final token = await _getToken();
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'url': url,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchVideo();
      } else {
        throw Exception('Gagal menambah video');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }


  Future<void> updateVideo(String id, String title, String description, String url) async {
    final apiUrl = 'https://express-production-c53f.up.railway.app/video/video/update/$id';
    final token = await _getToken();
    try {
      final response = await http.post( 
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'url': url,
        }),
      );

      if (response.statusCode == 200) {
        await fetchVideo();
      } else {
        throw Exception('Gagal update video');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }


  Future<void> deleteVideo(String id) async {
    final apiUrl = 'https://express-production-c53f.up.railway.app/video/video/delete/$id';
    final token = await _getToken();
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchVideo();
      } else {
        throw Exception('Gagal hapus video');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List video'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showVideoDialog(),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: video.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final vidio = video[index];
                return ListTile(
                  title: Text(vidio.title),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => showVideoDialog(vidio: vidio),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteVideo(vidio.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
