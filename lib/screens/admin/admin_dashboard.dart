import 'dart:convert';
import 'dart:async'; // مكتبة المؤقت
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medical_lab_flutter/providers/auth_provider.dart';
import 'package:medical_lab_flutter/services/api_service.dart';
import 'package:medical_lab_flutter/screens/auth/login_screen.dart';
import 'package:gap/gap.dart';

// ✅ استيراد الصفحات الفرعية
import 'package:medical_lab_flutter/screens/admin/manage_tests_screen.dart';
import 'package:medical_lab_flutter/screens/admin/orders_log_screen.dart';
import 'package:medical_lab_flutter/screens/admin/users_list_screen.dart';
import 'package:medical_lab_flutter/screens/admin/admin_settings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  String _ordersCount = '0';
  String _usersCount = '0';
  String _revenue = '0';

  // متغيرات للإشعارات
  Timer? _timer;
  int _lastOrdersCount = -1; // نبدأ بـ -1 لنتأكد أن أول تحميل لا يطلق إشعاراً

  @override
  void initState() {
    super.initState();
    // جلب البيانات فوراً عند الفتح
    _fetchStats(firstTime: true);

    // ✅ جعلنا المؤقت كل 5 ثواني للتجربة السريعة
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkNewOrders();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ✅ التحقق من الطلبات الجديدة في الخلفية
  Future<void> _checkNewOrders() async {
    try {
      // طباعة للتأكد أن الوظيفة تعمل
      print("🔄 Checking for new orders...");

      final response = await _apiService.get('/orders');
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        int currentCount = data.length;

        print("📊 Current: $currentCount, Last: $_lastOrdersCount");

        // إذا كان هذا ليس أول تحميل، والعدد الجديد أكبر من القديم
        if (_lastOrdersCount != -1 && currentCount > _lastOrdersCount) {
          print("🔔 NEW ORDER DETECTED!");
          _showNotification();
          _fetchStats(); // تحديث الواجهة
        }

        // تحديث الرقم الأخير دائماً
        _lastOrdersCount = currentCount;
      }
    } catch (e) {
      print("❌ Error checking orders: $e");
    }
  }

  // ✅ عرض إشعار احترافي
  void _showNotification() {
    // تشغيل صوت أو اهتزاز هنا لو أردت مستقبلاً
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🔔 طلب جديد!",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Cairo')),
                  Text("وصل طلب تحليل جديد الآن",
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent, // لون ملفت للانتباه
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.only(
            top: 20, left: 10, right: 10, bottom: 20), // مكان ظهور الإشعار
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'مشاهدة',
          textColor: Colors.yellow,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrdersLogScreen()),
            );
          },
        ),
      ),
    );
  }

  // ✅ جلب الإحصائيات وتحديث الواجهة
  Future<void> _fetchStats({bool firstTime = false}) async {
    try {
      final ordersRes = await _apiService.get('/orders');
      final usersRes = await _apiService.get('/users');

      if (ordersRes.statusCode == 200 && usersRes.statusCode == 200) {
        final ordersData = json.decode(ordersRes.body)['data'] as List;
        final usersData = json.decode(usersRes.body)['data'] as List;

        // عند فتح التطبيق لأول مرة، نحفظ العدد الحالي فقط دون إشعار
        if (firstTime) {
          _lastOrdersCount = ordersData.length;
        }

        // حساب المجموع الكلي للإيرادات
        double totalRevenue = 0;
        for (var order in ordersData) {
          totalRevenue += (order['totalAmount'] ?? 0);
        }

        if (mounted) {
          setState(() {
            _ordersCount = ordersData.length.toString();
            _usersCount = usersData.length.toString();
            _revenue = totalRevenue > 1000
                ? '${(totalRevenue / 1000).toStringAsFixed(1)}K'
                : totalRevenue.toStringAsFixed(0);
          });
        }
      }
    } catch (e) {
      print("Error fetching stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('لوحة إدارة المختبر',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Cairo')),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _fetchStats(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen(userType: 'User')),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ترحيب
              const Text(
                'أهلاً بك أيها المدير،',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Colors.indigo),
              ),
              const Text(
                'إليك ملخص سريع لما يحدث في المختبر اليوم.',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey, fontFamily: 'Cairo'),
              ),
              const Gap(20),

              // إحصائيات سريعة
              Row(
                children: [
                  _buildStatCard('الطلبات الكلية', _ordersCount, Colors.orange,
                      Icons.shopping_cart),
                  const Gap(16),
                  _buildStatCard('الإيرادات (د.ع)', _revenue, Colors.green,
                      Icons.attach_money),
                ],
              ),
              const Gap(16),
              // صف ثاني للإحصائيات
              Row(
                children: [
                  _buildStatCard(
                      'المستخدمين', _usersCount, Colors.teal, Icons.people),
                  const Gap(16),
                  _buildStatCard(
                      'التحاليل النشطة', '∞', Colors.blue, Icons.science),
                ],
              ),
              const Gap(24),

              const Text(
                'التحكم السريع',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo'),
              ),
              const Gap(16),

              // شبكة التحكم
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    context,
                    title: 'إدارة التحاليل',
                    icon: Icons.science,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ManageTestsScreen()));
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'سجل الطلبات',
                    icon: Icons.assignment,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OrdersLogScreen()));
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'المستخدمين',
                    icon: Icons.people_alt,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const UsersListScreen()));
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'الإعدادات',
                    icon: Icons.settings,
                    color: Colors.grey,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AdminSettingsScreen()));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const Gap(10),
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(title,
                style: const TextStyle(
                    fontSize: 14, color: Colors.white70, fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
            const Gap(12),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }
}
