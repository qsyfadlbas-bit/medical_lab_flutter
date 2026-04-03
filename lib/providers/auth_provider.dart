import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medical_lab_flutter/models/user_model.dart';
import 'package:medical_lab_flutter/services/api_service.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  // ═══════════════════════════════════════════════════════════════
  // ✅ دوال مساعدة جديدة لحماية من استجابات HTML
  // تحل مشكلة: FormatException: Unexpected character (at character 1) <DOCTYPE html>
  // ═══════════════════════════════════════════════════════════════

  /// فحص إذا كانت الاستجابة JSON أو HTML
  bool _isJsonResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    final body = response.body.trimLeft();

    // إذا الاستجابة تبدأ بـ HTML tag = ليست JSON
    if (body.startsWith('<') || body.startsWith('<!DOCTYPE')) {
      return false;
    }

    // إذا الـ Content-Type يحتوي على html = ليست JSON
    if (contentType.contains('text/html')) {
      return false;
    }

    return true;
  }

  /// تحليل استجابة السيرفر بأمان — لا يرمي Exception أبداً
  Map<String, dynamic>? _safeJsonDecode(http.Response response) {
    if (!_isJsonResponse(response)) {
      print("⚠️ السيرفر أرجع HTML بدلاً من JSON!");
      print("⚠️ Status: ${response.statusCode}");
      print(
          "⚠️ Body (أول 200 حرف): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}");
      return null;
    }

    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print("⚠️ فشل تحليل JSON: $e");
      return null;
    }
  }

  /// رسالة خطأ واضحة للمستخدم حسب كود الاستجابة
  String _getHtmlErrorMessage(int statusCode) {
    switch (statusCode) {
      case 403:
        return 'تم حظر الوصول من جدار الحماية. جرّب شبكة إنترنت مختلفة (WiFi) أو تواصل مع الدعم.';
      case 429:
        return 'طلبات كثيرة جداً. انتظر بضع دقائق وحاول مرة أخرى.';
      case 500:
        return 'خطأ داخلي في السيرفر. حاول مرة أخرى لاحقاً.';
      case 502:
      case 503:
        return 'السيرفر غير متاح مؤقتاً. حاول بعد قليل.';
      default:
        return 'استجابة غير متوقعة من السيرفر (كود: $statusCode). جرّب شبكة إنترنت مختلفة.';
    }
  }

  /// رسالة خطأ واضحة حسب نوع الاستثناء
  String _getExceptionMessage(dynamic e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('HandshakeException')) {
      return 'لا يوجد اتصال بالإنترنت. تحقق من شبكتك.';
    } else if (msg.contains('TimeoutException')) {
      return 'انتهت مهلة الاتصال. السيرفر بطيء، حاول مرة أخرى.';
    } else {
      return 'خطأ في الاتصال بالسيرفر. حاول مرة أخرى.';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // دالة التحقق من تسجيل الدخول التلقائي
  // ═══════════════════════════════════════════════════════════════

  Future<String?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      return null;
    }

    _token = prefs.getString('token');
    final role = prefs.getString('userRole');

    await fetchUserProfile();

    notifyListeners();
    return role;
  }

  // ═══════════════════════════════════════════════════════════════
  // جلب بيانات الملف الشخصي
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchUserProfile() async {
    if (_token == null) return;

    try {
      final response = await _apiService.get('/auth/profile');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ فحص آمن للاستجابة
        final body = _safeJsonDecode(response);
        if (body == null) {
          print("❌ Profile response was not JSON");
          return;
        }

        if (body['success'] == true && body['data'] != null) {
          _currentUser = User.fromJson(body['data']);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userName', _currentUser?.name ?? 'مستخدم');
          await prefs.setString('userRole', _currentUser?.role ?? 'USER');

          notifyListeners();
          print("✅ Profile Fetched Successfully: ${_currentUser?.name}");
        }
      } else {
        print("❌ Failed to fetch profile: Status ${response.statusCode}");
      }
    } catch (e) {
      print('❌ fetchUserProfile error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // تسجيل الدخول — مع حماية من استجابات HTML
  // ═══════════════════════════════════════════════════════════════

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

      // ✅ الإصلاح الرئيسي: فحص إذا الاستجابة HTML بدل JSON
      final body = _safeJsonDecode(response);
      if (body == null) {
        _errorMessage = _getHtmlErrorMessage(response.statusCode);
        return false;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];

          _token = data['token'];
          _currentUser = User.fromJson(data['user']);

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
      _errorMessage = _getExceptionMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // تسجيل حساب جديد — مع حماية من استجابات HTML
  // ═══════════════════════════════════════════════════════════════

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

      // ✅ الإصلاح الرئيسي: فحص إذا الاستجابة HTML بدل JSON
      final body = _safeJsonDecode(response);
      if (body == null) {
        _errorMessage = _getHtmlErrorMessage(response.statusCode);
        return false;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];

          _token = data['token'];
          _currentUser = User.fromJson(data['user']);

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
      _errorMessage = _getExceptionMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // تسجيل الخروج
  // ═══════════════════════════════════════════════════════════════

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}
