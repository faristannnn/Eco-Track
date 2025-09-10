import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../loginpage.dart';
import '../model/tps_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_pengaduan_page.dart';
class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<dynamic> _layanan = [];

  @override
  void initState() {
    super.initState();
    _fetchTps();
    _fetchLayanan();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 🔹 Fetch TPS
  Future<void> _fetchTps() async {
    try {
      const apiUrl = 'https://express-production-c53f.up.railway.app/tps';
      final token = await _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        List<Marker> markers = [];

        for (var item in data) {
          final tps = Tps.fromJson(item);
          if (tps.latitude.abs() > 90 || tps.longitude.abs() > 180) continue;

          markers.add(
            Marker(
              point: LatLng(tps.latitude, tps.longitude),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showTpsDetail(tps),
                child: const Icon(Icons.location_on,
                    color: Colors.red, size: 40),
              ),
            ),
          );
        }

        setState(() => _markers = markers);
      }
    } catch (e) {
      _showSnack("Gagal memuat TPS", Colors.red);
    }
  }

  // 🔹 Fetch Layanan
  Future<void> _fetchLayanan() async {
    try {
      const apiUrl = 'https://express-production-c53f.up.railway.app/layanan';
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => _layanan = json.decode(response.body));
      }
    } catch (e) {
      _showSnack("Gagal memuat layanan", Colors.red);
    }
  }


  // 🔹 Search lokasi
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1");

    final response =
        await http.get(url, headers: {'User-Agent': 'flutter_app'});

    if (response.statusCode == 200) {
      final results = json.decode(response.body);
      if (results.isNotEmpty) {
        final lat = double.parse(results[0]['lat']);
        final lon = double.parse(results[0]['lon']);

        _mapController.move(LatLng(lat, lon), 16);

        setState(() {
          _markers.add(
            Marker(
              point: LatLng(lat, lon),
              width: 50,
              height: 50,
              child: const Icon(Icons.search, color: Colors.blue, size: 40),
            ),
          );
        });
      }
    }
  }

  // 🔹 Detail TPS
  void _showTpsDetail(Tps tps) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 5,
                width: 60,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              tps.nama,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.place, color: Colors.blue),
              title: Text(tps.alamat),
            ),
            ListTile(
              leading: const Icon(Icons.storage, color: Colors.green),
              title: Text("Kapasitas: ${tps.kapasitas}"),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _mapController.move(LatLng(tps.latitude, tps.longitude), 17);
              },
              icon: const Icon(Icons.map),
              label: const Text("Fokus ke lokasi"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Logout
  Future<void> _logout(BuildContext context) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        _showSnack("Token tidak ditemukan, login ulang", Colors.orange);
        return;
      }

      final response = await http.post(
        Uri.parse("https://express-production-c53f.up.railway.app/logout"),
        headers: {'Authorization': 'Bearer $token'},
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');

      if (response.statusCode == 200) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Loginpage()),
          (route) => false,
        );
      } else {
        _showSnack("Logout gagal", Colors.red);
      }
    } catch (e) {
      _showSnack("Error: $e", Colors.red);
    }
  }

  // 🔹 Helper snackbar
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              accountName: Text("Layanan TPS",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              accountEmail: Text("Daftar kontak & informasi TPS"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.recycling, color: Colors.blue, size: 40),
              ),
            ),
            Expanded(
              child: _layanan.isEmpty
                  ? const Center(
                      child: Text("Tidak ada data layanan",
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _layanan.length,
                      itemBuilder: (context, i) {
                        final item = _layanan[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.support_agent,
                                color: Colors.green),
                            title: Text(item['name']),
                            subtitle: Text(
                                "${item['region']} • ${item['type']} • ${item['phone'] ?? '-'}"),
                            trailing: Chip(
                              label: Text(item['status']),
                              backgroundColor: item['status'].toLowerCase() ==
                                      "aktif"
                                  ? Colors.green
                                  : Colors.red,
                              labelStyle:
                                  const TextStyle(color: Colors.white),
                            ),
                            onTap: () async {
                              if (item['phone'] != null &&
                                  item['phone'] != "") {
                                final Uri callUri =
                                    Uri(scheme: 'tel', path: item['phone']);
                                if (await canLaunchUrl(callUri)) {
                                  await launchUrl(callUri,
                                      mode: LaunchMode.externalApplication);
                                }
                              }
                            },
                          ),
                        );
                      }),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () => _logout(context),
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text("Pengaduan TPS"),
              onTap: () {
                Navigator.pop(context); 
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserPengaduanPage()),
                );
              },
            ),

          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("User Dashboard"),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(-6.954194, 107.607917),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            top: 20,
            left: 15,
            right: 15,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(10),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Cari lokasi...",
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) => _searchLocation(value),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchTps,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.refresh),
        label: const Text("Refresh TPS"),
      ),
    );
  }
}
