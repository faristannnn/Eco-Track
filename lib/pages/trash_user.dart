import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TrashUserPage extends StatefulWidget {
  const TrashUserPage({super.key});

  @override
  State<TrashUserPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashUserPage> {
  final String baseUrl = "https://express-production-c53f.up.railway.app";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<dynamic>> fetchTrash() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/sampah"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load sampah");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Sampah'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchTrash(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final trashList = snapshot.data!;
          if (trashList.isEmpty) {
            return const Center(child: Text("Tidak ada data sampah."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trashList.length,
            itemBuilder: (context, index) {
              final trash = trashList[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trash['name'] ?? '-',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("Deskripsi: ${trash['deskripsi'] ?? '-'}"),
                      Text("Kategori: ${trash['kategori']?['name'] ?? '-'}"),
                      Text("Satuan: ${trash['satuan'] ?? '-'}"),
                      Text("Harga: Rp${trash['harga']?.toString() ?? '-'}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
