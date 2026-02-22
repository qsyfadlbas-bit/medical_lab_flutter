import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ 1. الرابط الثابت للسيرفر
  static const String baseUrl = 'https://medical-lab-backend.vercel.app/api';

  // ✅ دالة مساعدة لجلب الهيدر مع التوكن (تمنع تكرار الكود)
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // جلب التوكن من الذاكرة المحلية

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. دالة POST
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    print("🚀 POST Request to: $url");

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      print("✅ Response Status: ${response.statusCode}");
      return response;
    } catch (e) {
      print("❌ Connection Error: $e");
      rethrow;
    }
  }

  // 2. دالة GET
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    print("🚀 GET Request to: $url");

    try {
      final response = await http.get(
        url,
        headers: headers,
      );
      print("✅ GET Status: ${response.statusCode}");
      return response;
    } catch (e) {
      print("❌ GET Error: $e");
      rethrow;
    }
  }

  // 3. دالة PUT
  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    print("🔄 PUT Request to: $url");

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      print("✅ PUT Status: ${response.statusCode}");
      return response;
    } catch (e) {
      print("❌ PUT Error: $e");
      rethrow;
    }
  }

  // 4. دالة DELETE
  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    print("🗑️ DELETE Request to: $url");

    try {
      final response = await http.delete(
        url,
        headers: headers,
      );
      print("✅ DELETE Status: ${response.statusCode}");
      return response;
    } catch (e) {
      print("❌ DELETE Error: $e");
      rethrow;
    }
  }

  // ✅ 5. دالة PATCH
  Future<http.Response> patch(
      String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    print("🔧 PATCH Request to: $url");

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      print("✅ PATCH Status: ${response.statusCode}");
      return response;
    } catch (e) {
      print("❌ PATCH Error: $e");
      rethrow;
    }
  }
}
