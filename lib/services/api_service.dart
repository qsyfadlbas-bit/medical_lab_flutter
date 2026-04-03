import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ═══════════════════════════════════════════════════════════════
  // الرابط الثابت للسيرفر — مكان واحد فقط لتغييره
  // ═══════════════════════════════════════════════════════════════
  static const String baseUrl = 'https://labapp3.alqadateam.com/api';

  // مهلة الاتصال — لمنع تعليق الطلبات للأبد
  static const Duration _timeout = Duration(seconds: 15);

  // ═══════════════════════════════════════════════════════════════
  // ✅ دوال مركزية لحماية json.decode من استجابات HTML
  // استخدمها في كل مكان بدلاً من json.decode مباشرة
  // ═══════════════════════════════════════════════════════════════

  /// فحص إذا كانت الاستجابة JSON فعلاً (وليست HTML من جدار حماية)
  static bool isJsonResponse(http.Response response) {
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
  /// استخدمها في كل مكان بدلاً من json.decode(response.body)
  ///
  /// مثال الاستخدام:
  /// ```dart
  /// final body = ApiService.safeJsonDecode(response);
  /// if (body == null) {
  ///   // السيرفر أرجع HTML — اعرض رسالة خطأ مناسبة
  ///   return;
  /// }
  /// // استخدم body بأمان...
  /// ```
  static Map<String, dynamic>? safeJsonDecode(http.Response response) {
    if (!isJsonResponse(response)) {
      print("⚠️ السيرفر أرجع HTML بدلاً من JSON!");
      print("⚠️ Status: ${response.statusCode}");
      print(
          "⚠️ Body snippet: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}");
      return null;
    }

    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      // في حال كانت الاستجابة JSON لكن ليست Map (مثلاً List مباشرة)
      return {'data': decoded};
    } catch (e) {
      print("⚠️ فشل تحليل JSON: $e");
      return null;
    }
  }

  /// رسالة خطأ واضحة للمستخدم حسب نوع الاستجابة
  static String getErrorMessage(http.Response response) {
    // إذا الاستجابة JSON، حاول قراءة رسالة الخطأ من السيرفر
    final body = safeJsonDecode(response);
    if (body != null) {
      return body['error']?.toString() ??
          body['message']?.toString() ??
          'خطأ غير معروف (كود: ${response.statusCode})';
    }

    // إذا الاستجابة HTML — رسالة حسب كود الحالة
    switch (response.statusCode) {
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
        return 'استجابة غير متوقعة من السيرفر (كود: ${response.statusCode}). جرّب شبكة إنترنت مختلفة.';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // دالة مساعدة لجلب الهيدر مع التوكن
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // دوال HTTP الأساسية
  // ═══════════════════════════════════════════════════════════════

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    print("🚀 POST Request to: $url");
    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(_timeout);
      print("✅ Response Status: ${response.statusCode}");
      return response;
    } catch (e) {
      print("❌ Connection Error: $e");
      rethrow;
    }
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    print("🚀 GET Request to: $url");
    try {
      final response = await http.get(url, headers: headers).timeout(_timeout);
      print("✅ GET Status: ${response.statusCode}");
      return response;
    } catch (e) {
      print("❌ GET Error: $e");
      rethrow;
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    print("🔄 PUT Request to: $url");
    try {
      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(_timeout);
      print("✅ PUT Status: ${response.statusCode}");
      return response;
    } catch (e) {
      print("❌ PUT Error: $e");
      rethrow;
    }
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    print("🗑️ DELETE Request to: $url");
    try {
      final response =
          await http.delete(url, headers: headers).timeout(_timeout);
      print("✅ DELETE Status: ${response.statusCode}");
      return response;
    } catch (e) {
      print("❌ DELETE Error: $e");
      rethrow;
    }
  }

  Future<http.Response> patch(
      String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    print("🔧 PATCH Request to: $url");
    try {
      final response = await http
          .patch(url, headers: headers, body: jsonEncode(data))
          .timeout(_timeout);
      print("✅ PATCH Status: ${response.statusCode}");
      return response;
    } catch (e) {
      print("❌ PATCH Error: $e");
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ دالة اقتراح التحاليل بالذكاء الاصطناعي
  // ═══════════════════════════════════════════════════════════════

  Future<http.Response> suggestTests(String symptoms) async {
    return post('/symptoms/suggest', {'symptoms': symptoms});
  }
}
