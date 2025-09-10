import 'package:flutter/material.dart';
import 'package:login_ui/components/header.dart';
import 'package:login_ui/pages/location.dart';
import 'package:login_ui/pages/users.dart'; 
import 'package:login_ui/pages/trash.dart'; 
import 'package:login_ui/pages/report.dart'; 

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 16, 
          mainAxisSpacing: 16,
          children: [
            _buildCard(context, Icons.person, 'Users'),
            _buildCard(context, Icons.location_on, 'Informasi TPS'),
            _buildCard(context, Icons.report_problem, 'Pengaduan TPS'),
            _buildCard(context, Icons.delete, 'Sampah'),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String label) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black, width: 3),
      ),
      child: InkWell(
        onTap: () {
          switch (label) {
            case 'Users':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersPage()),
              );
              break;
            case 'Informasi TPS':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationPage()),
              );
              break;
            case 'Pengaduan TPS':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportPage()),
              );
              break;
            case 'Sampah':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrashPage()),
              );
              break;
            default:
              debugPrint('Tapped on $label');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.indigo),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
