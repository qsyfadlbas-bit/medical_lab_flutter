import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/models/user_model.dart';
import 'package:medical_lab_flutter/services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<User> _users = [];
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<User> get users => _users;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setCurrentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ✅ دالة لجلب جميع المستخدمين
  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/users');

      if (response.statusCode == 200) {
        // ✅ استخدام safeJsonDecode بدلاً من json.decode
        final data = ApiService.safeJsonDecode(response);
        if (data == null) {
          _errorMessage = ApiService.getErrorMessage(response);
          return;
        }

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          _users = list.map((e) => User.fromJson(e)).toList();
        }
      } else {
        _errorMessage = ApiService.getErrorMessage(response);
      }
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال بالسيرفر';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ دالة تحديث الملف الشخصي
  Future<bool> updateUserProfile(Map<String, dynamic> updateData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response =
          await _apiService.put('/auth/update-profile', updateData);

      // ✅ استخدام safeJsonDecode
      final responseData = ApiService.safeJsonDecode(response);
      if (responseData == null) {
        _errorMessage = ApiService.getErrorMessage(response);
        return false;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true && responseData['data'] != null) {
          _currentUser = User.fromJson(responseData['data']);
        }
        return true;
      } else {
        _errorMessage = responseData['error'] ??
            responseData['message'] ??
            'فشل تحديث البيانات';
        return false;
      }
    } catch (e) {
      print("Update Profile Error: $e");
      _errorMessage = 'خطأ في الاتصال بالسيرفر';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
