import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
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

  Future<List<dynamic>> fetchKategori() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/kategori"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load kategori");
    }
  }

  Future<void> addTrash(Map<String, dynamic> data) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/sampah/add"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Failed to add sampah");
    }
    setState(() {});
  }

  Future<void> updateTrash(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/sampah/update/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to update sampah");
    }
    setState(() {});
  }

  Future<void> deleteTrash(String id) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/sampah/delete/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to delete sampah");
    }
    setState(() {});
  }

  void showForm({Map<String, dynamic>? trash}) async {
    final nameController = TextEditingController(text: trash?['name']);
    final satuanController = TextEditingController(text: trash?['satuan']);
    final hargaController =
        TextEditingController(text: trash?['harga']?.toString());
    final deskripsiController =
        TextEditingController(text: trash?['deskripsi']);
    String? kategoriId = trash?['kategori']?['_id'];

    final kategoriList = await fetchKategori();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(trash == null ? "Tambah Sampah" : "Edit Sampah"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nama"),
                ),
                DropdownButtonFormField<String>(
                  value: kategoriId,
                  decoration: const InputDecoration(labelText: "Kategori"),
                  items: kategoriList.map<DropdownMenuItem<String>>((k) {
                    return DropdownMenuItem<String>(
                      value: k['_id'],
                      child: Text(k['name']),
                    );
                  }).toList(),
                  onChanged: (val) => kategoriId = val,
                ),
                TextField(
                  controller: satuanController,
                  decoration: const InputDecoration(labelText: "Satuan"),
                ),
                TextField(
                  controller: hargaController,
                  decoration: const InputDecoration(labelText: "Harga"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: deskripsiController,
                  decoration: const InputDecoration(labelText: "Deskripsi"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  "name": nameController.text,
                  "kategori": kategoriId,
                  "satuan": satuanController.text,
                  "harga": int.tryParse(hargaController.text) ?? 0,
                  "deskripsi": deskripsiController.text,
                };

                if (trash == null) {
                  await addTrash(data);
                } else {
                  await updateTrash(trash['_id'], data);
                }
                Navigator.pop(context);
              },
              child: Text(trash == null ? "Tambah" : "Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Sampah'),
        centerTitle: true,
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
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trashList.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final trash = trashList[index];
              return ListTile(
                leading: const Icon(Icons.delete),
                title: Text(trash['name'] ?? ''),
                subtitle: Text(
                  "${trash['deskripsi'] ?? ''}\nKategori: ${trash['kategori']?['name'] ?? '-'}",
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      showForm(trash: trash);
                    } else if (value == 'delete') {
                      deleteTrash(trash['_id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
