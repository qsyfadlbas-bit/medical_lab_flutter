import 'package:medical_lab_flutter/utils/storage.dart';

class AuthService {
  static Future<bool> isLoggedIn() async {
    final token = await Storage.getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getUserRole() async {
    return await Storage.getUserRole();
  }

  static Future<void> clearAuthData() async {
    await Storage.clearAll();
  }

  static Future<String?> getToken() async {
    return await Storage.getToken();
  }

  static Future<String?> getUserData() async {
    return await Storage.getUserData();
  }

  static Future<void> saveAuthData({
    required String token,
    required String userData,
    required String role,
  }) async {
    await Storage.saveToken(token);
    await Storage.saveUserData(userData);
    await Storage.saveUserRole(role);
  }
}
