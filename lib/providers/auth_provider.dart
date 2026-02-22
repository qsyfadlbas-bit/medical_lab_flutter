import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medical_lab_flutter/models/user_model.dart';
import 'package:medical_lab_flutter/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ❌ حذفنا FlutterSecureStorage واستبدلناها بـ SharedPreferences داخل الدوال
  // final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  // ✅ دالة جديدة: التحقق من تسجيل الدخول التلقائي عند بدء التطبيق
  Future<String?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      return null;
    }

    _token = prefs.getString('token');
    final role = prefs.getString('userRole');
    final name = prefs.getString('userName');

    // إعادة بناء المستخدم بشكل مؤقت (يمكنك تحسينه بجلب البيانات من السيرفر لاحقاً)
    if (name != null && role != null) {
      // هنا نفترض وجود بيانات بسيطة، يمكنك تعديل User ليتناسب مع البيانات المحفوظة
      // _currentUser = User(name: name, role: role, ...);
    }

    notifyListeners();
    return role; // إرجاع الرول لتوجيه المستخدم
  }

  // تسجيل الدخول
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("🚀 Login Attempt: $username");

      final response = await _apiService.post('/auth/login', {
        'username': username,
        'password': password,
      });

      print("📡 Response Status: ${response.statusCode}");

      final Map<String, dynamic> body = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];

          _token = data['token'];
          _currentUser = User.fromJson(data['user']);

          // ✅ حفظ البيانات باستخدام SharedPreferences
          if (_token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', _token!);
            await prefs.setString('userRole', _currentUser?.role ?? 'USER');
            await prefs.setString('userName', _currentUser?.name ?? 'مستخدم');
          }

          print("✅ Login Success");
          return true;
        }
      }

      _errorMessage = body['error'] ?? body['message'] ?? 'فشل تسجيل الدخول';
      print("❌ Login Failed: $_errorMessage");
      return false;
    } catch (e) {
      print("❌ Login Exception: $e");
      _errorMessage = 'خطأ في الاتصال بالسيرفر';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تسجيل حساب جديد
  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String address,
    String? phone,
    String? adminCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("🚀 Register Attempt: $email");

      final response = await _apiService.post('/auth/register', {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
        'address': address,
        'adminCode': adminCode,
      });

      print("📡 Response Status: ${response.statusCode}");

      final Map<String, dynamic> body = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];

          _token = data['token'];
          _currentUser = User.fromJson(data['user']);

          // ✅ حفظ البيانات باستخدام SharedPreferences
          if (_token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', _token!);
            await prefs.setString('userRole', _currentUser?.role ?? 'USER');
            await prefs.setString('userName', _currentUser?.name ?? 'مستخدم');
          }

          print("✅ Register Success");
          return true;
        }
      }

      _errorMessage = body['error'] ?? body['message'] ?? 'فشل إنشاء الحساب';
      print("❌ Register Failed: $_errorMessage");
      return false;
    } catch (e) {
      print("❌ Register Exception: $e");
      _errorMessage = 'خطأ في الاتصال بالسيرفر';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    // ✅ مسح البيانات من SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    // يمكنك إضافة كود جلب الملف الشخصي هنا لاحقاً إذا احتجت لتحديث البيانات
  }
}
