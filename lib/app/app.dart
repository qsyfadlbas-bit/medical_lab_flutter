import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medical_lab_flutter/providers/auth_provider.dart';

// استيراد الشاشات الأساسية
import 'package:medical_lab_flutter/screens/landing/landing_screen.dart';
import 'package:medical_lab_flutter/screens/home/home_screen.dart';
import 'package:medical_lab_flutter/screens/admin/admin_dashboard.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = await authProvider.tryAutoLogin();

    if (mounted) {
      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. شاشة التحميل أثناء فحص التوكن
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. إذا لم يكن هناك دور (Role)، نأخذه لشاشة البداية
    if (_userRole == null) {
      return const LandingScreen();
    }

    // 3. توجيه المستخدم حسب دوره الحقيقي
    if (_userRole == 'ADMIN') {
      return const AdminDashboard();
    } else {
      // ✅ الإصلاح: استخدام ResponsiveHomeScreen بدل HomeScreen
      return const HomeScreen();
    }
  }
}
