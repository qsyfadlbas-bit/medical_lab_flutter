import 'dart:convert';

class User {
  final String id;
  final String username;
  final String email;
  final String name;
  final String? phone;
  final String? address; // ✅ 1. تم إضافة حقل العنوان هنا
  final String role; // ✅ هذا هو الحقل الأهم للتوجيه
  final DateTime createdAt;
  final DateTime? updatedAt;
  final UserProfile? profile;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    this.phone,
    this.address, // ✅ 2. تم إضافته للـ Constructor
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // 🛠️ إضافة للتتبع: طباعة الدور القادم من السيرفر في الكونسول
    print(
        "🔍 Parsing User Data -> Name: ${json['name']}, Role: ${json['role']}");

    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(), // ✅ 3. تم إضافته لقراءة الـ JSON

      // ✅ قراءة الدور، وإذا لم يوجد نعتبره مستخدماً عادياً
      role: json['role']?.toString() ?? 'USER',

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),

      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,

      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'])
          : null,
    );
  }
}

// كلاس الملف الشخصي (مبسط لتجنب الأخطاء)
class UserProfile {
  final String? bio;

  UserProfile({this.bio});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      bio: json['bio']?.toString(),
    );
  }
}
