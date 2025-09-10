import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> fetchUsers() async {
    const apiUrl = 'https://express-production-c53f.up.railway.app/user';
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          users = data.map((u) => {
                'id': u['_id'],
                'username': u['username'],
                'email': u['email'],
                'level': u['level'],
                'phone': u['phone'],
                'address': u['address'],
              }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat user');
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }


  void showUserDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text("Detail User", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text("Username: ${user['username']}"),
              Text("Email: ${user['email']}"),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
              )
            ],
          ),
        );
      },
    );
  }


  Future<void> showUserDialog({Map<String, dynamic>? user}) async {
    final nameController     = TextEditingController(text: user?['username'] ?? '');
    final emailController    = TextEditingController(text: user?['email'] ?? '');
    final passwordController = TextEditingController();
    final phoneController    = TextEditingController(text: user?['phone']?.toString() ?? '');
    final addressController  = TextEditingController(text: user?['address'] ?? '');

    // ✅ Tambahkan variabel ini
    String selectedLevel = user?['level'] ?? 'user';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(   // ✅ pakai StatefulBuilder supaya dropdown bisa berubah
        builder: (context, setState) {
          return AlertDialog(
            title: Text(user == null ? 'Tambah User' : 'Edit User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'petugas', child: Text('Petugas')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedLevel = value;  // ✅ update state lokal dialog
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();
                  final phone = phoneController.text.trim();
                  final address = addressController.text.trim();

                  if (name.isEmpty || email.isEmpty || (user == null && password.isEmpty)) {
                    return;
                  }

                  user == null
                      ? await addUser(name, email, password, phone, address, selectedLevel)
                      : await updateUser(user['id'], name, email, password, phone, address, selectedLevel);

                  Navigator.pop(context);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> addUser(String name, String email, String password,
      String phone, String address, String level) async {
    const apiUrl = 'https://express-production-c53f.up.railway.app/user/add';
    final token = await _getToken();
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': name,
          'email': email,
          'password': password,
          'phone': phone.isNotEmpty ? int.tryParse(phone) : null,
          'address': address,
          'level': level,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchUsers();
      } else {
        throw Exception('Gagal menambah user');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }


  Future<void> updateUser(String id, String name, String email, String password,
      String phone, String address, String level) async {
    final apiUrl = 'https://express-production-c53f.up.railway.app/user/update/$id';
    final token = await _getToken();
    try {
      final body = {
        'username': name,
        'email': email,
        'phone': phone.isNotEmpty ? int.tryParse(phone) : null,
        'address': address,
        'level': level,
      };
      if (password.isNotEmpty) body['password'] = password;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        await fetchUsers();
      } else {
        throw Exception('Gagal update user');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }


  Future<void> deleteUser(String id) async {
    final apiUrl = 'https://express-production-c53f.up.railway.app/user/delete/$id';
    final token = await _getToken();
    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchUsers();
      } else {
        throw Exception('Gagal hapus user');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List User'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showUserDialog(),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user['username'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${user['email'] ?? '-'}"),
                      Text("Phone: ${user['phone']?.toString() ?? '-'}"),
                      Text("Address: ${user['address'] ?? '-'}"),
                      Text("Level: ${user['level'] ?? '-'}"),
                    ],
                  ),
                  onTap: () => showUserDetail(user),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => showUserDialog(user: user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteUser(user['id'].toString()),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
