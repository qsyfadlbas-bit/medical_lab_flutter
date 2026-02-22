import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medical_lab_flutter/providers/auth_provider.dart';
import 'package:medical_lab_flutter/screens/auth/login_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.grey,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Divider(),
          _buildSettingItem(Icons.logout, 'تسجيل الخروج', () async {
            await authProvider.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => const LoginScreen(userType: 'User')),
              (route) => false,
            );
          }, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return Card(
      child: ListTile(
        leading:
            Icon(icon, color: isDestructive ? Colors.red : Colors.grey[700]),
        title: Text(title,
            style: TextStyle(
                fontFamily: 'Cairo',
                color: isDestructive ? Colors.red : Colors.black)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
