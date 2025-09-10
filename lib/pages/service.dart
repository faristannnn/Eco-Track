import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final String baseUrl = "https://express-production-c53f.up.railway.app/layanan";

  List<dynamic> services = [];
  bool isLoading = true;

  // 🔑 ambil token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  // 🔹 Ambil data layanan
  Future<void> fetchServices() async {
    setState(() => isLoading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse(baseUrl),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        setState(() {
          services = jsonDecode(res.body);
        });
      } else {
        debugPrint("Fetch failed: ${res.body}");
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
    setState(() => isLoading = false);
  }

  // 🔹 Tambah layanan
  Future<void> addService(Map<String, dynamic> data) async {
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
        fetchServices();
      } else {
        debugPrint("Add failed: ${res.body}");
      }
    } catch (e) {
      debugPrint("Add error: $e");
    }
  }

  // 🔹 Update layanan
  Future<void> updateService(String id, Map<String, dynamic> data) async {
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
        fetchServices();
      } else {
        debugPrint("Update failed: ${res.body}");
      }
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  // 🔹 Delete layanan
  Future<void> deleteService(String id) async {
    try {
      final token = await _getToken();
      final res = await http.delete(
        Uri.parse("$baseUrl/delete/$id"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        fetchServices();
      } else {
        debugPrint("Delete failed: ${res.body}");
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  // 🔹 Form tambah / edit
  void openForm({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final regionCtrl = TextEditingController(text: existing?['region'] ?? '');
    final noteCtrl = TextEditingController(text: existing?['note'] ?? '');
    String typeValue = existing?['type'] ?? 'darurat';
    String statusValue = existing?['status'] ?? 'aktif';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? "Tambah Layanan" : "Edit Layanan"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone")),
              TextField(controller: regionCtrl, decoration: const InputDecoration(labelText: "Region")),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "Note")),
              DropdownButtonFormField<String>(
                value: typeValue,
                decoration: const InputDecoration(labelText: "Type"),
                items: const [
                  DropdownMenuItem(value: "darurat", child: Text("Darurat")),
                  DropdownMenuItem(value: "layanan", child: Text("Layanan")),
                ],
                onChanged: (val) => typeValue = val ?? 'darurat',
              ),
              if (existing != null) // status hanya saat update
                DropdownButtonFormField<String>(
                  value: statusValue,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: const [
                    DropdownMenuItem(value: "aktif", child: Text("Aktif")),
                    DropdownMenuItem(value: "tidak aktif", child: Text("Tidak Aktif")),
                  ],
                  onChanged: (val) => statusValue = val ?? 'aktif',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              final data = {
                "name": nameCtrl.text,
                "phone": phoneCtrl.text,
                "region": regionCtrl.text,
                "note": noteCtrl.text,
                "type": typeValue,
                "status": existing == null ? "aktif" : statusValue,
              };
              if (existing == null) {
                addService(data);
              } else {
                updateService(existing['_id'], data);
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
        title: const Text('Nomor Layanan'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final service = services[index];
                return ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(service['name'] ?? ''),
                  subtitle: Text(
                    "Phone: ${service['phone']}\n"
                    "Region: ${service['region']}\n"
                    "Note: ${service['note']}\n"
                    "Type: ${service['type']}\n"
                    "Status: ${service['status']}",
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        openForm(existing: service);
                      } else if (value == 'delete') {
                        deleteService(service['_id']);
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
