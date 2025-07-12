import 'package:flutter/material.dart';
import 'package:login_ui/loginpage.dart';
import 'package:login_ui/pages/users.dart'; 

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  const CustomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Dashboard'),
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
              case 'courses':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Courses page belum tersedia')),
                );
                break;
              case 'logout':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Loginpage()),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'users',
              child: Text('Users'),
            ),
            const PopupMenuItem(
              value: 'courses',
              child: Text('Courses'),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
