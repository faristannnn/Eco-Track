import 'package:flutter/material.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  final List<Map<String, String>> dummyUsers = const [
    {'name': 'Willy Randika', 'email': 'willy@example.com'},
    {'name': 'Rina Putri', 'email': 'rina@example.com'},
    {'name': 'Doni Saputra', 'email': 'doni@example.com'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: dummyUsers.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final user = dummyUsers[index];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(user['name'] ?? ''),
            subtitle: Text(user['email'] ?? ''),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              debugPrint("Selected: ${user['name']}");
            },
          );
        },
      ),
    );
  }
}
