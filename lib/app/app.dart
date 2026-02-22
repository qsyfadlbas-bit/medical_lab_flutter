import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/screens/landing/landing_screen.dart';
import 'package:medical_lab_flutter/screens/user/user_dashboard.dart';
import 'package:medical_lab_flutter/screens/admin/admin_dashboard.dart';
import 'package:medical_lab_flutter/screens/developer/developer_dashboard.dart';
import 'package:medical_lab_flutter/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:medical_lab_flutter/providers/auth_provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _isLoading = true;
  String? _userRole;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    final role = await AuthService.getUserRole();

    setState(() {
      _isLoggedIn = isLoggedIn;
      _userRole = role;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isLoggedIn) {
      return const LandingScreen();
    }

    switch (_userRole) {
      case 'ADMIN':
        return const AdminDashboard();
      case 'DEVELOPER':
        return const DeveloperDashboard();
      case 'USER':
      default:
        return const UserDashboard();
    }
  }
}
