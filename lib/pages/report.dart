import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _PengaduanPageState();
}

class _PengaduanPageState extends State<ReportPage> {
  final String baseUrl = "https://express-production-c53f.up.railway.app/service";
  List<dynamic> reports = [];
  bool isLoading = true;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    setState(() => isLoading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse(baseUrl),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        setState(() {
          reports = jsonDecode(res.body);
        });
      } else {
        debugPrint("Fetch failed: ${res.body}");
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> deleteReport(String id) async {
    final token = await _getToken();
    final res = await http.delete(
      Uri.parse("$baseUrl/delete/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      fetchReports();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pengaduan berhasil dihapus")),
      );
    } else {
      debugPrint("Delete failed: ${res.body}");
    }
  }

  Future<void> updateStatus(String id, String status, String userId, String tpsId, String name, String deskripsi) async {
    final token = await _getToken();
    final body = {
      "user": userId,
      "tps": tpsId,
      "name": name,
      "deskripsi": deskripsi,
      "status": status
    };
    final res = await http.post(
      Uri.parse("$baseUrl/update/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      fetchReports();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status diubah ke $status")),
      );
    } else {
      debugPrint("Update failed: ${res.body}");
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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
  }

  void _showStatusSheet(Map<String, dynamic> item) {
    final userId = item['user']?['_id'];
    final tpsId = item['tps']?['_id'];
    final name = item['name'] ?? '';
    final deskripsi = item['deskripsi'] ?? '';

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Wrap(
          children: ["diproses", "ditolak", "ditindak", "selesai"]
              .map((status) => ListTile(
                    title: Text(status),
                    onTap: () {
                      Navigator.pop(context);
                      updateStatus(item['_id'], status, userId, tpsId, name, deskripsi);
                    },
                  ))
              .toList(),
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Pengaduan"),
        content: const Text("Yakin ingin menghapus pengaduan ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteReport(id);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaduan TPS'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = reports[index];
                final user = item['user'];
                final tps = item['tps'];
                return ListTile(
                  leading: const Icon(Icons.report),
                  title: Text(item['name'] ?? ''),
                  subtitle: Text(
                    "Deskripsi: ${item['deskripsi'] ?? '-'}\n"
                    "User: ${user?['username'] ?? '-'}\n"
                    "TPS: ${tps?['nama'] ?? '-'}",
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(item['status']),
                        backgroundColor: _statusColor(item['status']),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showStatusSheet(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(item['_id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
