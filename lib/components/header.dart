import 'package:flutter/material.dart';
import 'package:login_ui/loginpage.dart';
import 'package:login_ui/pages/education.dart';
import 'package:login_ui/pages/location.dart';
import 'package:login_ui/pages/report.dart';
import 'package:login_ui/pages/service.dart';
import 'package:login_ui/pages/trash.dart';
import 'package:login_ui/pages/users.dart';
import 'package:login_ui/pages/category.dart';
import 'package:login_ui/loginpage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  const CustomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (value) {
            switch (value) {
              case 'users':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersPage()),
                );
                break;
              case 'category':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryPage()),
                );
                break;
              case 'trash':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrashPage()),
                );
                break;
                case 'vidio':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EducationPage()),
                );
                break;
                case 'service':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ServicePage()),
                );
                break;
                case 'report':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportPage()),
                );
                break;
                case 'location':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationPage()),
                );
                break;
              case 'logout':
                _logout(context); 
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'users', child: Text('Users')),
            PopupMenuItem(value: 'category', child: Text('Kategori Sampah')),
            PopupMenuItem(value: 'trash', child: Text('Sampah')),
            PopupMenuItem(value: 'report', child: Text('Laporan Dinas')),
            PopupMenuItem(value: 'location', child: Text('TPS')),
            PopupMenuItem(value: 'vidio', child: Text('Education Vidio')),
            PopupMenuItem(value: 'service', child: Text('Layanan TPS')),
            PopupMenuItem(value: 'logout', child: Text('Logout')),
            
          ],
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


void _logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');

  if (token == null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Loginpage()),
    );
    return;
  }

  final url = Uri.parse('https://express-production-c53f.up.railway.app/logout');
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    debugPrint(data['message']); 

    await prefs.remove('accessToken');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Loginpage()),
    );
  } else {
    debugPrint('Logout gagal: ${response.body}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logout gagal')),
    );
  }
}