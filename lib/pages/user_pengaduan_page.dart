import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserPengaduanPage extends StatefulWidget {
  const UserPengaduanPage({super.key});

  @override
  State<UserPengaduanPage> createState() => _UserPengaduanPageState();
}

class _UserPengaduanPageState extends State<UserPengaduanPage> {
  List<dynamic> _pengaduan = [];
  List<dynamic> _tpsList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPengaduan();
    _fetchTps();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _fetchPengaduan() async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();
      if (token == null || userId == null) return;

      final apiUrl =
          'https://express-production-c53f.up.railway.app/service/user/$userId';
      final response = await http.get(Uri.parse(apiUrl),
          headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        setState(() {
          _pengaduan = json.decode(response.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchTps() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('https://express-production-c53f.up.railway.app/tps'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _tpsList = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Gagal ambil TPS: $e");
    }
  }

    Future<void> _showForm({Map? item}) async {
    final nameController =
        TextEditingController(text: item != null ? item['name'] : "");
    final deskripsiController =
        TextEditingController(text: item != null ? item['deskripsi'] : "");
    String? selectedTps = item?['tps']?['_id'] as String?;

    final userId = await _getUserId();
    final token = await _getToken();

    if (userId == null || token == null) return;

    showDialog(
        context: context,
        builder: (context) {
        return AlertDialog(
            title: Text(item == null ? "Tambah Pengaduan" : "Edit Pengaduan"),
            content: SingleChildScrollView(
            child: Column(
                children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Judul"),
                ),
                TextField(
                    controller: deskripsiController,
                    decoration: const InputDecoration(labelText: "Deskripsi"),
                ),
                DropdownButtonFormField<String>(
                    value: selectedTps,
                    items: _tpsList
                        .map<DropdownMenuItem<String>>((tps) => DropdownMenuItem(
                            value: tps['_id'],
                            child: Text(tps['nama']),
                            ))
                        .toList(),
                    onChanged: (val) => selectedTps = val,
                    decoration: const InputDecoration(labelText: "TPS"),
                ),
                ],
            ),
            ),
            actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal")),
            ElevatedButton(
                onPressed: () async {
                final body = jsonEncode({
                    "user": userId, 
                    "tps": selectedTps,
                    "name": nameController.text,
                    "deskripsi": deskripsiController.text,
                    "status": "diproses", 
                });

                final url = item == null
                    ? "https://express-production-c53f.up.railway.app/service/add"
                    : "https://express-production-c53f.up.railway.app/service/update/${item['_id']}";

                final response = await http.post(
                    Uri.parse(url),
                    headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token'
                    },
                    body: body,
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                    Navigator.pop(context);
                    _fetchPengaduan();
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(item == null
                            ? "Pengaduan berhasil ditambahkan"
                            : "Pengaduan berhasil diperbarui"),
                    ),
                    );
                } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal simpan pengaduan")),
                    );
                }
                },
                child: const Text("Simpan"),
            )
            ],
        );
        },
    );
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaduan TPS"),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pengaduan.isEmpty
              ? const Center(child: Text("Belum ada pengaduan"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _pengaduan.length,
                  itemBuilder: (context, i) {
                    final item = _pengaduan[i];
                    final user = item['user'];
                    final tps = item['tps'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.report_problem,
                            color: Colors.orange),
                        title: Text(item['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Deskripsi: ${item['deskripsi']}"),
                            if (tps != null)
                              Text("TPS: ${tps['nama']} - ${tps['alamat']}"),
                            Text("Pelapor: ${user['username']}"),
                          ],
                        ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                            if (item['status'].toLowerCase() == "diproses")
                            IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showForm(item: item),
                            ),
                            Chip(
                            label: Text(item['status']),
                            backgroundColor: () {
                                switch (item['status'].toLowerCase()) {
                                case "diproses":
                                    return Colors.orange;
                                case "ditolak":
                                    return Colors.red;
                                case "ditindak":
                                    return Colors.blue;
                                case "selesai":
                                    return Colors.green;
                                default:
                                    return Colors.grey;
                                }
                            }(),
                            labelStyle: const TextStyle(color: Colors.white),
                            ),
                        ],
                        ),

                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
