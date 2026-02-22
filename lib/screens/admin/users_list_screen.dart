import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/services/api_service.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await _apiService.get('/users');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _users = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المستخدمين (${_users.length})',
            style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user['name'],
                        style: const TextStyle(
                            fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    subtitle: Text(user['email']),
                    trailing: Text(user['phone'] ?? '',
                        style: const TextStyle(fontSize: 12)),
                  ),
                );
              },
            ),
    );
  }
}
