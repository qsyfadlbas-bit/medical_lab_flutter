import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/models/user_model.dart';
import 'package:medical_lab_flutter/services/api_service.dart';

class UserProvider with ChangeNotifier {
  // ✅ استخدام الخدمة الجديدة
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

  // دالة لجلب جميع المستخدمين (للوحة تحكم الأدمن)
  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ التصحيح: نستخدم دالة get العامة بدلاً من getUsers
      final response = await _apiService.get('/users');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'];
          _users = list.map((e) => User.fromJson(e)).toList();
        }
      } else {
        _errorMessage = 'فشل تحميل القائمة';
      }
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث الملف الشخصي
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ نستخدم دالة put للتحديث
      final response = await _apiService.put('/users/profile', data);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          // تحديث البيانات محلياً
          _currentUser = User.fromJson(responseData['data']);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _errorMessage = 'فشل التحديث: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
