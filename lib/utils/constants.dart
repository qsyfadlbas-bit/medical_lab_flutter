import 'package:flutter/material.dart'; // أضف هذا السطر

class AppConstants {
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

  // مسارات API
  static const String apiBaseUrl = 'http://localhost:3000/api';
  static const String apiTimeout = '30';

  // أنواع الفحوصات
  static const List<Map<String, String>> inspectionTypes = [
    {'value': 'PRE_PURCHASE', 'label': 'فحص ما قبل الشراء'},
    {'value': 'QUALITY', 'label': 'فحص الجودة'},
    {'value': 'SAFETY', 'label': 'فحص السلامة'},
    {'value': 'COMPLIANCE', 'label': 'فحص المطابقة'},
    {'value': 'TECHNICAL', 'label': 'فحص تقني'},
    {'value': 'PERIODIC', 'label': 'فحص دوري'},
    {'value': 'EMERGENCY', 'label': 'فحص طارئ'},
  ];

  // حالات الفحوصات
  static const List<Map<String, String>> inspectionStatuses = [
    {'value': 'PENDING', 'label': 'معلق', 'color': '0xFFF59E0B'},
    {'value': 'SCHEDULED', 'label': 'مجدول', 'color': '0xFF3B82F6'},
    {'value': 'IN_PROGRESS', 'label': 'قيد التنفيذ', 'color': '0xFF8B5CF6'},
    {'value': 'COMPLETED', 'label': 'مكتمل', 'color': '0xFF10B981'},
    {'value': 'CANCELLED', 'label': 'ملغى', 'color': '0xFF6B7280'},
    {'value': 'FAILED', 'label': 'فاشل', 'color': '0xFFEF4444'},
  ];

  // أدوار المستخدمين
  static const List<Map<String, String>> userRoles = [
    {'value': 'USER', 'label': 'مستخدم'},
    {'value': 'ADMIN', 'label': 'مدير'},
    {'value': 'DEVELOPER', 'label': 'مطور'},
    {'value': 'INSPECTOR', 'label': 'فاحص'},
  ];

  // إعدادات التطبيق
  static const String appName = 'مختبر الشفاء الطبية';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@medical-lab.com';
  static const String supportPhone = '+964 770 000 0000';
  static const String privacyPolicyUrl = 'https://medical-lab.com/privacy';
  static const String termsOfServiceUrl = 'https://medical-lab.com/terms';

  // رسائل التنبيه
  static const String networkError = 'خطأ في الاتصال بالشبكة';
  static const String serverError = 'حدث خطأ في السيرفر';
  static const String authError = 'خطأ في المصادقة';
  static const String sessionExpired =
      'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى';
  static const String noInternet = 'لا يوجد اتصال بالإنترنت';

  // رسائل النجاح
  static const String loginSuccess = 'تم تسجيل الدخول بنجاح';
  static const String registerSuccess = 'تم إنشاء الحساب بنجاح';
  static const String orderCreated = 'تم إنشاء الطلب بنجاح';
  static const String inspectionCreated = 'تم إنشاء الفحص بنجاح';
  static const String dataSaved = 'تم حفظ البيانات بنجاح';

  // قيم افتراضية
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
