import 'package:flutter/material.dart';

class AppConstants {
  // ✅ الرابط الحقيقي والوحيد للتطبيق
  static const String apiBaseUrl = 'https://labapp3.alqadateam.com/api';
  static const String apiTimeout = '30';

  // ✅ الأدوار المطابقة لقاعدة البيانات 100%
  static const String roleUser = 'USER';
  static const String roleAdmin = 'ADMIN';

  // أدوار المستخدمين (تم تنظيفها من الأدوار الوهمية)
  static const List<Map<String, String>> userRoles = [
    {'value': roleUser, 'label': 'مستخدم'},
    {'value': roleAdmin, 'label': 'مدير'},
  ];

  // ألوان التطبيق
  static const Color primaryColor = Color(0xFF1E40AF);
  static const Color secondaryColor = Color(0xFF7C3AED);
  static const Color accentColor = Color(0xFFDB2777);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // أبعاد التصميم
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius = 8.0;

  // إعدادات التطبيق (تم تحديث الاسم إلى مختبر القمة)
  static const String appName = 'مختبر القمة الطبي';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@medical-lab.com';
  static const String supportPhone = '+964 770 000 0000';
  static const String privacyPolicyUrl = 'https://medical-lab.com/privacy';
  static const String termsOfServiceUrl = 'https://medical-lab.com/terms';

  // رسائل الأخطاء العامة
  static const String networkError = 'يرجى التحقق من اتصال الإنترنت';
  static const String serverError = 'حدث خطأ في الاتصال بالسيرفر';
  static const String authError = 'خطأ في المصادقة';
  static const String sessionExpired =
      'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى';
  static const String noInternet = 'لا يوجد اتصال بالإنترنت';

  // رسائل النجاح
  static const String loginSuccess = 'تم تسجيل الدخول بنجاح';
  static const String registerSuccess = 'تم إنشاء الحساب بنجاح';
  static const String orderCreated = 'تم إنشاء الطلب بنجاح';
  static const String dataSaved = 'تم حفظ البيانات بنجاح';

  // قيم افتراضية للصور والملفات
  static const int defaultPageSize = 10;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/jpg',
  ];
  static const List<String> allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ];
}
