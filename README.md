# flutter_application_2

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# 📱 تطبيق Flutter - نظام مختبر الشفاء الطبية

تطبيق Flutter كامل لنظام إدارة الفحوصات الطبية مع دعم ثلاثة أنواع من المستخدمين.

## ✨ المميزات

### 🔐 نظام المصادقة المتقدم
- تسجيل دخول متعدد المستخدمين
- JWT Authentication
- إدارة الجلسات
- 2FA (قيد التطوير)

### 📊 لوحات التحكم
1. **لوحة المستخدم العادي** (4 تبويبات):
   - الرئيسية (إحصائيات، إجراءات سريعة)
   - الطلبات (عرض، إنشاء، متابعة)
   - الفحوصات (طلب، متابعة، تقارير)
   - الملف الشخصي (تعديل، إعدادات)

2. **لوحة الإدارة** (شاشة متكاملة):
   - إحصائيات النظام
   - إدارة الطلبات
   - إدارة المستخدمين
   - إدارة الفحوصات
   - التقارير والإحصائيات

3. **لوحة المطورين**:
   - مراقبة أداء النظام
   - سجلات النظام
   - إدارة API
   - إعدادات البيئة

### 🔍 نظام الفحوصات المتكامل
- طلب فحوصات جديدة
- جدولة مواعيد الفحص
- رفع التقارير والصور
- التوقيع الإلكتروني
- متابعة حالة الفحص

## 🚀 البدء السريع

### المتطلبات الأساسية
- Flutter 3.0 أو أعلى
- Dart 3.0 أو أعلى
- Android Studio / VS Code
- Node.js 18+ (لخادم API)

### خطوات التركيب

```bash
# 1. استنساخ المشروع
git clone <repository-url>
cd medical_lab_flutter

# 2. تثبيت التبعيات
flutter pub get

# 3. تشغيل خادم API (Next.js)
# افتح نافذة طرفية جديدة
cd ../medical-lab-system
npm install
npx prisma db push
npm run dev

# 4. تشغيل تطبيق Flutter
flutter run