/// قواعد التحقق الموحّدة للتطبيق.
/// كلمة المرور: 6 أحرف بسيطة بلا تعقيد — مطابقة 100% لقاعدة الخادم
/// (security.php → validate_password).
class Validators {
  Validators._();

  /// كلمة المرور: 6 أحرف على الأقل، بدون شروط تعقيد.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  /// تأكيد كلمة المرور.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'يرجى تأكيد كلمة المرور';
    }
    if (value != original) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  /// حقل مطلوب عام.
  static String? required(String? value, [String field = 'هذا الحقل']) {
    if (value == null || value.trim().isEmpty) {
      return '$field مطلوب';
    }
    return null;
  }

  /// البريد الإلكتروني (اختياري الاستخدام).
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final re = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
    if (!re.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صالح';
    }
    return null;
  }

  /// رقم الهاتف (أرقام فقط، 6 خانات فأكثر).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    final digits = value.trim();
    if (!RegExp(r'^[0-9]{6,}$').hasMatch(digits)) {
      return 'رقم الهاتف غير صالح';
    }
    return null;
  }

  /// اسم المستخدم: 3 أحرف فأكثر (حروف/أرقام/شرطة سفلية) — مطابق للخادم.
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]{3,50}$').hasMatch(value.trim())) {
      return 'اسم المستخدم: 3-50 حرف (حروف/أرقام/شرطة سفلية)';
    }
    return null;
  }
}
