import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medical_lab_flutter/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medical_lab_flutter/services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ----------------------
// 1. الموديل (المنطق)
// ----------------------

class MedicalTest {
  final String id;
  final String nameAr;
  final String nameEn;
  final String code;
  final int price;
  final String category;
  final String descriptionAr;
  final String descriptionEn;
  final List<String> keywords;

  MedicalTest({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.code,
    required this.price,
    required this.category,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.keywords,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'code': code,
      'price': price,
      'category': category,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'keywords': keywords,
    };
  }
}

class CartItem {
  final MedicalTest test;
  int quantity;

  CartItem({required this.test, required this.quantity});

  Map<String, dynamic> toJson() {
    return {
      'testId': test.id,
      'testName': test.nameEn,
      'price': test.price,
      'quantity': quantity,
    };
  }
}

// ----------------------
// فئة موديل الطلب (Order)
// ----------------------
// ----------------------
// فئة موديل الطلب (Order) - نسخة محسنة لـ Firebase
// ----------------------
class Order {
  final String id;
  final String orderNumber;
  final DateTime date;
  final List<CartItem> items;
  final num totalAmount;
  final String status;
  final String paymentMethod;
  final String patientName;
  final String phone;

  Order({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    // ✅ أضف هذين السطرين في البناء (Constructor):
    required this.patientName,
    required this.phone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime parseDate() {
      try {
        if (json['createdAt'] != null) return DateTime.parse(json['createdAt']);
        if (json['date'] != null) return DateTime.parse(json['date']);
        return DateTime.now();
      } catch (e) {
        return DateTime.now();
      }
    }

    List<CartItem> parseItems() {
      try {
        if (json['items'] == null) return [];
        return (json['items'] as List).map((item) {
          return CartItem(
            test: MedicalTest(
              id: item['testId'] ?? item['id'] ?? '',
              nameAr: item['nameAr'] ?? '',
              nameEn: item['testName'] ?? item['nameEn'] ?? 'تحليل',
              code: item['code'] ?? '',
              price: (item['price'] ?? 0).toInt(),
              category: '',
              descriptionAr: '',
              descriptionEn: '',
              keywords: [],
            ),
            quantity: item['quantity'] ?? 1,
          );
        }).toList();
      } catch (e) {
        return [];
      }
    }

    return Order(
      id: json['id'] ?? json['_id'] ?? '',
      orderNumber: json['orderNumber'] ?? 'N/A',
      date: parseDate(),
      items: parseItems(),
      totalAmount: json['totalAmount'] ?? 0,
      status: json['status'] ?? 'PENDING',
      paymentMethod: json['paymentMethod'] ?? 'cash',

      // ✅ أضف هذين السطرين لقراءة البيانات من السيرفر:
      patientName: json['patientName'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? suggestedTestCodes;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedTestCodes,
  });
}

class LabAppModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // بيانات المستخدم
  bool _isArabic = true;
  String _userName = '';
  String _userPhone = '';
  String _userEmail = '';
  String _userAddress = '';

  // القوائم
  List<Order> _orders = [];
  final List<CartItem> _cart = [];
  List<ChatMessage> _chatMessages = [];

  // القائمة الديناميكية للتحاليل (تأتي من الباك إند)
  List<MedicalTest> _allTests = [];

  // حالات التحميل
  bool _isSubmitting = false;
  bool _isAiThinking = false;
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  // ✅ 1. متغير التحكم بالإشعارات (افتراضياً مفعل)
  bool _notificationsEnabled = true;

  // Getters
  bool get isArabic => _isArabic;
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get userEmail => _userEmail;
  String get userAddress => _userAddress;
  List<Order> get orders => _orders;
  List<CartItem> get cart => _cart;
  bool get isSubmitting => _isSubmitting;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isAiThinking => _isAiThinking;
  bool get notificationsEnabled => _notificationsEnabled;

  // ✅ 2. إلغاء الوضع الليلي نهائياً (دائماً يرجع false)
  bool get isDark => false;

  // دالة تغيير الثيم (فارغة لأننا لغينا الوضع الليلي)
  void toggleTheme() {
    // لا تفعل شيئاً، التطبيق دائماً نهاري
    notifyListeners();
  }

  // دالة تفعيل/تعطيل الإشعارات
  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  // إرجاع كل التحاليل
  List<MedicalTest> get allTests => _allTests;

  // ✅ الفلترة (تعتمد على _allTests الديناميكية)
  List<MedicalTest> get filteredTests {
    // تصفية التحاليل فقط (استبعاد العروض من قائمة التصفح العامة)
    final testsOnly = _allTests.where((t) => t.category != 'عروض').toList();

    if (_selectedCategory == 'الكل') {
      return testsOnly
          .where((test) =>
              test.nameAr.contains(_searchQuery) ||
              test.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    } else {
      return testsOnly
          .where((test) => test.category == _selectedCategory)
          .where((test) =>
              test.nameAr.contains(_searchQuery) ||
              test.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  // ✅ جلب العروض فقط (من الباك إند)
  List<MedicalTest> get offers {
    return _allTests.where((t) => t.category == 'عروض').toList();
  }

  List<String> get categories => [
        'الكل',
        'فحوصات الدم',
        'الكيمياء الحيوية',
        'فايروسات',
        'مناعة',
        'البكتيريا',
        'الهرمونات',
        'الفيتامينات',
        'وظائف الأعضاء',
        'أخرى'
      ];

  get _aiBaseUrl => null;
  get _aiApiKey => null;

  void toggleLanguage() {
    _isArabic = !_isArabic;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // ✅ دالة تحميل البيانات عند بدء التطبيق
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _isArabic = prefs.getBool('isArabic') ?? true;

    String? storedName = await _storage.read(key: 'userName');
    if (storedName != null) _userName = storedName;

    await fetchUserProfile();
    await fetchMyOrders();
    await fetchTests(); // ✅ جلب التحاليل من السيرفر

    notifyListeners();
  }

  // ✅ دالة جلب التحاليل من السيرفر
  Future<void> fetchTests() async {
    try {
      final response = await _apiService.get('/tests');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'];

        _allTests = data.map((json) {
          return MedicalTest(
            id: json['_id'] ?? json['id'] ?? '',
            nameAr: json['nameAr'] ?? '',
            nameEn: json['nameEn'] ?? '',
            code: json['code'] ?? '',
            price: (json['price'] ?? 0).toInt(),
            category: json['category'] ?? 'أخرى',
            descriptionAr: json['descriptionAr'] ?? '',
            descriptionEn: json['descriptionEn'] ?? '',
            keywords: List<String>.from(json['keywords'] ?? []),
          );
        }).toList();

        notifyListeners();
      }
    } catch (e) {
      print("Error fetching tests: $e");
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await _apiService.get('/auth/profile');
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'];
        _userName = data['name'] ?? data['username'] ?? 'مستخدم';
        _userPhone = data['phone'] ?? '';
        _userEmail = data['email'] ?? '';
        _userAddress = data['address'] ?? '';
        await _storage.write(key: 'userName', value: _userName);
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  Future<void> fetchMyOrders() async {
    try {
      final response = await _apiService.get('/orders');
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'] ?? body;
        final allOrders = data.map((json) => Order.fromJson(json)).toList();

        // الفلترة حسب رقم الهاتف واسم المستخدم
        _orders = allOrders.where((order) {
          String orderPhone = order.phone.replaceAll(' ', '');
          String myPhone = _userPhone.replaceAll(' ', '');
          bool matchPhone = orderPhone == myPhone && myPhone.isNotEmpty;
          bool matchName =
              order.patientName == _userName && _userName.isNotEmpty;
          return matchPhone || matchName;
        }).toList();

        _orders.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }
    } catch (e) {
      print("Error in fetchMyOrders: $e");
    }
  }

  Future<bool> submitOrderToBackend(String paymentMethod,
      {String? location}) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      // التأكد من وجود توكن قبل الإرسال
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('token')) {
        print("❌ Error: No token found. User needs to login.");
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      final orderData = {
        "patientName": _userName,
        "phone": _userPhone,
        "address": _userAddress,
        "location": location,
        "items": _cart.map((e) => e.toJson()).toList(),
        "totalAmount": getCartTotalPrice(), // السعر بدون زيادات
        "paymentMethod": paymentMethod,
        "status": "PENDING",
        "date": DateTime.now().toIso8601String(),
      };

      print("🚀 Sending Order..."); // تتبع
      final response = await _apiService.post('/orders', orderData);

      print("📡 Order Response Status: ${response.statusCode}"); // تتبع

      _isSubmitting = false;
      notifyListeners();

      if (response.statusCode == 201 || response.statusCode == 200) {
        clearCart();
        await fetchMyOrders();
        return true;
      } else {
        print("❌ Server Error: ${response.body}"); // طباعة سبب الرفض من السيرفر
        return false;
      }
    } catch (e) {
      print("❌ Exception: $e");
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(
      {required String name,
      required String phone,
      required String email,
      required String address}) async {
    try {
      final response = await _apiService.put('/auth/update-profile',
          {'name': name, 'phone': phone, 'email': email, 'address': address});
      if (response.statusCode == 200) {
        _userName = name;
        _userPhone = phone;
        _userEmail = email;
        _userAddress = address;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _userName = '';
    _orders = [];
    _cart.clear();
    notifyListeners();
  }

  void addToCart(MedicalTest test) {
    final index = _cart.indexWhere((item) => item.test.id == test.id);
    if (index >= 0) {
      _cart[index].quantity++;
    } else {
      _cart.add(CartItem(test: test, quantity: 1));
    }
    notifyListeners();
  }

  void removeFromCart(MedicalTest test) {
    final index = _cart.indexWhere((item) => item.test.id == test.id);
    if (index >= 0) {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  int getCartTotalPrice() {
    return _cart.fold(
        0, (sum, item) => sum + (item.test.price * item.quantity));
  }

  void askAIAssistant(String question) async {
    _chatMessages.add(
        ChatMessage(text: question, isUser: true, timestamp: DateTime.now()));
    _isAiThinking = true;
    notifyListeners();
    try {
      final aiResponse = await _getRealAIResponse(question);
      _chatMessages.add(ChatMessage(
          text: aiResponse['response'],
          isUser: false,
          timestamp: DateTime.now(),
          suggestedTestCodes: aiResponse['suggestedTests']));
    } catch (e) {
      final localResponse = _generateLocalResponse(question);
      _chatMessages.add(ChatMessage(
          text: localResponse['response'],
          isUser: false,
          timestamp: DateTime.now(),
          suggestedTestCodes: localResponse['suggestedTests']));
    }
    _isAiThinking = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _getRealAIResponse(String question) async {
    return await _callOpenAI(question);
  }

  Future<Map<String, dynamic>> _callOpenAI(String question) async {
    throw Exception('Not Implemented');
  }

  Map<String, dynamic> _generateLocalResponse(String question) {
    return {
      'response': 'نصحك بزيارة الطبيب',
      'suggestedTests': ['CBC001']
    };
  }

  void clearChat() {
    _chatMessages.clear();
    notifyListeners();
  }
}

// ----------------------
// 4. شاشة سجل الطلبات (تعرض طلبات المستخدم السابقة)
// ----------------------

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? LabTheme.darkBackground
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('سجل طلباتي', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: LabTheme.primaryColor,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false, // لأنها في الناف بار
      ),
      body: Consumer<LabAppModel>(
        builder: (context, appModel, child) {
          if (appModel.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    "لا توجد طلبات سابقة",
                    style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // تحديث البيانات يدوياً
                      appModel.fetchMyOrders();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LabTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("تحديث",
                        style: TextStyle(
                            color: Colors.white, fontFamily: 'Cairo')),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => appModel.fetchMyOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appModel.orders.length,
              itemBuilder: (context, index) {
                final order = appModel.orders[index];
                return _buildOrderCard(context, order);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor;
    String statusText;

    switch (order.status.toUpperCase()) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
        break;
      case 'PROCESSING':
        statusColor = Colors.blue;
        statusText = 'قيد التنفيذ';
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        statusText = 'مكتمل';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = 'ملغي';
        break;
      default:
        statusColor = Colors.grey;
        statusText = order.status;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: isDark ? const Color(0xFF2D3250) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "طلب #${order.orderNumber}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "${order.date.year}-${order.date.month}-${order.date.day}",
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "${order.date.hour}:${order.date.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // عرض عدد العناصر
            Row(
              children: [
                const Icon(Icons.medical_services_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "${order.items.length} فحوصات",
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      fontFamily: 'Cairo',
                      fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // عرض السعر الكلي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "المجموع الكلي:",
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white60 : Colors.grey[600]),
                ),
                Text(
                  "${order.totalAmount} د.ع",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: LabTheme.primaryColor,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------
// شاشة حسابي (تشمل الملف الشخصي + معلومات المختبر)
// ----------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ✅ تم تحديث البيانات: حذف المعلومات القديمة واعتماد المدراء الجدد
  // ملاحظة: سنقوم بكتابة الأسماء مباشرة في الـ Widget لسهولة الترتيب

  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<LabAppModel>(context);
    const bool isDark = false; // الوضع النهاري

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text("حسابي", style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LabTheme.primaryGradient,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. كارت المعلومات المختصر (للمستخدم)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: LabTheme.cardDecoration(context),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: LabTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.person,
                        size: 40, color: LabTheme.primaryColor),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appModel.userName.isNotEmpty
                            ? appModel.userName
                            : "مستخدم",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Colors.black,
                        ),
                      ),
                      const Text(
                        "أهلاً بك في مختبر القمة",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. إعدادات التطبيق
            const Text(
              "إعدادات التطبيق",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 10),

            _buildSettingsTile(
              icon: Icons.notifications_active,
              color: Colors.teal,
              title: "الإشعارات",
              subtitle: "تلقي تنبيهات حول حالة الطلب",
              isDark: isDark,
              trailing: Switch(
                value: appModel.notificationsEnabled,
                activeColor: Colors.teal,
                onChanged: (val) {
                  appModel.toggleNotifications(val);
                },
              ),
            ),

            _buildSettingsTile(
              icon: Icons.logout,
              color: Colors.red,
              title: "تسجيل الخروج",
              subtitle: "الخروج من الحساب الحالي",
              isDark: isDark,
              onTap: () async {
                _showLogoutDialog(context, appModel);
              },
            ),

            const Divider(height: 40, thickness: 1),

            // 4. قسم "عن المختبر" (البيانات الجديدة)
            const Text(
              "إدارة المختبر",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LabTheme.primaryColor,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 15),

            // ✅ بطاقة الإدارة الجديدة (مجتبى وحسين)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: LabTheme.cardDecoration(context),
              child: Column(
                children: [
                  // الاسم الأول
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings,
                          color: Colors.blue),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          "مجتبى علي محمد",
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(),
                  ),
                  // الاسم الثاني
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings,
                          color: Colors.indigo),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          "حسين علي حنظل",
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // ✅ معلومات التواصل والموقع الجديدة
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LabTheme.primaryGradient,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: LabTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  // الموقع الجديد
                  _buildContactRow(
                    Icons.location_on,
                    "العراق، البصرة، بريهة، شارع مستشفى النور، بناية الضمان الصحي",
                  ),
                  const SizedBox(height: 15),

                  // الأرقام (تمت إضافة الرقم الثاني)
                  _buildContactRow(
                    Icons.phone,
                    "07762666185  |  07840206070",
                  ),
                  const SizedBox(height: 15),

                  // أوقات الدوام الجديدة
                  _buildContactRow(
                    Icons.access_time_filled,
                    "أوقات الدوام:\nكل الأيام: 3:00 عصراً – 9:00 مساءً\nالجمعة: 8:00 صباحاً – 2:00 ظهراً",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // حقوق التصميم
            Center(
              child: Column(
                children: [
                  const Text(
                    "تصميم وتطوير",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: LabTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.code,
                            size: 18, color: LabTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          "تيم القادة   تواصل 07750418280",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: LabTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "v 1.0.0",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ✅ ودجت بناء الصفوف للإعدادات
  Widget _buildSettingsTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: LabTheme.cardDecoration(context, elevated: false),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
        ),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  // ✅ ودجت بناء صفوف الاتصال (محسن للنصوص الطويلة)
  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // محاذاة للأعلى في حال تعدد الأسطر
      children: [
        Icon(icon, color: Colors.white, size: 20), // زيادة الحجم قليلاً
        const SizedBox(width: 12),
        Expanded(
          // ✅ استخدام Expanded لمنع الخطأ عند طول النص
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontSize: 13,
              height: 1.5, // تباعد أسطر مريح للقراءة
            ),
          ),
        ),
      ],
    );
  }

  // نافذة تأكيد الخروج
  void _showLogoutDialog(BuildContext context, LabAppModel appModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title:
            const Text("تسجيل الخروج", style: TextStyle(fontFamily: 'Cairo')),
        content: const Text("هل أنت متأكد أنك تريد تسجيل الخروج؟",
            style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء",
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await appModel.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("خروج",
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
// ==========================================
// إصلاح 1: إضافة شاشة الدفع للموبايل
// ==========================================

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // ✅ التعديل: الدفع دائماً نقدي (cash)
  final String _paymentMethod = 'cash';

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<LabAppModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? LabTheme.darkBackground : LabTheme.lightBackground,
      appBar: AppBar(
        title: const Text("إتمام الطلب", style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: LabTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "طريقة الدفع",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 10),

            // ✅ طرق الدفع (تم حذف البطاقة)
            Container(
              padding: const EdgeInsets.all(5),
              decoration: LabTheme.cardDecoration(context),
              child: Column(
                children: [
                  RadioListTile(
                    value: 'cash',
                    groupValue: _paymentMethod,
                    onChanged: (val) {}, // لا نغير القيمة لأنها ثابتة
                    activeColor: LabTheme.primaryColor,
                    title: const Text("الدفع عند الاستلام",
                        style: TextStyle(
                            fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    subtitle: const Text("ادفع نقداً بعد إتمام الفحص",
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.money, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ✅ زر التأكيد (بدون شروط)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LabTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                onPressed: !appModel.isSubmitting
                    ? () async {
                        final success =
                            await appModel.submitOrderToBackend(_paymentMethod);
                        if (success) {
                          if (!mounted) return;
                          Navigator.popUntil(context, (route) => route.isFirst);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("تم إرسال الطلب بنجاح ✅",
                                  style: TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    : null,
                child: appModel.isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("تأكيد الطلب الآن",
                        style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ----------------------
// 2. ألوان وثيمات مخصصة
// ----------------------

class LabTheme {
  static const Color primaryColor = Color(0xFF047857);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color accentColor = Color(0xFF34D399);
  static const Color successColor = Color(0xFF064E3B);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color lightBackground = Color(0xFFECFDF5);
  static const Color darkBackground = Color(0xFF064E3B);

  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF065F46), Color(0xFF10B981)],
  );

  static LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF6EE7B7)],
  );

  static BoxDecoration cardDecoration(BuildContext context,
      {bool elevated = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark ? Color(0xFF2D3250) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 1,
                offset: Offset(0, 5),
              ),
            ]
          : [],
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.withOpacity(0.2),
        width: 1,
      ),
    );
  }
}

// ----------------------
// 3. شاشة الرئيسية - تصميم إبداعي
// ----------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // ✅ متغيرات نظام التنبيهات
  Timer? _notificationTimer;
  Map<String, String> _previousOrderStatuses = {}; // لحفظ حالة كل طلب

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LabAppModel>(context, listen: false).loadUserData();
    });

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();

    // ✅ تشغيل المؤقت للتحقق من تحديثات الطلبات كل 10 ثواني
    _startNotificationCheck();
  }

  void _startNotificationCheck() {
    _notificationTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      final appModel = Provider.of<LabAppModel>(context, listen: false);

      // 1. إذا كانت الإشعارات مغلقة، لا تفعل شيئاً
      if (!appModel.notificationsEnabled) return;

      // 2. تحديث قائمة الطلبات بصمت
      await appModel.fetchMyOrders();

      // 3. مقارنة الحالة الجديدة بالقديمة
      for (var order in appModel.orders) {
        String newStatus = order.status;
        String orderId = order.id;

        if (_previousOrderStatuses.containsKey(orderId)) {
          String oldStatus = _previousOrderStatuses[orderId]!;

          // ✅ الشرط: إذا كان "قيد الانتظار" وأصبح "قيد التنفيذ" (مقبول)
          if (oldStatus == 'PENDING' && newStatus == 'PROCESSING') {
            _showOrderNotification(order.orderNumber);
          }
        }
        // تحديث الحالة المحفوظة
        _previousOrderStatuses[orderId] = newStatus;
      }
    });
  }

  // ✅ دالة عرض التنبيه
  void _showOrderNotification(String orderNumber) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("تحديث حالة الطلب!",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  Text("تم قبول طلبك رقم #$orderNumber وهو قيد التنفيذ الآن",
                      style:
                          const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: LabTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 20),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _animationController.dispose();
    _notificationTimer?.cancel(); // ✅ إيقاف المؤقت
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<LabAppModel>(context);
    // ✅ تم تثبيت الثيم على الفاتح (isDark = false)
    const bool isDark = false;
    final screenWidth = MediaQuery.of(context).size.width;

    final List<Widget> pages = [
      _buildCreativeServicesScreen(appModel, isDark),
      _buildCreativeAIAssistantScreen(appModel, isDark),
      const OrderHistoryScreen(),
      const ProfileScreen(),
    ];

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Scaffold(
            backgroundColor: LabTheme.lightBackground,
            appBar: (_currentIndex == 2 || _currentIndex == 3)
                ? null
                : _buildCreativeAppBar(appModel, screenWidth),
            body:
                _currentIndex < pages.length ? pages[_currentIndex] : pages[0],
            bottomNavigationBar:
                _buildCreativeBottomNavigationBar(appModel, isDark),
            floatingActionButton: _buildFloatingActionButton(appModel, isDark),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          ),
        );
      },
    );
  }

  // ... (باقي دوال البناء مثل _buildCreativeServicesScreen تبقى كما هي، فقط تأكد من تمرير isDark كـ false دائماً أو حذف الباراميتر)
  // سأختصر الكود هنا، عليك فقط استخدام الدوال السابقة الموجودة في ملفك.
  // ...

  // (ضع هنا باقي الدوال مثل _buildCreativeAppBar, _buildActionButton, etc. كما كانت في ردودي السابقة)
  // ...

  AppBar _buildCreativeAppBar(LabAppModel appModel, double screenWidth) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LabTheme.primaryGradient,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: LabTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          // ✅ التعديل هنا: مربع بحواف دائرية (Rounded Square)
          Container(
            padding: const EdgeInsets.all(
                8), // مسافة داخلية لكي لا تلتصق الصورة بالحواف
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), // لون الخلفية الشفاف
              borderRadius: BorderRadius.circular(
                  15), // ✅ جعل الزوايا ناعمة (مربع دائري الحواف)
              border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1), // إطار خفيف جمالي
            ),
            child: Image.asset(
              'assets/logo.png',
              height: 40,
              width: 40,
              fit: BoxFit.contain, // عرض الصورة بالكامل داخل المربع
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'مختبر القمة للتحليلات المرضية',
                  style: TextStyle(
                    fontSize: 18, // تصغير الخط قليلاً ليتناسب مع المساحة
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -2),
                  child: Text(
                    'الرعاية الصحية بلمسة ذكية',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [], // بدون سلة تسوق
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int badgeCount,
    required VoidCallback onPressed,
  }) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 22),
            onPressed: onPressed,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: LabTheme.accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                badgeCount.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 1. شاشة الخدمات (الرئيسية)
  // 1. شاشة الخدمات (الرئيسية)
  Widget _buildCreativeServicesScreen(LabAppModel appModel, bool isDark) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ✅ 1. السلايدر المتحرك الجديد (تم تمرير دالة النافذة المنبثقة له)
        SliverToBoxAdapter(
          child: _PromoCarousel(
            onOfferTap: (test) => _showOfferDetails(context, test, appModel),
          ),
        ),

        // 2. شريط البحث
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: isDark ? const Color(0xFF022C22) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  const Icon(Icons.search,
                      color: LabTheme.primaryColor, size: 24),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: appModel.setSearchQuery,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'ابحث عن فحص طبي...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        appModel.setSearchQuery('');
                      },
                    ),
                ],
              ),
            ),
          ),
        ),

        // إحصائيات سريعة
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: LabTheme.cardDecoration(context, elevated: true),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.medical_services,
                    value: '12',
                    label: 'فحص متوفر',
                    color: LabTheme.primaryColor,
                  ),
                  _buildStatItem(
                    icon: Icons.timer,
                    value: '24',
                    label: 'ساعة للنتائج',
                    color: LabTheme.secondaryColor,
                  ),
                  _buildStatItem(
                    icon: Icons.star,
                    value: '4.9',
                    label: 'تقييم المرضى',
                    color: LabTheme.accentColor,
                  ),
                ],
              ),
            ),
          ),
        ),

        // قسم العروض
        _buildOffersSection(isDark, appModel),

        // تصفح الفحوصات (التصنيفات)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Text(
                    '🔍 تصفح الفحوصات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: LabTheme.primaryColor,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: appModel.categories.map((category) {
                      final isSelected = appModel.selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            appModel.setCategory(category);
                            _animationController.reset();
                            _animationController.forward();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LabTheme.primaryGradient
                                  : LinearGradient(
                                      colors: isDark
                                          ? [
                                              const Color(0xFF065F46),
                                              const Color(0xFF065F46)
                                            ]
                                          : [Colors.white, Colors.white],
                                    ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected
                                    ? LabTheme.primaryColor
                                    : Colors.grey.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : LabTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // شبكة الفحوصات
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.9,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final test = appModel.filteredTests[index];
                final cartItem = appModel.cart.firstWhere(
                  (item) => item.test.id == test.id,
                  orElse: () => CartItem(test: test, quantity: 0),
                );

                return _buildCreativeTestCard(test, cartItem, appModel);
              },
              childCount: appModel.filteredTests.length,
            ),
          ),
        ),
      ],
    );
  }

  // الدوال المساعدة (تأكد أنها موجودة أيضاً داخل الكلاس)
  // ✅ دالة جديدة لبناء قسم العروض
  // ✅ دالة بناء قسم العروض (تمت إضافة عرض العائلة)
  // ✅ دالة بناء قسم العروض (تم تعديل اسم الفحص الشامل)
  Widget _buildOffersSection(bool isDark, LabAppModel appModel) {
    // 1. تعريف العرض الأول (الفحص الدوري + فيتامين D)
    final offer1 = MedicalTest(
      id: 'offer_1',
      nameAr: 'الفحص الدوري + فيتامين D مجاني 🎁', // ✅ تم تعديل الاسم هنا
      nameEn: 'Periodic Checkup + Free Vit D',
      code: 'OFF01',
      price: 25000,
      category: 'عروض',
      descriptionAr: 'تحليل دم + سكر + وظائف كلى + كبد',
      descriptionEn: 'CBC + Sugar + Kidney + Liver',
      keywords: [],
    );

    // 2. تعريف عرض العائلة 👨‍👩‍👧‍👦
    final familyOffer = MedicalTest(
      id: 'offer_family',
      nameAr: 'فحص العائلة المخفّض',
      nameEn: 'Family Discount Package',
      code: 'FAM01',
      price: 25000, // سعر الشخص الواحد
      category: 'عروض',
      descriptionAr: 'كل 3 أشخاص = الرابع مجاني 🎁',
      descriptionEn: 'Buy 3 Get 1 Free',
      keywords: [],
    );

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
            child: Row(
              children: [
                const Icon(Icons.local_offer, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  '🔥 عروض المختبر الحصرية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                // كارت عرض العائلة
                _buildOfferCard(
                  test: familyOffer,
                  oldPrice: "",
                  color1: const Color(0xFF0D9488),
                  color2: const Color(0xFF2DD4BF),
                  icon: Icons.family_restroom,
                  appModel: appModel,
                ),

                // كارت الفحص الدوري (المعدل)
                _buildOfferCard(
                  test: offer1,
                  oldPrice: "35,000",
                  color1: const Color(0xFF065F46),
                  color2: const Color(0xFF10B981),
                  icon: Icons.biotech,
                  appModel: appModel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // ✅ 1. بطاقة العرض (تم ربطها بالنافذة المنبثقة)
  // ------------------------------------------------------------------------
  Widget _buildOfferCard({
    required MedicalTest test,
    required String oldPrice,
    required Color color1,
    required Color color2,
    required IconData icon,
    required LabAppModel appModel,
  }) {
    return InkWell(
      onTap: () =>
          _showOfferDetails(context, test, appModel), // فتح التفاصيل عند الضغط
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color2.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // زخرفة خلفية
            Positioned(
              right: -20,
              top: -20,
              child:
                  Icon(icon, size: 100, color: Colors.white.withOpacity(0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "عرض خاص",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    test.nameAr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    test.descriptionAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${test.price} د.ع',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$oldPrice د.ع',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      // زر إضافة سريع
                      InkWell(
                        onTap: () {
                          appModel.addToCart(test);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("تم إضافة العرض للسلة ✅",
                                  style: TextStyle(fontFamily: 'Cairo')),
                              duration: Duration(seconds: 1),
                              backgroundColor: LabTheme.successColor,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Icon(Icons.add, color: color2, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // ✅ 2. النافذة المنبثقة (تحتوي على التفاصيل التي طلبتها)
  // ------------------------------------------------------------------------
  // ✅ دالة النافذة المنبثقة (تعرض التفاصيل حسب العرض المختار)
  // ✅ دالة النافذة المنبثقة (تعرض التفاصيل حسب العرض المختار)
  // ✅ دالة النافذة المنبثقة (تعرض التفاصيل حسب العرض المختار)
  // ✅ دالة النافذة المنبثقة (تعرض التفاصيل حسب العرض المختار)
  void _showOfferDetails(
      BuildContext context, MedicalTest offer, LabAppModel appModel) {
    List<Widget> detailsContent = [];
    String giftText = "";
    bool isBookable = true;

    // --- العروض السابقة ---
    if (offer.id == 'offer_family') {
      detailsContent = [
        const Text(
            "توضيح العرض: عند حجز الفحص لـ 3 أشخاص، يحصل الشخص الرابع على فحص مجاني!",
            style: TextStyle(
                fontSize: 14,
                color: LabTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo')),
        const SizedBox(height: 15),
        _buildDetailItem(
            'صورة الدم الكاملة (CBC)', 'أكثر من 20 مؤشر للاطمئنان على الصحة'),
        _buildDetailItem('فحص السكر الصائم', ''),
        _buildDetailItem('فحص الدهون', 'الكوليسترول + الدهون الثلاثية'),
        _buildDetailItem('وظائف الكلى', 'Urea + Creatinine'),
        _buildDetailItem('إنزيمات الكبد', 'وظائف الكبد + إنزيم أبو صفار'),
        _buildDetailItem('فحص الالتهابات العام', ''),
        _buildDetailItem('فحص الإدرار العام', ''),
      ];
      giftText = "فيتامين D3 مجاني لكل شخص 🎁";
    } else if (offer.id == 'promo_pcos') {
      detailsContent = [
        const Text("التحاليل المشمولة في باقة تكيس المبايض:",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('فحص الأنسولين', 'INSULIN'),
        _buildDetailItem('فحص الهرمونات الجنسية:',
            '• هرمون (LH)\n• هرمون (FSH)\n• هرمون (PRL)\n• الهرمون الأنثوي (ESTROGEN)\n• الهرمون الذكري (TESTOSTERONE)'),
      ];
      giftText = "فقط بـ 49 الف 🌸";
    } else if (offer.id == 'promo_hair') {
      detailsContent = [
        const Text(
            "شعركم بعده يتساقط؟! حتى تعرفون شنو اسبابها ضروري تسوون التحاليل التالية:",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('فحص الـ', '(CBC)'),
        _buildDetailItem('فحص الكالسيوم', '(CA)'),
        _buildDetailItem('فحص فيتامين', '(D3)'),
        _buildDetailItem('فحص الزنك', '(ZINC)'),
        _buildDetailItem('فحص مخزون الحديد', '(FERRITIN)'),
        _buildDetailItem('فحص هرمون الغدة الدرقية', '(TSH)'),
      ];
      giftText = "مع مختبر القمة ثقة ودقة عالية ❤️";
    } else if (offer.id == 'promo_vitamins') {
      detailsContent = [
        const Text("برنامج فحص الفيتامينات والمعادن يشمل:",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('فحص فيتامين', '(D3)'),
        _buildDetailItem('فحص فيتامين', '(B12)'),
        _buildDetailItem('فحص الزنك', '(ZINC)'),
        _buildDetailItem('فحص عنصر الحديد', '(IRON)'),
        _buildDetailItem('فحص مخزون الحديد', '(FERRITIN)'),
        _buildDetailItem('فحص عنصر الصوديوم', '(Na)'),
        _buildDetailItem('فحص عنصر البوتاسيوم', '(K)'),
        _buildDetailItem('صورة كاملة للدم', '(CBC)'),
      ];
      giftText = "صحتك تبدأ من توازن الفيتامينات 🌿";
    } else if (offer.id == 'promo_kids') {
      detailsContent = [
        const Text(
            "صحة طفلك أمانة عندك.. وللمحافظة على سلامتهم وفرنا لكم هذا البرنامج:",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('صورة كاملة للدم', '(CBC)'),
        _buildDetailItem('فحص فيتامين', '(D3)'),
        _buildDetailItem('فحص السكر اليومي', '(RBS)'),
        _buildDetailItem('فحص عنصر الحديد', '(IRON)'),
        _buildDetailItem('فحص ابو صفار', '(TSB)'),
        _buildDetailItem('فحص هرمون الغدة الدرقية', '(TSH)'),
        _buildDetailItem('فحص عنصر الكالسيوم', '(Ca)'),
        _buildDetailItem('فحص النقرس', '(URIC ACID)'),
        _buildDetailItem('فحص اليوريا', '(UREA)'),
        _buildDetailItem('فحص الخروج العام', '(GSE)'),
        _buildDetailItem('فحص الادرار العام', '(GUE)'),
      ];
      giftText = "للاطمئنان على صحة أطفالكم 🧸";
    } else if (offer.id == 'promo_week') {
      detailsContent = [
        const Text("عرض لمدة اسبوع فقط بـ 39 الف بدلاً من 125 الف دينار!",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: Colors.red)),
        const SizedBox(height: 15),
        _buildDetailItem('فحص فيتامين', '(D3)'),
        _buildDetailItem('فحص كامل للدهون', '(Lipid profile)'),
        _buildDetailItem('فحص كامل لوظائف الكبد', '(LFT)'),
        _buildDetailItem('فحص كامل لوظائف الكلى', '(RFT)'),
        _buildDetailItem('فحص صورة كاملة للدم', '(CBC)'),
        _buildDetailItem('فحص السكر اليومي', '(RBS)'),
        _buildDetailItem('فحص السكر التراكمي', '(HBA1C)'),
        _buildDetailItem('فحص هرمون الغدة الدرقية', '(TSH)'),
      ];
      giftText = "عرض حصري لفترة محدودة ⏱️";
    } else if (offer.id == 'promo_comp') {
      detailsContent = [
        const Text("فحص القمة الشامل يشمل التحاليل التالية:",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('فحص المفاصل وهشاشة العظام', '(ESR, Ca)'),
        _buildDetailItem('فحص صورة الدم الشامل', '(CBC)'),
        _buildDetailItem('فحص السكر اليومي', '(RBS)'),
        _buildDetailItem('فحص جرثومة المعدة', '(H.Pylori)'),
        _buildDetailItem('فحص وظائف الكبد', '(LFT)'),
        _buildDetailItem('فحص وظائف الكلى', '(RFT)'),
        _buildDetailItem('فحص الادرار العام', '(GUE)'),
        _buildDetailItem('فحص الدهون الشامل', '(Lipid Profile)'),
      ];
      giftText = "اطمئن على صحتك بسعر رمزي 🤍";
    } else if (offer.id == 'promo_thyroid') {
      detailsContent = [
        const Text("التحاليل المشمولة في فحص الغدة الدرقية:",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('TSH', ''),
        _buildDetailItem('T3', ''),
        _buildDetailItem('T4', ''),
      ];
      giftText = "نتائج دقيقة بأحدث الأجهزة 🔬";
    } else if (offer.id == 'promo_friday') {
      isBookable = false;
      detailsContent = [
        const Text("بشرى سارة لعملائنا الكرام!",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: Colors.orange)),
        const SizedBox(height: 15),
        const Text(
            "استفد من خصم 50% على كافة التحاليل الطبية عند زيارتك لمختبرنا يوم الجمعة من كل أسبوع. \n\nأوقات الدوام يوم الجمعة:\nمن 8:00 صباحاً حتى 2:00 ظهراً.",
            style: TextStyle(fontSize: 15, fontFamily: 'Cairo', height: 1.5)),
      ];
      giftText = "نحن هنا لخدمتكم 🌹";
    } else if (offer.id == 'pkg_foreign_workers') {
      detailsContent = [
        const Text("باقة فحص العاملات الأجنبيات – المختبرية الأساسية",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        const Text(
            "لأغراض الإقامة والعمل ✔️\nنتائج سريعة خلال نفس اليوم ✔️\nفحص دقيق وبأجهزة حديثة ✔️",
            style: TextStyle(
                fontSize: 14,
                fontFamily: 'Cairo',
                color: Colors.black87,
                height: 1.5)),
        const Divider(),
        const Text("🔴 فحوصات الأمراض المعدية:",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: Colors.red)),
        _buildDetailItem('HBsAg', '(التهاب الكبد B)'),
        _buildDetailItem('Anti-HCV', '(التهاب الكبد C)'),
        _buildDetailItem('HIV 1 & 2', ''),
        _buildDetailItem('VDRL', '(الزهري)'),
        const Text("🟡 فحوصات الصحة العامة:",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: Colors.amber)),
        _buildDetailItem('CBC', '(صورة دم كاملة)'),
        _buildDetailItem('Urinalysis', '(فحص بول عام)'),
      ];
      giftText = "تقارير رسمية معتمدة 📄";
    } else if (offer.id == 'pkg_female_hormones') {
      detailsContent = [
        const Text("مناسبة لاضطراب الدورة، تأخر الحمل، تكيس المبايض ✔️",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('FSH', ''),
        _buildDetailItem('LH', ''),
        _buildDetailItem('Prolactin', ''),
        _buildDetailItem('Estradiol', '(E2)'),
        _buildDetailItem('TSH', ''),
      ];
      giftText = "تشخيص مبكر لمشاكل الهرمونات 🌸";
    } else if (offer.id == 'pkg_pregnancy_delay') {
      detailsContent = [
        const Text("خطوة أولى لتقييم الخصوبة ✔️",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('FSH', ''),
        _buildDetailItem('LH', ''),
        _buildDetailItem('AMH', 'تقييم مخزون المبيض'),
        _buildDetailItem('Prolactin', ''),
        _buildDetailItem('TSH', ''),
      ];
      giftText = "تحديد سبب الخلل الهرموني بسرعة 🤰";
    } else if (offer.id == 'pkg_male_hormones') {
      detailsContent = [
        const Text("للضعف العام، تساقط الشعر، مشاكل الخصوبة ✔️",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('Testosterone', ''),
        _buildDetailItem('Prolactin', ''),
        _buildDetailItem('FSH', ''),
        _buildDetailItem('LH', ''),
      ];
      giftText = "تقييم دقيق لوظيفة الخصية 🧔";
    } else if (offer.id == 'pkg_anemia') {
      detailsContent = [
        const Text("إرهاق، دوخة، شحوب؟ ✔️",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('CBC', 'صورة الدم الكاملة'),
        _buildDetailItem('Serum Iron', 'الحديد بالدم'),
        _buildDetailItem('Ferritin', 'مخزون الحديد'),
        _buildDetailItem('Vitamin B12', ''),
        _buildDetailItem('Vitamin D', ''),
      ];
      giftText = "تحديد نوع فقر الدم بدقة 🩸";
    } else if (offer.id == 'pkg_heart_lipids') {
      detailsContent = [
        const Text("للاطمئنان على صحة القلب (مناسبة لمن فوق 30 سنة) ✔️",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('Cholesterol', ''),
        _buildDetailItem('TG', 'الدهون الثلاثية'),
        _buildDetailItem('HDL', 'الدهون النافعة'),
        _buildDetailItem('LDL', 'الدهون الضارة'),
        _buildDetailItem('Blood Sugar', 'سكر الدم'),
        _buildDetailItem('Troponin', 'إنزيم القلب'),
        _buildDetailItem('CBC', ''),
      ];
      giftText = "تقييم خطر الجلطات مبكراً 🫀";
    } else if (offer.id == 'pkg_fatigue_hair') {
      detailsContent = [
        const Text("تحس تعب دائم؟ دوخة؟ تساقط شعر؟",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('CBC', 'صورة الدم الكاملة'),
        _buildDetailItem('Ferritin', 'مخزون الحديد'),
        _buildDetailItem('Vitamin D3', ''),
        _buildDetailItem('Vitamin B12', ''),
        _buildDetailItem('TSH', 'هرمون الغدة الدرقية'),
      ];
      giftText = "تكشف فقر الدم + نقص الفيتامينات 🔵";
    } else if (offer.id == 'pkg_diabetes') {
      detailsContent = [
        const Text("للإطمئنان أو لمرضى السكري:",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('FBS', 'السكر الصائم'),
        _buildDetailItem('HbA1c', 'السكر التراكمي'),
        _buildDetailItem('2hPPBS', 'السكر بعد الأكل بساعتين'),
        _buildDetailItem('Urine Analysis', 'إدرار عام'),
        _buildDetailItem('Microalbumin', 'زلال البول الدقيق'),
      ];
      giftText = "تقييم السيطرة على السكر 🟣";
    } else if (offer.id == 'pkg_clots') {
      detailsContent = [
        const Text(
            "للأشخاص فوق 35 سنة أو عند وجود تاريخ عائلي (يفضل صيام 8 ساعات):",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('Lipid Profile', 'دهون الدم الشاملة'),
        _buildDetailItem('CK-MB', 'إنزيم القلب'),
        _buildDetailItem('Troponin I', 'إنزيم القلب الدقيق'),
        _buildDetailItem('CRP', 'بروتين الالتهاب'),
        _buildDetailItem('D-Dimer', 'مؤشر التجلط'),
      ];
      giftText = "تقييم دهون الدم ومؤشرات الجلطات 🔴";
    } else if (offer.id == 'pkg_marriage') {
      detailsContent = [
        const Text("فحص ضروري ومهم لكل شاب وبنية:",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('CBC', 'صورة الدم'),
        _buildDetailItem('Blood Group', 'فصيلة الدم'),
        _buildDetailItem('HBsAg', 'التهاب الكبد B'),
        _buildDetailItem('HCV', 'التهاب الكبد C'),
        _buildDetailItem('HIV', 'نقص المناعة'),
        _buildDetailItem('VDRL', 'الزهري'),
        _buildDetailItem('Thalassemia Screen', 'فحص التلاسيميا'),
      ];
      giftText = "اطمئنان كامل قبل الخطوة المهمة 💍 🟢";
    } else if (offer.id == 'pkg_fatigue_top') {
      detailsContent = [
        const Text("الباقة الأكثر طلباً لمعرفة سبب التعب المستمر:",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('CBC', 'صورة الدم الكاملة'),
        _buildDetailItem('Ferritin', 'مخزون الحديد'),
        _buildDetailItem('Vitamin D3', ''),
        _buildDetailItem('Vitamin B12', ''),
        _buildDetailItem('TSH', 'هرمون الغدة الدرقية'),
      ];
      giftText = "تودع التعب وترجع طاقتك 🟣";
    } else if (offer.id == 'pkg_ramadan') {
      detailsContent = [
        const Text("الباقة الشاملة للاطمئنان الكامل:",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('صورة كاملة للدم', '(CBC)'),
        _buildDetailItem('فحص مخزون الحديد', ''),
        _buildDetailItem('السكر الصائم + السكر التراكمي', ''),
        _buildDetailItem('وظائف الكلى', '(اليوريا + الكرياتينين)'),
        _buildDetailItem('وظائف الكبد', 'خمسة إنزيمات أساسية'),
        _buildDetailItem('فحص الكوليسترول والدهون الثلاثية', ''),
        _buildDetailItem('فحص الإدرار العام', ''),
        _buildDetailItem('فحص الالتهابات والمناعة العامة', ''),
      ];
      giftText = "مجاناً: فحص فيتامين D + جرثومة المعدة 🎁 🟣";
    } else if (offer.id == 'pkg_energy') {
      detailsContent = [
        const Text("مناسبة للناس اللي يحسون تعب أو تساقط شعر أو دوخة:",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('CBC', 'صورة الدم الكاملة'),
        _buildDetailItem('Ferritin', 'مخزون الحديد'),
        _buildDetailItem('Vitamin D', ''),
        _buildDetailItem('Vitamin B12', ''),
        _buildDetailItem('TSH', 'هرمون الغدة الدرقية'),
      ];
      giftText = "باقة الطاقة والصحة العامة ⚡ 🔹";

      // --- الإضافات الخمسة الجديدة ---
    } else if (offer.id == 'pkg_sports_general') {
      detailsContent = [
        const Text("مناسبة للرياضيين ورفع الأداء البدني ومتابعة التعافي:",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('الدم والفيتامينات', 'CBC + Ferritin + Vitamin D'),
        _buildDetailItem('الشوارد والمعادن', 'Na, K, Ca, Mg'),
        _buildDetailItem('وظائف الكلى', 'Urea + Creatinine'),
        _buildDetailItem('وظائف الكبد', '5 إنزيمات أساسية'),
        _buildDetailItem('فحص الدهون', 'Cholesterol + TG + HDL + LDL'),
        _buildDetailItem('صحة العضلات والقلب', 'CK'),
        _buildDetailItem('الغدة الدرقية', 'TSH + Free T4'),
      ];
      giftText = "باقة الرياضيين – فحص الأداء والصحة 🏋️‍♂️ 🔹";
    } else if (offer.id == 'pkg_obesity') {
      detailsContent = [
        const Text("فحص شامل لمخاطر الوزن الزائد:",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('الدم والفيتامينات', 'CBC + Ferritin + Vitamin D'),
        _buildDetailItem('السكري', 'Sugar Fasting + HbA1c'),
        _buildDetailItem(
            'وظائف الكبد والدهون', 'Lipid Profile + Liver Enzymes (5)'),
        _buildDetailItem('وظائف الكلى', 'Urea + Creatinine'),
        _buildDetailItem('الغدة الدرقية', 'TSH + Free T4'),
        _buildDetailItem('مؤشر الالتهابات', 'CRP'),
        _buildDetailItem('فحص البول', 'Urine Routine'),
      ];
      giftText = "باقة فحص السمنة الشامل ⚖️ 🔹";
    } else if (offer.id == 'pkg_sports_hormones') {
      detailsContent = [
        const Text("الفحوصات الهرمونية للرياضيين (حسب الجنس):",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('التستوستيرون', 'Testosterone'),
        _buildDetailItem('التستوستيرون الحر', 'Free Testosterone'),
        _buildDetailItem('هرمونات الخصوبة', 'LH + FSH'),
        _buildDetailItem('هرمون التوتر', 'Cortisol'),
        _buildDetailItem('هرمون الغدة الكظرية', 'DHEA-S'),
      ];
      giftText = "باقة الرياضيين الهرمونية 🧬 🔹";
    } else if (offer.id == 'pkg_minerals') {
      detailsContent = [
        const Text("مناسبة للرياضيين، الإرهاق المزمن، وهشاشة العظام:",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('الحديد ومخزونه', 'Iron / Ferritin'),
        _buildDetailItem('الزنك', 'Zinc'),
        _buildDetailItem('المغنيسيوم', 'Magnesium'),
        _buildDetailItem('الكالسيوم', 'Calcium'),
        _buildDetailItem('الفوسفور', 'Phosphorus'),
      ];
      giftText = "باقة العناصر المعدنية الأساسية 🧪 🔹";
    } else if (offer.id == 'pkg_grand_full_body') {
      detailsContent = [
        const Text("لمن يريد فحص شامل لكل الجسم تقريباً بدون استثناء:",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: LabTheme.primaryColor)),
        const SizedBox(height: 15),
        _buildDetailItem('1️⃣ الدم والوظائف الأساسية',
            'صورة الدم، السكر التراكمي، الكلى، الكبد، الدهون، والبول'),
        _buildDetailItem('2️⃣ القلب والعضلات', 'إنزيم CK'),
        _buildDetailItem('3️⃣ المعدة والبنكرياس',
            'جرثومة المعدة (H. Pylori)، Amylase, Lipase'),
        _buildDetailItem('4️⃣ الغدد والهرمونات',
            'هرمونات الذكورة/الأنوثة، التوتر (Cortisol)، الغدة الدرقية'),
        _buildDetailItem('5️⃣ الفيتامينات والمعادن',
            'Vit D, Vit B12, Folate, Iron, Zinc, Mg, Ca, Ph'),
        _buildDetailItem(
            '6️⃣ الالتهابات والمناعة', 'مؤشرات الالتهاب والمناعة العامة'),
      ];
      giftText = "الباقة الكبرى الموسعة (Full Body) 🌟 🔹";
    } else {
      detailsContent = [const Text("لا توجد تفاصيل إضافية.")];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: LabTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.verified,
                        color: LabTheme.primaryColor, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      offer.nameAr,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: LabTheme.darkBackground),
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey)),
                ],
              ),
              const Divider(height: 30),
              Expanded(
                child: ListView(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ...detailsContent,
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LabTheme.secondaryGradient,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                              color: LabTheme.secondaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5))
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard,
                              color: Colors.white, size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(giftText,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (isBookable)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: LabTheme.lightBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: LabTheme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("السعر الكلي",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontFamily: 'Cairo')),
                          Text(
                            "${offer.price} د.ع",
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: LabTheme.primaryColor,
                                fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          appModel.addToCart(offer);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("تمت إضافة العرض للسلة ✅",
                                    style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: LabTheme.primaryColor),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LabTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        icon: const Icon(Icons.add_shopping_cart,
                            color: Colors.white),
                        label: const Text("حجز العرض",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // ✅ 3. ويدجتات مساعدة للتصميم (لتسهيل القراءة)
  // ------------------------------------------------------------------------

  Widget _buildDetailItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fiber_manual_record,
              color: LabTheme.secondaryColor, size: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Colors.black87,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontFamily: 'Cairo',
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: LabTheme.primaryColor),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCreativeTestCard(
      MedicalTest test, CartItem cartItem, LabAppModel appModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {},
      child: Container(
        decoration: LabTheme.cardDecoration(context),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(test.category).withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(40),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(_getCategoryIcon(test.category),
                          color: _getCategoryColor(test.category)),
                      if (cartItem.quantity > 0)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: LabTheme.accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${cartItem.quantity}',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                        )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(test.nameAr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black)),
                      SizedBox(height: 5),
                      Text('${test.price} د.ع',
                          style: TextStyle(
                              color: LabTheme.primaryColor,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.add_circle,
                        color: LabTheme.primaryColor, size: 30),
                    onPressed: () => appModel.addToCart(test),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item,
      LabAppModel appModel, bool isDark, int index) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, index == 0 ? 20 : 10, 20,
          index == appModel.cart.length - 1 ? 20 : 10),
      decoration: LabTheme.cardDecoration(context),
      child: Stack(
        children: [
          // زخرفة الخلفية
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getCategoryColor(item.test.category).withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(40),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة الفحص
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(item.test.category),
                        _getCategoryColor(item.test.category).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: _getCategoryColor(item.test.category)
                            .withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(item.test.category),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(width: 15),

                // التفاصيل
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appModel.isArabic
                                  ? item.test.nameAr
                                  : item.test.nameEn,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: LabTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.test.code,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: LabTheme.primaryColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        appModel.isArabic
                            ? item.test.descriptionAr
                            : item.test.descriptionEn,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 15),

                      // أزرار التحكم بالكمية والسعر
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: LabTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item.test.price * item.quantity} د.ع',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: LabTheme.successColor,
                              ),
                            ),
                          ),
                          Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // زر الإنقاص
                                IconButton(
                                  icon: Icon(
                                    Icons.remove,
                                    size: 20,
                                    color: item.quantity > 1
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  onPressed: () {
                                    appModel.removeFromCart(item.test);
                                  },
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    item.quantity.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                                // زر الزيادة
                                IconButton(
                                  icon: Icon(
                                    Icons.add,
                                    size: 20,
                                    color: LabTheme.primaryColor,
                                  ),
                                  onPressed: () {
                                    appModel.addToCart(item.test);
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),

                          // زر الحذف (سلة المهملات) - تم تصحيحه
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                // هنا التصحيح: استدعاء الدالة مباشرة
                                appModel.removeFromCart(item.test);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 1. استخراج الرأس في ويدجت مستقل
  Widget _buildAssistantHeader() {
    return Container(
      padding: EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LabTheme.primaryColor,
            LabTheme.secondaryColor.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: LabTheme.primaryColor.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.health_and_safety,
                    size: 60,
                    color: LabTheme.primaryColor,
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: LabTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'المساعد الطبي الذكي',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'أنا هنا لمساعدتك في اختيار الفحوصات المناسبة لصحتك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildExampleChip('💊 آلام المعدة'),
                _buildExampleChip('😴 تعب وإرهاق'),
                _buildExampleChip('💓 ألم في الصدر'),
                _buildExampleChip('🩸 فحص دوري'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 2. تعديل الشاشة لجعل الرأس جزءاً من القائمة
  Widget _buildCreativeAIAssistantScreen(LabAppModel appModel, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    )
                  : null,
              color: isDark ? Colors.transparent : Colors.white,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.03,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/pattern.png'),
                          repeat: ImageRepeat.repeat,
                        ),
                      ),
                    ),
                  ),
                ),
                appModel._chatMessages
                        .isEmpty // تأكد من استخدام chatMessages وليس _chatMessages
                    ? _buildCreativeEmptyChat(isDark)
                    : _buildCreativeChatList(appModel, isDark),
                if (appModel.isAiThinking)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: _buildThinkingIndicator(),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D3250) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.black.withOpacity(0.3) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: LabTheme.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'اكتب استفسارك الطبي هنا...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LabTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: LabTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          final question = _chatController.text.trim();
                          if (question.isEmpty) return;

                          appModel.askAIAssistant(question);
                          _chatController.clear();
                          FocusScope.of(context).unfocus();

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_chatScrollController.hasClients) {
                              _chatScrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // تعديل المحاذاة بعد الحذف
                children: [
                  // ❌ تم حذف زر المايك من هنا

                  // زر السلة
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: LabTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_cart,
                          size: 16,
                          color: LabTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appModel.cart.isEmpty
                              ? 'سلة فارغة'
                              : '${appModel.cart.length} فحص',
                          style: const TextStyle(
                            color: LabTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // زر مسح المحادثة
                  if (appModel._chatMessages.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: LabTheme.accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: LabTheme.accentColor,
                        ),
                        onPressed: () => appModel.clearChat(),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExampleChip(String text) {
    return Container(
      margin: EdgeInsets.only(right: 10),
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  // ✅ 3. جعل الشاشة الفارغة قابلة للتمرير مع الرأس
  Widget _buildCreativeEmptyChat(bool isDark) {
    return SingleChildScrollView(
      // استخدام SingleChildScrollView
      child: Column(
        children: [
          _buildAssistantHeader(), // الرأس الآن جزء من التمرير
          SizedBox(height: 50),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            decoration: BoxDecoration(
              gradient: LabTheme.primaryGradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: LabTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_downward, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'ابدأ المحادثة الآن',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50), // مساحة إضافية في الأسفل للتمرير
        ],
      ),
    );
  }

  // ✅ 4. دمج الرأس مع قائمة المحادثة عند وجود رسائل
  Widget _buildCreativeChatList(LabAppModel appModel, bool isDark) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      controller: _chatScrollController,
      reverse: true,
      padding: EdgeInsets.all(20),
      // نزيد 1 للرأس
      itemCount:
          appModel._chatMessages.length + (appModel.isAiThinking ? 1 : 0) + 1,
      itemBuilder: (context, index) {
        // إذا كان العنصر الأخير (في القائمة المعكوسة يعني الأعلى)، نعرض الرأس
        if (index ==
            appModel._chatMessages.length + (appModel.isAiThinking ? 1 : 0)) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildAssistantHeader(),
          );
        }

        if (appModel.isAiThinking && index == 0) {
          return _buildTypingIndicatorWithAnimation();
        }

        // ضبط الفهرس لأننا أضفنا الرأس
        final messageIndex = appModel.isAiThinking ? index - 1 : index;
        final message = appModel._chatMessages.reversed.toList()[messageIndex];

        return _buildCreativeChatBubble(message, appModel, isDark);
      },
    );
  }

  Widget _buildTypingIndicatorWithAnimation() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LabTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _buildTypingDot(delay: 0),
                      SizedBox(width: 4),
                      _buildTypingDot(delay: 200),
                      SizedBox(width: 4),
                      _buildTypingDot(delay: 400),
                    ],
                  ),
                  SizedBox(width: 10),
                  Text(
                    'جاري كتابة الرد...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot({int delay = 0}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: LabTheme.primaryColor,
        shape: BoxShape.circle,
      ),
    );
  }

  // 1. فقاعة المحادثة (Chat Bubble)
  Widget _buildCreativeChatBubble(
      ChatMessage message, LabAppModel appModel, bool isDark) {
    final isUser = message.isUser;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // أيقونة المساعد (لليسار)
          if (!isUser)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LabTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LabTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 20,
              ),
            ),
          SizedBox(width: 10),

          // محتوى الرسالة
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          )
                        : LinearGradient(
                            colors: [Colors.white, Color(0xFFf7f9fc)],
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft:
                          isUser ? Radius.circular(20) : Radius.circular(5),
                      topRight:
                          isUser ? Radius.circular(5) : Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: isUser ? Colors.white : Colors.black,
                          height: 1.4,
                        ),
                      ),
                      // عرض الفحوصات المقترحة إذا وجدت
                      if (message.suggestedTestCodes != null &&
                          message.suggestedTestCodes!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 15),
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.white.withOpacity(0.1)
                                    : LabTheme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isUser
                                      ? Colors.white.withOpacity(0.3)
                                      : LabTheme.primaryColor.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.recommend,
                                        size: 18,
                                        color: isUser
                                            ? Colors.white
                                            : LabTheme.primaryColor,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'الفحوصات المقترحة',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isUser
                                              ? Colors.white
                                              : LabTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  // استدعاء الدالة المفقودة هنا
                                  ...message.suggestedTestCodes!
                                      .map((testCode) {
                                    final test = appModel.allTests.firstWhere(
                                      (t) => t.code == testCode,
                                      orElse: () => appModel.allTests[0],
                                    );

                                    return _buildSuggestedTestCardEnhanced(
                                        test, appModel, isUser);
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // الوقت
                SizedBox(height: 5),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // أيقونة المستخدم (لليمين)
          if (isUser)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  // 2. كارت الفحص المقترح (الدالة المفقودة)
  Widget _buildSuggestedTestCardEnhanced(
      MedicalTest test, LabAppModel appModel, bool isUser) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isUser ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUser
              ? Colors.white.withOpacity(0.2)
              : LabTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(test.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(test.category),
              size: 20,
              color: _getCategoryColor(test.category),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        test.nameAr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isUser ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.white.withOpacity(0.2)
                            : LabTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        test.code,
                        style: TextStyle(
                          fontSize: 9,
                          color:
                              isUser ? Colors.white70 : LabTheme.primaryColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  test.descriptionAr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser ? Colors.white70 : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: LabTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.price_change,
                            size: 10,
                            color: LabTheme.successColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${test.price} دينار',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: LabTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LabTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => appModel.addToCart(test),
                        icon: Icon(
                          Icons.add,
                          size: 14,
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.all(5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // الدوال المساعدة (تأكد أنها موجودة أيضاً داخل الكلاس)

  Widget _buildCreativeBottomNavigationBar(LabAppModel appModel, bool isDark) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D3250) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. الفحوصات (الرئيسية)
          _buildNavItem(
            icon: Icons.medical_services,
            label: 'الفحوصات',
            isActive: _currentIndex == 0,
            onTap: () => setState(() => _currentIndex = 0),
          ),

          // 2. المساعد الذكي
          _buildNavItem(
            icon: Icons.health_and_safety,
            label: 'المساعد',
            isActive: _currentIndex == 1,
            onTap: () => setState(() => _currentIndex = 1),
          ),

          // مساحة فارغة للزر العائم في المنتصف
          SizedBox(width: 60),

          // 3. السجل (تم التأكد منه) ✅
          _buildNavItem(
            icon: Icons.history,
            label: 'السجل',
            isActive: _currentIndex == 2,
            onTap: () => setState(() => _currentIndex = 2), // الانتقال للسجل
          ),

          // 4. حسابي (تم التأكد منه) ✅
          _buildNavItem(
            icon: Icons.person,
            label: 'حسابي',
            isActive: _currentIndex == 3,
            onTap: () =>
                setState(() => _currentIndex = 3), // الانتقال للملف الشخصي
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? LabTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? LabTheme.primaryColor : Colors.grey[600],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? LabTheme.primaryColor : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(LabAppModel appModel, bool isDark) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LabTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: LabTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        icon: Stack(
          children: [
            Icon(Icons.shopping_cart, color: Colors.white, size: 28),
            if (appModel.cart.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: LabTheme.accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '${appModel.cart.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        ),
      ),
    );
  }

  // داخل _HomeScreenState
  Color _getCategoryColor(String category) {
    final colors = {
      // درجات الأخضر المتنوعة لتمييز الأقسام
      'فحوصات الدم': const Color(0xFF047857), // أخضر زمردي غامق
      'الكيمياء الحيوية': const Color(0xFF059669), // أخضر متوسط
      'فايروسات': const Color(0xFF10B981), // أخضر حيوي
      'مناعة': const Color(0xFF34D399), // أخضر فاتح
      'البكتيريا': const Color(0xFF6EE7B7), // أخضر باستيل
      'الهرمونات': const Color(0xFF064E3B), // أخضر داكن جداً
      'الفيتامينات': const Color(0xFF0D9488), // أخضر مزرق (Teal)
      'وظائف الأعضاء': const Color(0xFF14B8A6), // تركواز
      'أخرى': const Color(0xFF99F6E4), // فاتح جداً
    };
    return colors[category] ?? LabTheme.primaryColor;
  }

  // داخل _HomeScreenState (وكذلك DesktopHomeScreenState إذا كنت تستخدمه)
  IconData _getCategoryIcon(String category) {
    final icons = {
      'فحوصات الدم': Icons.bloodtype,
      'الكيمياء الحيوية': Icons.science, // ✅ أيقونة أنبوب اختبار
      'فايروسات': Icons.coronavirus, // ✅ أيقونة الفايروس
      'مناعة': Icons.shield_outlined, // ✅ أيقونة درع المناعة
      'البكتيريا': Icons.bug_report, // ✅ أيقونة البكتيريا
      'الهرمونات': Icons.insights,
      'الفيتامينات': Icons.eco,
      'وظائف الأعضاء': Icons.monitor_heart,
      'أخرى': Icons.more_horiz,
    };
    return icons[category] ?? Icons.medical_services;
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} د.ع';
  }

  // ✅ دالة إظهار تفاصيل العرض (نافذة منبثقة احترافية)

  // ويدجت مساعد لبناء عناصر القائمة

  // ويدجت مساعد للمميزات

  Widget _buildThinkingIndicator() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LabTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                size: 20,
                color: LabTheme.primaryColor,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جاري تحليل الأعراض...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: LabTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  width: 100,
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(LabTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------
// 4. شاشة السلة بتصميم إبداعي
// ----------------------

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<LabAppModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ التعديل الأول: السعر الكلي يساوي مجموع التحاليل فقط (بدون زيادة)
    final total = appModel.getCartTotalPrice();
    final grandTotal = total;

    return Scaffold(
      backgroundColor:
          isDark ? LabTheme.darkBackground : LabTheme.lightBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true, // تثبيت البار عند التمرير
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LabTheme.primaryGradient,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/cart_pattern.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            appModel.isArabic ? 'سلة التسوق' : 'Shopping Cart',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (appModel.cart.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyCart(context, appModel, isDark),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = appModel.cart[index];
                  return _buildCartItemCard(
                      context, item, appModel, isDark, index);
                },
                childCount: appModel.cart.length,
              ),
            ),
          if (appModel.cart.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: LabTheme.cardDecoration(context),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: LabTheme.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            appModel.isArabic ? 'ملخص الطلب' : 'Order Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ✅ تم حذف صفوف الضريبة والخدمة لتقليل المساحة ومنع الزيادة

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            appModel.isArabic
                                ? 'المجموع الكلي'
                                : 'Total Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            '$grandTotal د.ع',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: LabTheme.primaryColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (appModel.cart.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 40), // مسافة بالأسفل
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.arrow_back,
                                color: LabTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                appModel.isArabic
                                    ? 'متابعة التسوق'
                                    : 'Continue Shopping',
                                style: const TextStyle(
                                  color: LabTheme.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LabTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: LabTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PaymentScreen()),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                appModel.isArabic ? 'تأكيد الحجز' : 'Checkout',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ... (باقي الدوال المساعدة _buildEmptyCart, _buildCartItemCard, etc. تبقى كما هي انسخها من الكود السابق)
  // يفضل نسخ الدوال المساعدة هنا لضمان عدم حدوث أخطاء
  Widget _buildEmptyCart(
      BuildContext context, LabAppModel appModel, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[400]!,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 70,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            appModel.isArabic ? 'السلة فارغة' : 'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            appModel.isArabic
                ? 'أضف فحوصات طبية لتبدأ رحلة العناية بصحتك'
                : 'Add medical tests to start your health journey',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              gradient: LabTheme.primaryGradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: LabTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    appModel.isArabic ? 'تصفح الفحوصات' : 'Browse Tests',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item,
      LabAppModel appModel, bool isDark, int index) {
    // ... (نفس كود البطاقة السابق تماماً)
    // للاختصار، افترض أنك ستنسخ كود _buildCartItemCard السابق هنا
    return Container(
      margin: EdgeInsets.fromLTRB(20, index == 0 ? 20 : 10, 20,
          index == appModel.cart.length - 1 ? 20 : 10),
      decoration: LabTheme.cardDecoration(context),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getCategoryColor(item.test.category).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(40),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(item.test.category),
                        _getCategoryColor(item.test.category).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: _getCategoryColor(item.test.category)
                            .withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(item.test.category),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appModel.isArabic
                                  ? item.test.nameAr
                                  : item.test.nameEn,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appModel.isArabic
                            ? item.test.descriptionAr
                            : item.test.descriptionEn,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Cairo',
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: LabTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item.test.price * item.quantity} د.ع',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: LabTheme.successColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 20),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      appModel.removeFromCart(item.test);
                                    }
                                  },
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text(
                                    item.quantity.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add,
                                      size: 20, color: LabTheme.primaryColor),
                                  onPressed: () =>
                                      appModel.addToCart(item.test),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  appModel.removeFromCart(item.test),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'فحوصات الدم': const Color(0xFF047857),
      'الهرمونات': const Color(0xFF064E3B),
      'الفيتامينات': const Color(0xFF0D9488),
      'وظائف الأعضاء': const Color(0xFF14B8A6),
      'أخرى': const Color(0xFF99F6E4),
    };
    return colors[category] ?? LabTheme.primaryColor;
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'فحوصات الدم': Icons.bloodtype,
      'الهرمونات': Icons.insights,
      'الفيتامينات': Icons.eco,
      'وظائف الأعضاء': Icons.monitor_heart,
      'أخرى': Icons.more_horiz,
    };
    return icons[category] ?? Icons.medical_services;
  }
}
// ----------------------
// 5. تصميم متجاوب للشاشات الكبيرة
// ----------------------

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileScreen;
  final Widget desktopScreen;

  const ResponsiveLayout({
    Key? key,
    required this.mobileScreen,
    required this.desktopScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 768) {
          return desktopScreen;
        } else {
          return mobileScreen;
        }
      },
    );
  }
}

// ----------------------
// 6. تصميم احترافي للشاشات الكبيرة (لابتوب)
// ----------------------

class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  int _currentIndex = 0;
  late AnimationController _animationController;
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<LabAppModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. الشريط الجانبي
          _buildDesktopSidebar(appModel, isDark),

          // 2. المحتوى الرئيسي
          Expanded(
            child: Column(
              children: [
                // شريط البحث العلوي
                _buildDesktopTopBar(appModel, isDark, screenWidth),

                // المحتوى الرئيسي
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildDesktopContent(appModel, isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // الشريط الجانبي
  Widget _buildDesktopSidebar(LabAppModel appModel, bool isDark) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // شعار المختبر
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LabTheme.primaryGradient,
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'مختبر القمة الطبي',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'الرعاية الصحية الذكية',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // قائمة التنقل
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildSidebarItem(
                  icon: Icons.dashboard,
                  label: 'لوحة التحكم',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _buildSidebarItem(
                  icon: Icons.medical_services,
                  label: 'الفحوصات',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _buildSidebarItem(
                  icon: Icons.health_and_safety,
                  label: 'المساعد الذكي',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _buildSidebarItem(
                  icon: Icons.shopping_cart,
                  label: 'سلة التسوق',
                  badgeCount: appModel.cart.length,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DesktopCartScreen()),
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.person,
                  label: 'الملف الشخصي',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DesktopProfileScreen()),
                  ),
                ),
                Divider(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  indent: 20,
                  endIndent: 20,
                  height: 40,
                ),
                _buildSidebarItem(
                  icon: Icons.logout,
                  label: 'تسجيل الخروج',
                  color: Colors.red,
                  onTap: () => _showLogoutDialog(context, appModel),
                ),
              ],
            ),
          ),

          // معلومات المستخدم
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: LabTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: LabTheme.primaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appModel.userName.isNotEmpty
                            ? appModel.userName
                            : 'مرحباً بك',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'عميل مميز',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    size: 20,
                    color: isDark ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () => appModel.toggleTheme(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    int badgeCount = 0,
    Color? color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? LabTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: LabTheme.primaryColor.withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? LabTheme.primaryColor
                    : (color ?? Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive
                    ? Colors.white
                    : (color ?? (isDark ? Colors.white70 : Colors.grey)),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? LabTheme.primaryColor
                : (isDark ? Colors.white : Colors.black),
          ),
        ),
        trailing: isActive
            ? Icon(
                Icons.arrow_left,
                color: LabTheme.primaryColor,
                size: 20,
              )
            : Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
        minLeadingWidth: 0,
      ),
    );
  }

  // الشريط العلوي
  Widget _buildDesktopTopBar(
      LabAppModel appModel, bool isDark, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // شريط البحث
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: appModel.setSearchQuery,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'ابحث عن فحص طبي...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        appModel.setSearchQuery('');
                      },
                    ),
                  SizedBox(width: 16),
                ],
              ),
            ),
          ),

          SizedBox(width: 20),

          // الأزرار الإضافية
          _buildTopBarButton(
            icon: Icons.notifications,
            badgeCount: 3,
            onPressed: () {},
          ),
          SizedBox(width: 12),
          _buildTopBarButton(
            icon: Icons.shopping_cart,
            badgeCount: appModel.cart.length,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DesktopCartScreen()),
            ),
          ),
          SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LabTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: () => setState(() => _currentIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarButton({
    required IconData icon,
    required int badgeCount,
    required VoidCallback onPressed,
  }) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              size: 20,
              color: Colors.grey.shade600,
            ),
            onPressed: onPressed,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                badgeCount.toString(),
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // المحتوى الرئيسي
  Widget _buildDesktopContent(LabAppModel appModel, bool isDark) {
    switch (_currentIndex) {
      case 0:
        return _buildDesktopDashboard(appModel, isDark);
      case 1:
        return _buildDesktopTestsGrid(appModel, isDark);
      case 2:
        return _buildDesktopAIChat(appModel, isDark);
      default:
        return _buildDesktopDashboard(appModel, isDark);
    }
  }

  // لوحة التحكم
  Widget _buildDesktopDashboard(LabAppModel appModel, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لوحة التحكم',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'مرحباً بك في مختبر الشفاء الطبي',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 32),

          // بطاقات الإحصائيات
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 2,
            children: [
              _buildStatCard(
                title: 'الفحوصات المتاحة',
                value: '12',
                icon: Icons.medical_services,
                color: Colors.blue,
                isDark: isDark,
              ),
              _buildStatCard(
                title: 'سلة التسوق',
                value: '${appModel.cart.length}',
                icon: Icons.shopping_cart,
                color: Colors.orange,
                isDark: isDark,
              ),
            ],
          ),

          SizedBox(height: 40),

          // الفحوصات الشائعة
          Row(
            children: [
              Text(
                'الفحوصات الشائعة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: Row(
                  children: [
                    Text('عرض الكل',
                        style: TextStyle(color: LabTheme.primaryColor)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward,
                        size: 16, color: LabTheme.primaryColor),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.2,
            children: appModel.allTests.take(6).map((test) {
              final cartItem = appModel.cart.firstWhere(
                (item) => item.test.id == test.id,
                orElse: () => CartItem(test: test, quantity: 0),
              );

              return _buildDashboardTestCard(test, cartItem, appModel);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTestCard(
      MedicalTest test, CartItem cartItem, LabAppModel appModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(test.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(test.category),
                  size: 20,
                  color: _getCategoryColor(test.category),
                ),
              ),
              Spacer(),
              if (cartItem.quantity > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: LabTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cartItem.quantity}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: LabTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            test.nameAr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Text(
            test.descriptionAr,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Spacer(),
          Row(
            children: [
              Text(
                '${test.price} د.ع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: LabTheme.primaryColor,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: LabTheme.primaryColor,
                  size: 24,
                ),
                onPressed: () => appModel.addToCart(test),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // شبكة الفحوصات
  Widget _buildDesktopTestsGrid(LabAppModel appModel, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'جميع الفحوصات الطبية',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'اختر من بين مجموعة واسعة من الفحوصات الطبية الدقيقة',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 32),

        // التصنيفات
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: appModel.categories.map((category) {
              final isSelected = appModel.selectedCategory == category;
              return Container(
                margin: EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) => appModel.setCategory(category),
                  selectedColor: LabTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black),
                  ),
                  backgroundColor:
                      isDark ? Colors.white10 : Colors.grey.shade100,
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 32),

        // الفحوصات
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.1,
            ),
            itemCount: appModel.filteredTests.length,
            itemBuilder: (context, index) {
              final test = appModel.filteredTests[index];
              final cartItem = appModel.cart.firstWhere(
                (item) => item.test.id == test.id,
                orElse: () => CartItem(test: test, quantity: 0),
              );

              return _buildDesktopTestCard(test, cartItem, appModel);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTestCard(
      MedicalTest test, CartItem cartItem, LabAppModel appModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getCategoryColor(test.category).withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(40),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _getCategoryColor(test.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(test.category),
                        size: 24,
                        color: _getCategoryColor(test.category),
                      ),
                    ),
                    Spacer(),
                    if (cartItem.quantity > 0)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: LabTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${cartItem.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  test.nameAr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  test.descriptionAr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacer(),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${test.price} د.ع',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: LabTheme.primaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          test.code,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle,
                            color: cartItem.quantity > 0
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: cartItem.quantity > 0
                              ? () => appModel.removeFromCart(test)
                              : null,
                        ),
                        Text(
                          cartItem.quantity.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            color: LabTheme.primaryColor,
                          ),
                          onPressed: () => appModel.addToCart(test),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // محادثة المساعد الذكي
  Widget _buildDesktopAIChat(LabAppModel appModel, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المساعد الطبي الذكي',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'اسأل عن أعراضك واحصل على اقتراحات الفحوصات المناسبة',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 32),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // قائمة المحادثات
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF252525) : Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    border: Border(
                      right: BorderSide(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LabTheme.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.health_and_safety,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'محادثاتك',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => appModel.clearChat(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: appModel._chatMessages.length > 5
                              ? 5
                              : appModel._chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = appModel._chatMessages[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: message.isUser
                                    ? Colors.blue.withOpacity(0.1)
                                    : LabTheme.primaryColor.withOpacity(0.1),
                                child: Icon(
                                  message.isUser
                                      ? Icons.person
                                      : Icons.health_and_safety,
                                  size: 20,
                                  color: message.isUser
                                      ? Colors.blue
                                      : LabTheme.primaryColor,
                                ),
                              ),
                              title: Text(
                                message.text.length > 30
                                    ? '${message.text.substring(0, 30)}...'
                                    : message.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                '${message.timestamp.hour}:${message.timestamp.minute}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // المحادثة الحالية
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          reverse: true,
                          padding: EdgeInsets.all(24),
                          controller: _chatScrollController,
                          itemCount: appModel._chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = appModel._chatMessages[index];
                            return _buildDesktopChatBubble(
                                message, appModel, isDark);
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                maxLines: 3,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: 'اكتب استفسارك الطبي هنا...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.white10
                                      : Colors.grey.shade50,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LabTheme.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.send, color: Colors.white),
                                onPressed: () async {
                                  final question = _chatController.text.trim();
                                  if (question.isEmpty) return;

                                  appModel.askAIAssistant(question);
                                  _chatController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopChatBubble(
      ChatMessage message, LabAppModel appModel, bool isDark) {
    final isUser = message.isUser;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LabTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 20,
              ),
            ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.5,
                  ),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser
                        ? LabTheme.primaryColor
                        : (isDark ? Colors.white10 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      if (message.suggestedTestCodes != null &&
                          message.suggestedTestCodes!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 12),
                            ...message.suggestedTestCodes!.map((testCode) {
                              final test = appModel.allTests.firstWhere(
                                (t) => t.code == testCode,
                                orElse: () => appModel.allTests[0],
                              );
                              return ListTile(
                                leading: Icon(
                                  _getCategoryIcon(test.category),
                                  color: _getCategoryColor(test.category),
                                ),
                                title: Text(test.nameAr),
                                subtitle: Text('${test.price} د.ع'),
                                trailing: IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () => appModel.addToCart(test),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (isUser)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, LabAppModel appModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسجيل الخروج'),
        content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await appModel.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text('خروج'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'فحوصات الدم': Color(0xFFE74C3C),
      'الهرمونات': Color(0xFF9B59B6),
      'الفيتامينات': Color(0xFFF39C12),
      'الأمراض المعدية': Color(0xFFE67E22),
      'وظائف الأعضاء': Color(0xFF1ABC9C),
      'أخرى': Color(0xFF95A5A6),
    };
    return colors[category] ?? LabTheme.primaryColor;
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'فحوصات الدم': Icons.water_drop,
      'الهرمونات': Icons.insights,
      'الفيتامينات': Icons.eco,
      'الأمراض المعدية': Icons.coronavirus,
      'وظائف الأعضاء': Icons.healing,
      'أخرى': Icons.more_horiz,
    };
    return icons[category] ?? Icons.medical_services;
  }
}

// ----------------------
// 7. تصميم سلة التسوق للشاشات الكبيرة
// ----------------------

class DesktopCartScreen extends StatelessWidget {
  const DesktopCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<LabAppModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Color(0xFFF8FAFC),
      body: Row(
        children: [
          // الشريط الجانبي
          _buildCartSidebar(isDark),

          // المحتوى الرئيسي
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'سلة التسوق',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Spacer(),
                      if (appModel.cart.isNotEmpty)
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_back, size: 20),
                              SizedBox(width: 8),
                              Text('مواصلة التسوق'),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${appModel.cart.length} منتج في السلة',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 32),
                  if (appModel.cart.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 100,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 24),
                            Text(
                              'السلة فارغة',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'أضف فحوصات طبية لتبدأ رحلة العناية بصحتك',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 32),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LabTheme.primaryColor,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text('تصفح الفحوصات'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // قائمة المنتجات
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    isDark ? Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: appModel.cart.map((item) {
                                  return _buildDesktopCartItem(
                                      item, appModel, isDark);
                                }).toList(),
                              ),
                            ),

                            SizedBox(height: 32),

                            // ملخص الطلب
                            Container(
                              padding: EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color:
                                    isDark ? Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ملخص الطلب',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  _buildOrderSummaryRow(
                                    'المجموع الفرعي',
                                    '${appModel.getCartTotalPrice()} د.ع',
                                    isDark,
                                  ),
                                  _buildOrderSummaryRow(
                                    'رسوم الخدمة',
                                    '${(appModel.getCartTotalPrice() * 0.05).round()} د.ع',
                                    isDark,
                                  ),
                                  _buildOrderSummaryRow(
                                    'الضريبة',
                                    '${(appModel.getCartTotalPrice() * 0.05).round()} د.ع',
                                    isDark,
                                  ),
                                  Divider(height: 32),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'المجموع الكلي',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        '${appModel.getCartTotalPrice() + (appModel.getCartTotalPrice() * 0.1).round()} د.ع',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: LabTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 32),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor:
                                                LabTheme.primaryColor,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                            side: BorderSide(
                                                color: LabTheme.primaryColor),
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('متابعة التسوق'),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                LabTheme.primaryColor,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                          ),
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const DesktopPaymentScreen()),
                                          ),
                                          child: Text('إتمام الشراء'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSidebar(bool isDark) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LabTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'إتمام الطلب',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'خطوة واحدة تفصلك عن العناية بصحتك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(32),
              children: [
                _buildStepItem(
                  number: 1,
                  title: 'السلة',
                  subtitle: 'اختيار الفحوصات',
                  isActive: true,
                  isDark: isDark,
                ),
                _buildStepItem(
                  number: 2,
                  title: 'الدفع',
                  subtitle: 'اختيار طريقة الدفع',
                  isActive: false,
                  isDark: isDark,
                ),
                _buildStepItem(
                  number: 3,
                  title: 'التأكيد',
                  subtitle: 'تأكيد الطلب',
                  isActive: false,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int number,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isDark,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? LabTheme.primaryColor
                  : (isDark ? Colors.white10 : Colors.grey.shade100),
              shape: BoxShape.circle,
              border: isActive
                  ? null
                  : Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.grey),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCartItem(
      CartItem item, LabAppModel appModel, bool isDark) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getCategoryColor(item.test.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(item.test.category),
              size: 40,
              color: _getCategoryColor(item.test.category),
            ),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.test.nameAr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: LabTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.test.code,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: LabTheme.primaryColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  item.test.descriptionAr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '${item.test.price * item.quantity} د.ع',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: LabTheme.primaryColor,
                      ),
                    ),
                    Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () => appModel.removeFromCart(item.test),
                          ),
                          Container(
                            width: 40,
                            child: Center(
                              child: Text(
                                item.quantity.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () => appModel.addToCart(item.test),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => appModel.removeFromCart(item.test),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'فحوصات الدم': Color(0xFFE74C3C),
      'الهرمونات': Color(0xFF9B59B6),
      'الفيتامينات': Color(0xFFF39C12),
      'الأمراض المعدية': Color(0xFFE67E22),
      'وظائف الأعضاء': Color(0xFF1ABC9C),
      'أخرى': Color(0xFF95A5A6),
    };
    return colors[category] ?? LabTheme.primaryColor;
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'فحوصات الدم': Icons.water_drop,
      'الهرمونات': Icons.insights,
      'الفيتامينات': Icons.eco,
      'الأمراض المعدية': Icons.coronavirus,
      'وظائف الأعضاء': Icons.healing,
      'أخرى': Icons.more_horiz,
    };
    return icons[category] ?? Icons.medical_services;
  }
}

// ----------------------
// 8. تصميم شاشة الدفع للشاشات الكبيرة
// ----------------------

class DesktopPaymentScreen extends StatefulWidget {
  const DesktopPaymentScreen({super.key});

  @override
  _DesktopPaymentScreenState createState() => _DesktopPaymentScreenState();
}

class _DesktopPaymentScreenState extends State<DesktopPaymentScreen> {
  String _paymentMethod = 'cash';
  final TextEditingController _notesController = TextEditingController();
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<LabAppModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Color(0xFFF8FAFC),
      body: Row(
        children: [
          // الشريط الجانبي
          _buildPaymentSidebar(isDark),

          // المحتوى الرئيسي
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إتمام الطلب',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'أكمل بيانات الطلب النهائية',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 32),

                  // تفاصيل الطلب
                  Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تفاصيل الطلب',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 24),
                        ...appModel.cart.map((item) {
                          return _buildOrderItem(item, appModel, isDark);
                        }).toList(),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // طرق الدفع
                  Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طريقة الدفع',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPaymentMethodCard(
                                'cash',
                                'الدفع عند الاستلام',
                                'ادفع نقداً عند تسليم العينات',
                                Icons.money,
                                Colors.green,
                                isDark,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildPaymentMethodCard(
                                'card',
                                'بطاقة ائتمان',
                                'دفع آمن عبر البطاقات',
                                Icons.credit_card,
                                Colors.blue,
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // معلومات إضافية
                  Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'معلومات إضافية',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 24),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'ملاحظات إضافية للطلب (اختياري)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'أوافق على شروط الخدمة وسياسة الخصوصية',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // زر التأكيد
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: _agreedToTerms
                          ? LabTheme.primaryGradient
                          : LinearGradient(colors: [Colors.grey, Colors.grey]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _agreedToTerms
                          ? [
                              BoxShadow(
                                color: LabTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ]
                          : [],
                    ),
                    child: TextButton(
                      onPressed: _agreedToTerms
                          ? () async {
                              final success = await appModel
                                  .submitOrderToBackend(_paymentMethod);
                              if (success) {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      _buildSuccessDialog(appModel),
                                );
                              }
                            }
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'تأكيد الطلب',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSidebar(bool isDark) {
    final appModel = Provider.of<LabAppModel>(context);
    final total = appModel.getCartTotalPrice();
    final serviceFee = (total * 0.05).round();
    final tax = (total * 0.05).round();
    final grandTotal = total + serviceFee + tax;

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LabTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'الدفع',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                _buildSummaryRow('المجموع الفرعي', '$total د.ع', isDark),
                _buildSummaryRow('رسوم الخدمة', '$serviceFee د.ع', isDark),
                _buildSummaryRow('الضريبة', '$tax د.ع', isDark),
                Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المجموع الكلي',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '$grandTotal د.ع',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: LabTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'معلومة هامة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'سيتم الاتصال بك خلال 24 ساعة لتأكيد الموعد وجمع العينات',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item, LabAppModel appModel, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getCategoryColor(item.test.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(item.test.category),
              color: _getCategoryColor(item.test.category),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.test.nameAr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${item.quantity} × ${item.test.price} د.ع',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.quantity * item.test.price} د.ع',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: LabTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final isSelected = _paymentMethod == value;

    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : (isDark ? Colors.white10 : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // أضف هذه الدالة داخل كلاس _DesktopPaymentScreenState
  Widget _buildSuccessDialog(LabAppModel appModel) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.check, color: Colors.green, size: 50),
            ),
            SizedBox(height: 24),
            Text('تم بنجاح!',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            SizedBox(height: 16),
            Text('تم إرسال طلبك بنجاح\nسيتم الاتصال بك قريباً',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: LabTheme.primaryColor,
                    padding: EdgeInsets.all(16)),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text('حسناً', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'فحوصات الدم': Color(0xFFE74C3C),
      'الهرمونات': Color(0xFF9B59B6),
      'الفيتامينات': Color(0xFFF39C12),
      'الأمراض المعدية': Color(0xFFE67E22),
      'وظائف الأعضاء': Color(0xFF1ABC9C),
      'أخرى': Color(0xFF95A5A6),
    };
    return colors[category] ?? LabTheme.primaryColor;
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'فحوصات الدم': Icons.water_drop,
      'الهرمونات': Icons.insights,
      'الفيتامينات': Icons.eco,
      'الأمراض المعدية': Icons.coronavirus,
      'وظائف الأعضاء': Icons.healing,
      'أخرى': Icons.more_horiz,
    };
    return icons[category] ?? Icons.medical_services;
  }
}

// ----------------------
// 9. تصميم سجل الطلبات للشاشات الكبيرة
// ----------------------

class DesktopOrderHistoryScreen extends StatelessWidget {
  const DesktopOrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<LabAppModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Color(0xFFF8FAFC),
      body: Row(
        children: [
          // الشريط الجانبي
          _buildHistorySidebar(isDark),

          // المحتوى الرئيسي
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'سجل الطلبات',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Spacer(),
                      Container(
                        width: 300,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'ابحث في الطلبات...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${appModel.orders.length} طلب سابق',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 32),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: appModel.orders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 100,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    'لا توجد طلبات سابقة',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'عندما تقوم بعمل طلب، سيظهر هنا',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              child: DataTable(
                                columns: [
                                  DataColumn(label: Text('رقم الطلب')),
                                  DataColumn(label: Text('التاريخ')),
                                  DataColumn(label: Text('المنتجات')),
                                  DataColumn(label: Text('المجموع')),
                                  DataColumn(label: Text('الحالة')),
                                  DataColumn(label: Text('الإجراءات')),
                                ],
                                rows: appModel.orders.map((order) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(order.orderNumber)),
                                      DataCell(Text(
                                          '${order.date.day}/${order.date.month}/${order.date.year}')),
                                      DataCell(
                                          Text('${order.items.length} منتج')),
                                      DataCell(
                                          Text('${order.totalAmount} د.ع')),
                                      DataCell(
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(order.status)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _getStatusText(order.status),
                                            style: TextStyle(
                                              color:
                                                  _getStatusColor(order.status),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.remove_red_eye,
                                                  size: 20),
                                              onPressed: () {},
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.print, size: 20),
                                              onPressed: () {},
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySidebar(bool isDark) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LabTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'سجل الطلبات',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تصفية حسب',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 16),
                ...[
                  'جميع الطلبات',
                  'قيد الانتظار',
                  'قيد التنفيذ',
                  'مكتمل',
                  'ملغي'
                ].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Checkbox(value: false, onChanged: (v) {}),
                        SizedBox(width: 8),
                        Text(filter),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'قيد الانتظار';
      case 'PROCESSING':
        return 'قيد التنفيذ';
      case 'COMPLETED':
        return 'مكتمل';
      case 'CANCELLED':
        return 'ملغي';
      default:
        return status;
    }
  }
}

// ----------------------
// 10. تصميم الملف الشخصي للشاشات الكبيرة (تم إضافة زر الرجوع)
// ----------------------

class DesktopProfileScreen extends StatefulWidget {
  const DesktopProfileScreen({super.key});

  @override
  _DesktopProfileScreenState createState() => _DesktopProfileScreenState();
}

class _DesktopProfileScreenState extends State<DesktopProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    final appModel = Provider.of<LabAppModel>(context, listen: false);
    _nameController.text = appModel.userName;
    _phoneController.text = appModel.userPhone;
    _emailController.text = appModel.userEmail;
    _addressController.text = appModel.userAddress;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<LabAppModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Color(0xFFF8FAFC),
      body: Row(
        children: [
          // الشريط الجانبي
          _buildProfileSidebar(appModel, isDark),

          // المحتوى الرئيسي
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- رأس الصفحة مع زر الرجوع (جديد) ---
                  Row(
                    children: [
                      // زر الرجوع
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: isDark ? Colors.white : Colors.black),
                          onPressed: () =>
                              Navigator.pop(context), // الرجوع للرئيسية
                          tooltip: 'الرجوع',
                        ),
                      ),
                      SizedBox(width: 20),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الملف الشخصي',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'إدارة معلومات حسابك الشخصي',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 32),

                  // معلومات المستخدم
                  Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المعلومات الشخصية',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 24),
                        GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 3,
                          children: [
                            _buildTextField('الاسم الكامل', _nameController),
                            _buildTextField('رقم الهاتف', _phoneController),
                            _buildTextField(
                                'البريد الإلكتروني', _emailController),
                            _buildTextField('العنوان', _addressController),
                          ],
                        ),
                        SizedBox(height: 32),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LabTheme.primaryColor,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                              ),
                              onPressed: () async {
                                final success = await appModel.updateProfile(
                                  name: _nameController.text,
                                  phone: _phoneController.text,
                                  email: _emailController.text,
                                  address: _addressController.text,
                                );
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم تحديث المعلومات بنجاح',
                                          style:
                                              TextStyle(fontFamily: 'Cairo')),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              child: Text('حفظ التغييرات',
                                  style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Colors.white)),
                            ),
                            SizedBox(width: 16),
                            OutlinedButton(
                              onPressed: () {
                                _nameController.text = appModel.userName;
                                _phoneController.text = appModel.userPhone;
                                _emailController.text = appModel.userEmail;
                                _addressController.text = appModel.userAddress;
                              },
                              child: Text('إلغاء',
                                  style: TextStyle(fontFamily: 'Cairo')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // الإعدادات
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSidebar(LabAppModel appModel, bool isDark) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LabTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  appModel.userName.isNotEmpty ? appModel.userName : 'مستخدم',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  appModel.userEmail.isNotEmpty
                      ? appModel.userEmail
                      : 'user@example.com',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: LabTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'عميل مميز',
                    style: TextStyle(
                      color: LabTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(32),
              children: [
                _buildProfileMenuItem(
                  icon: Icons.person,
                  label: 'الملف الشخصي',
                  isActive: true,
                ),
                _buildProfileMenuItem(
                  icon: Icons.security,
                  label: 'الأمان',
                  isActive: false,
                ),
                _buildProfileMenuItem(
                  icon: Icons.payment,
                  label: 'الدفع',
                  isActive: false,
                ),
                _buildProfileMenuItem(
                  icon: Icons.help,
                  label: 'المساعدة',
                  isActive: false,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(32),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () => _showLogoutDialog(context, appModel),
              icon: Icon(Icons.logout, color: Colors.white),
              label: Text('تسجيل الخروج',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? LabTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive
              ? LabTheme.primaryColor
              : (isDark ? Colors.white70 : Colors.grey),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive
                ? LabTheme.primaryColor
                : (isDark ? Colors.white : Colors.black),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Cairo',
          ),
        ),
        trailing: isActive
            ? Icon(Icons.arrow_left, color: LabTheme.primaryColor)
            : Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black, fontFamily: 'Cairo'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: LabTheme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: LabTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontFamily: 'Cairo',
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: LabTheme.primaryColor,
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: LabTheme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: LabTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontFamily: 'Cairo',
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, LabAppModel appModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟',
            style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await appModel.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text('خروج',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
// ----------------------
// 11. تعديل HomeScreen الرئيسي ليستخدم التصميم المتجاوب
// ----------------------

class ResponsiveHomeScreen extends StatelessWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScreen: HomeScreen(),
      desktopScreen: DesktopHomeScreen(),
    );
  }
}

// ----------------------
// 12. تعديل main لتشغيل التصميم المتجاوب
// ----------------------

// في main.dart أو ملف التطبيق الرئيسي، استبدل:
// home: HomeScreen(),
// بـ:
// home: ResponsiveHomeScreen(),

// ----------------------
// 13. توصيل الشاشات الجديدة
// ----------------------

// تأكد من تحديث الروابط في الشريط الجانبي والشاشات الأخرى
// لتشير إلى الشاشات الجديدة (DesktopCartScreen, DesktopPaymentScreen, etc.)

// ------------------------------------------------------
// ✅ ويدجت السلايدر المتحرك للعروض (Promo Carousel)
// ------------------------------------------------------
// ------------------------------------------------------
// ✅ ويدجت السلايدر المتحرك للعروض (النسخة الجديدة)
// ------------------------------------------------------
// ------------------------------------------------------
// ✅ ويدجت السلايدر المتحرك للعروض (تم تطبيق الأسعار التسويقية)
// ------------------------------------------------------
class _PromoCarousel extends StatefulWidget {
  final Function(MedicalTest) onOfferTap;
  const _PromoCarousel({required this.onOfferTap});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  // ✅ القائمة الشاملة لجميع العروض والباقات
  final List<Map<String, dynamic>> _slides = [
    // --- العروض القديمة الأساسية ---
    {
      "test": MedicalTest(
          id: 'promo_friday',
          nameAr: 'عرض يوم الجمعة!',
          nameEn: 'Friday Offer',
          code: 'FRI50',
          price: 0,
          category: 'عروض',
          descriptionAr: 'تخفيض 50% على كافة التحاليل',
          descriptionEn: '50% off all tests',
          keywords: []),
      "discount": "50%",
      "icon": Icons.local_fire_department,
      "color": Colors.amber,
    },
    {
      "test": MedicalTest(
          id: 'promo_week',
          nameAr: 'عرض لمدة أسبوع',
          nameEn: 'One Week Offer',
          code: 'WEEK39',
          price: 39000,
          category: 'عروض',
          descriptionAr: 'بدل 125 الف! فرصة لا تعوض',
          descriptionEn: 'Limited time offer',
          keywords: []),
      "discount": "39K",
      "icon": Icons.timer,
      "color": Colors.redAccent,
    },
    {
      "test": MedicalTest(
          id: 'promo_pcos',
          nameAr: 'فحص تكيس المبايض',
          nameEn: 'PCOS Test',
          code: 'PCOS49',
          price: 49000,
          category: 'عروض',
          descriptionAr: 'تحاليل الهرمونات والانسولين',
          descriptionEn: 'Includes hormones, insulin, FBS',
          keywords: []),
      "discount": "49K",
      "icon": Icons.pregnant_woman,
      "color": Colors.pinkAccent,
    },
    {
      "test": MedicalTest(
          id: 'promo_hair',
          nameAr: 'برنامج تساقط الشعر',
          nameEn: 'Hair Loss Program',
          code: 'HAIR39',
          price: 39000,
          category: 'عروض',
          descriptionAr: 'لمعرفة أسباب التساقط وعلاجها',
          descriptionEn: 'Find out the causes of hair loss',
          keywords: []),
      "discount": "39K",
      "icon": Icons.face_retouching_natural,
      "color": Colors.brown,
    },
    {
      "test": MedicalTest(
          id: 'promo_vitamins',
          nameAr: 'الفيتامينات والمعادن',
          nameEn: 'Vitamins & Minerals',
          code: 'VIT49',
          price: 49000,
          category: 'عروض',
          descriptionAr: 'فحص شامل للفيتامينات الأساسية',
          descriptionEn: 'Comprehensive vitamins check',
          keywords: []),
      "discount": "49K",
      "icon": Icons.medication,
      "color": Colors.orangeAccent,
    },
    {
      "test": MedicalTest(
          id: 'promo_kids',
          nameAr: 'برنامج فحص الأطفال',
          nameEn: 'Kids Checkup',
          code: 'KIDS49',
          price: 49000,
          category: 'عروض',
          descriptionAr: 'صحة طفلك أمانة عندك',
          descriptionEn: 'Keep your child safe',
          keywords: []),
      "discount": "49K",
      "icon": Icons.child_care,
      "color": Colors.lightGreenAccent,
    },
    {
      "test": MedicalTest(
          id: 'promo_thyroid',
          nameAr: 'فحص الغدة الدرقية',
          nameEn: 'Thyroid Test',
          code: 'THY25',
          price: 25000,
          category: 'عروض',
          descriptionAr: 'يشمل: TSH, T3, T4',
          descriptionEn: 'TSH, T3, T4',
          keywords: []),
      "discount": "25K",
      "icon": Icons.medical_services_outlined,
      "color": Colors.white,
    },
    {
      "test": MedicalTest(
          id: 'promo_comp',
          nameAr: 'فحص القمة الشامل',
          nameEn: 'Comprehensive Test',
          code: 'COMP35',
          price: 35000,
          category: 'عروض',
          descriptionAr: 'اطمئن على صحتك بسعر رمزي',
          descriptionEn: 'Check your health',
          keywords: []),
      "discount": "35K",
      "icon": Icons.monitor_heart_outlined,
      "color": Colors.cyanAccent,
    },

    // --- الباقات الـ 13 الجديدة ---
    {
      "test": MedicalTest(
          id: 'pkg_foreign_workers',
          nameAr: 'باقة العاملات الأجنبيات',
          nameEn: 'Foreign Workers Pkg',
          code: 'FW30',
          price: 30000,
          category: 'عروض',
          descriptionAr: 'لأغراض الإقامة والعمل',
          descriptionEn: '',
          keywords: []),
      "discount": "30K",
      "icon": Icons.badge,
      "color": Colors.tealAccent,
    },
    {
      "test": MedicalTest(
          id: 'pkg_female_hormones',
          nameAr: 'هرمونات نسائية',
          nameEn: 'Female Hormones',
          code: 'FH39',
          price: 39000,
          category: 'عروض',
          descriptionAr: 'تأخر الحمل، الدورة، تكيس المبايض',
          descriptionEn: '',
          keywords: []),
      "discount": "39K",
      "icon": Icons.female,
      "color": Colors.pink,
    },
    {
      "test": MedicalTest(
          id: 'pkg_pregnancy_delay',
          nameAr: 'تأخر الحمل (للنساء)',
          nameEn: 'Pregnancy Delay Pkg',
          code: 'PRG75',
          price: 75000,
          category: 'عروض',
          descriptionAr: 'خطوة أولى لتقييم الخصوبة',
          descriptionEn: '',
          keywords: []),
      "discount": "75K",
      "icon": Icons.child_friendly,
      "color": Colors.purpleAccent,
    },
    {
      "test": MedicalTest(
          id: 'pkg_male_hormones',
          nameAr: 'هرمونات رجالية',
          nameEn: 'Male Hormones',
          code: 'MH39',
          price: 39000,
          category: 'عروض',
          descriptionAr: 'ضعف عام، تساقط شعر، خصوبة',
          descriptionEn: '',
          keywords: []),
      "discount": "39K",
      "icon": Icons.male,
      "color": Colors.blueAccent,
    },
    {
      "test": MedicalTest(
          id: 'pkg_anemia',
          nameAr: 'فقر الدم الشامل',
          nameEn: 'Anemia Pkg',
          code: 'ANM39',
          price: 39000,
          category: 'عروض',
          descriptionAr: 'إرهاق، دوخة، شحوب',
          descriptionEn: '',
          keywords: []),
      "discount": "39K",
      "icon": Icons.bloodtype,
      "color": Colors.red,
    },
    {
      "test": MedicalTest(
          id: 'pkg_heart_lipids',
          nameAr: 'القلب والدهون',
          nameEn: 'Heart & Lipids Pkg',
          code: 'HL29',
          price: 29000,
          category: 'عروض',
          descriptionAr: 'للاطمئنان على صحة القلب',
          descriptionEn: '',
          keywords: []),
      "discount": "29K",
      "icon": Icons.favorite,
      "color": Colors.redAccent,
    },
    {
      "test": MedicalTest(
          id: 'pkg_fatigue_hair',
          nameAr: 'الإرهاق والتساقط',
          nameEn: 'Fatigue & Hair Pkg',
          code: 'FH39',
          price: 39000,
          category: 'عروض',
          descriptionAr: 'تعب دائم، دوخة، تساقط',
          descriptionEn: '',
          keywords: []),
      "discount": "39K",
      "icon": Icons.battery_alert,
      "color": Colors.blueGrey,
    },
    {
      "test": MedicalTest(
          id: 'pkg_diabetes',
          nameAr: 'السكري الشامل',
          nameEn: 'Diabetes Pkg',
          code: 'DIA39',
          price: 39000,
          category: 'عروض',
          descriptionAr: 'للإطمئنان أو لمرضى السكري',
          descriptionEn: '',
          keywords: []),
      "discount": "39K",
      "icon": Icons.monitor_weight,
      "color": Colors.purple,
    },
    {
      "test": MedicalTest(
          id: 'pkg_clots',
          nameAr: 'القلب والجلطات',
          nameEn: 'Heart & Clots Pkg',
          code: 'HC75',
          price: 75000,
          category: 'عروض',
          descriptionAr: 'فوق 35 سنة أو تاريخ عائلي',
          descriptionEn: '',
          keywords: []),
      "discount": "75K",
      "icon": Icons.monitor_heart,
      "color": Colors.red,
    },
    {
      "test": MedicalTest(
          id: 'pkg_marriage',
          nameAr: 'فحص قبل الزواج',
          nameEn: 'Pre-Marriage Pkg',
          code: 'MAR49',
          price: 49000,
          category: 'عروض',
          descriptionAr: 'فحص ضروري لكل شاب وبنية',
          descriptionEn: '',
          keywords: []),
      "discount": "49K",
      "icon": Icons.favorite_border,
      "color": Colors.greenAccent,
    },
    {
      "test": MedicalTest(
          id: 'pkg_fatigue_top',
          nameAr: 'الإرهاق الشامل',
          nameEn: 'Top Fatigue Pkg',
          code: 'TF49',
          price: 49000,
          category: 'عروض',
          descriptionAr: 'الأكثر طلباً للتعب المستمر',
          descriptionEn: '',
          keywords: []),
      "discount": "49K",
      "icon": Icons.bed,
      "color": Colors.deepPurpleAccent,
    },
    {
      "test": MedicalTest(
          id: 'pkg_ramadan',
          nameAr: 'الشامل الرمضاني',
          nameEn: 'Ramadan Pkg',
          code: 'RAM39',
          price: 39000,
          category: 'عروض',
          descriptionAr: 'اطمئنان كامل قبل رمضان',
          descriptionEn: '',
          keywords: []),
      "discount": "39K",
      "icon": Icons.nightlight_round,
      "color": Colors.amberAccent,
    },
    {
      "test": MedicalTest(
          id: 'pkg_energy',
          nameAr: 'باقة 1: الطاقة والصحة',
          nameEn: 'Energy Pkg',
          code: 'ENG35',
          price: 35000,
          category: 'عروض',
          descriptionAr: 'للتعب وتساقط الشعر والدوخة',
          descriptionEn: '',
          keywords: []),
      "discount": "35K",
      "icon": Icons.bolt,
      "color": Colors.yellowAccent,
    },

    // --- الإضافات الخمسة الجديدة ---
    {
      "test": MedicalTest(
          id: 'pkg_sports_general',
          nameAr: 'باقة الرياضيين',
          nameEn: 'Sports General',
          code: 'SPT59',
          price: 59000,
          category: 'عروض',
          descriptionAr: 'فحص الأداء والصحة العامة',
          descriptionEn: '',
          keywords: []),
      "discount": "59K",
      "icon": Icons.fitness_center,
      "color": Colors.orange,
    },
    {
      "test": MedicalTest(
          id: 'pkg_obesity',
          nameAr: 'باقة فحص السمنة',
          nameEn: 'Obesity Pkg',
          code: 'OBS59',
          price: 59000,
          category: 'عروض',
          descriptionAr: 'فحص شامل لمخاطر الوزن الزائد',
          descriptionEn: '',
          keywords: []),
      "discount": "59K",
      "icon": Icons.fastfood,
      "color": Colors.deepOrangeAccent,
    },
    {
      "test": MedicalTest(
          id: 'pkg_sports_hormones',
          nameAr: 'هرمونات الرياضيين',
          nameEn: 'Sports Hormones',
          code: 'SPH69',
          price: 69000,
          category: 'عروض',
          descriptionAr: 'الفحوصات الهرمونية للرياضيين',
          descriptionEn: '',
          keywords: []),
      "discount": "69K",
      "icon": Icons.sports_gymnastics,
      "color": Colors.blue,
    },
    {
      "test": MedicalTest(
          id: 'pkg_minerals',
          nameAr: 'باقة العناصر المعدنية',
          nameEn: 'Minerals Pkg',
          code: 'MIN29',
          price: 29000,
          category: 'عروض',
          descriptionAr: 'لتعب مزمن أو هشاشة عظام',
          descriptionEn: '',
          keywords: []),
      "discount": "29K",
      "icon": Icons.science,
      "color": Colors.teal,
    },
    {
      "test": MedicalTest(
          id: 'pkg_grand_full_body',
          nameAr: 'الباقة الكبرى الموسعة',
          nameEn: 'Grand Full Body',
          code: 'GFB225',
          price: 225000,
          category: 'عروض',
          descriptionAr: 'فحص شامل لكل الجسم تقريباً',
          descriptionEn: '',
          keywords: []),
      "discount": "225K",
      "icon": Icons.health_and_safety,
      "color": Colors.indigoAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    Future.delayed(const Duration(seconds: 4), _autoSlide);
  }

  void _autoSlide() {
    if (!mounted) return;
    setState(() {
      if (_currentPage < _slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
    });
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 800),
      curve: Curves.fastOutSlowIn,
    );
    Future.delayed(const Duration(seconds: 4), _autoSlide);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _buildSlideCard(slide);
            },
          ),
        ),
        const SizedBox(height: 8),
        // تعديل نقاط المؤشر لتناسب العدد الكبير من العروض (Scrollable Dots)
        SizedBox(
          height: 10,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentPage == index ? 20 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? LabTheme.primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideCard(Map<String, dynamic> slide) {
    final MedicalTest test = slide['test'];

    return GestureDetector(
      onTap: () => widget.onOfferTap(test),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF10B981)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                slide['discount'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(slide['icon'], color: slide['color'], size: 20),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          test.nameAr,
                          style: TextStyle(
                            color: slide['color'],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    test.descriptionAr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
