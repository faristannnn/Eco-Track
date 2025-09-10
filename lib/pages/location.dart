import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final String baseUrl = "https://express-production-c53f.up.railway.app/tps";

  List<dynamic> tpsList = [];
  bool isLoading = true;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  @override
  void initState() {
    super.initState();
    fetchTPS();
  }

  // 🔹 Ambil data TPS
  Future<void> fetchTPS() async {
    setState(() => isLoading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse(baseUrl),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        setState(() {
          tpsList = jsonDecode(res.body);
        });
      } else {
        debugPrint("Fetch failed: ${res.body}");
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
    setState(() => isLoading = false);
  }

  // 🔹 Tambah TPS
  Future<void> addTPS(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse("$baseUrl/add"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );
      if (res.statusCode == 201) {
        fetchTPS();
      } else {
        debugPrint("Add failed: ${res.body}");
      }
    } catch (e) {
      debugPrint("Add error: $e");
    }
  }

  // 🔹 Update TPS
  Future<void> updateTPS(String id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse("$baseUrl/update/$id"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        fetchTPS();
      } else {
        debugPrint("Update failed: ${res.body}");
      }
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  // 🔹 Delete TPS
  Future<void> deleteTPS(String id) async {
    try {
      final token = await _getToken();
      final res = await http.delete(
        Uri.parse("$baseUrl/delete/$id"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        fetchTPS();
      } else {
        debugPrint("Delete failed: ${res.body}");
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  // 🔹 Form tambah / edit
  void openForm({Map<String, dynamic>? existing}) {
    final namaCtrl = TextEditingController(text: existing?['nama'] ?? '');
    final alamatCtrl = TextEditingController(text: existing?['alamat'] ?? '');
    final latitudeCtrl =
        TextEditingController(text: existing?['latitude']?.toString() ?? '');
    final longitudeCtrl =
        TextEditingController(text: existing?['longitude']?.toString() ?? '');
    final kapasitasCtrl =
        TextEditingController(text: existing?['kapasitas']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? "Tambah TPS" : "Edit TPS"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: "Nama")),
              TextField(controller: alamatCtrl, decoration: const InputDecoration(labelText: "Alamat")),
              TextField(controller: latitudeCtrl, decoration: const InputDecoration(labelText: "Latitude"), keyboardType: TextInputType.number),
              TextField(controller: longitudeCtrl, decoration: const InputDecoration(labelText: "Longitude"), keyboardType: TextInputType.number),
              TextField(controller: kapasitasCtrl, decoration: const InputDecoration(labelText: "Kapasitas"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              final data = {
                "nama": namaCtrl.text,
                "alamat": alamatCtrl.text,
                "latitude": double.tryParse(latitudeCtrl.text) ?? 0,
                "longitude": double.tryParse(longitudeCtrl.text) ?? 0,
                "kapasitas": int.tryParse(kapasitasCtrl.text) ?? 0,
              };
              if (existing == null) {
                addTPS(data);
              } else {
                updateTPS(existing['_id'], data);
              }
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi TPS'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tpsList.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final tps = tpsList[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(tps['nama'] ?? ''),
                  subtitle: Text(
                    "Alamat: ${tps['alamat']}\n"
                    "Lat: ${tps['latitude']}, Lng: ${tps['longitude']}\n"
                    "Kapasitas: ${tps['kapasitas']}",
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        openForm(existing: tps);
                      } else if (value == 'delete') {
                        deleteTPS(tps['_id']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
