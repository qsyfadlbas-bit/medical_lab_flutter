import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/services/api_service.dart';
import 'package:medical_lab_flutter/screens/admin/orders_log_screen.dart';
import 'package:medical_lab_flutter/screens/admin/manage_tests_screen.dart';
import 'package:medical_lab_flutter/providers/auth_provider.dart';
import 'package:medical_lab_flutter/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;

  // الإحصائيات
  int _totalOrders = 0;
  int _totalRevenue = 0;
  int _totalTests = 0;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // 1. جلب الطلبات لحساب العدد والإيرادات
      final ordersRes = await _apiService.get('/orders');
      if (ordersRes.statusCode == 200) {
        // ✅ استخدام safeJsonDecode بدلاً من json.decode
        final body = ApiService.safeJsonDecode(ordersRes);
        if (body != null && body['data'] != null) {
          final ordersData = body['data'] as List;
          int revenue = 0;
          for (var order in ordersData) {
            if (order['status'] == 'COMPLETED' ||
                order['status'] == 'PROCESSING') {
              revenue += (order['totalAmount'] as num?)?.toInt() ?? 0;
            }
          }
          _totalOrders = ordersData.length;
          _totalRevenue = revenue;
        }
      }

      // 2. جلب عدد التحاليل
      final testsRes = await _apiService.get('/tests');
      if (testsRes.statusCode == 200) {
        final body = ApiService.safeJsonDecode(testsRes);
        if (body != null && body['data'] != null) {
          _totalTests = (body['data'] as List).length;
        }
      }

      // 3. جلب عدد المستخدمين
      final usersRes = await _apiService.get('/users');
      if (usersRes.statusCode == 200) {
        final body = ApiService.safeJsonDecode(usersRes);
        if (body != null && body['data'] != null) {
          _totalUsers = (body['data'] as List).length;
        }
      }
    } catch (e) {
      print("Dashboard Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في جلب البيانات: ${e.toString().contains("Timeout") ? "السيرفر بطيء" : "تحقق من الاتصال"}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('لوحة إدارة المختبر',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F51B5),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
          tooltip: 'تسجيل خروج',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'أهلاً بك أيها المدير،',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F51B5),
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'إليك ملخص سريع لما يحدث في المختبر اليوم.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 25),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard(
                      title: 'الإيرادات (د.ع)',
                      value: '$_totalRevenue',
                      icon: Icons.attach_money,
                      color: const Color(0xFF4CAF50),
                    ),
                    _buildStatCard(
                      title: 'الطلبات الكلية',
                      value: '$_totalOrders',
                      icon: Icons.shopping_cart,
                      color: const Color(0xFFFF9800),
                    ),
                    _buildStatCard(
                      title: 'التحاليل النشطة',
                      value: '$_totalTests',
                      icon: Icons.science,
                      color: const Color(0xFF2196F3),
                    ),
                    _buildStatCard(
                      title: 'المستخدمين',
                      value: '$_totalUsers',
                      icon: Icons.people,
                      color: const Color(0xFF009688),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              const Text(
                'التحكم السريع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: 'سجل الطلبات',
                      icon: Icons.assignment,
                      iconColor: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OrdersLogScreen()),
                        ).then((_) => _fetchDashboardData());
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionCard(
                      title: 'إدارة التحاليل',
                      icon: Icons.biotech,
                      iconColor: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ManageTestsScreen()),
                        ).then((_) => _fetchDashboardData());
                      },
                    ),
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
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      {required String title,
      required IconData icon,
      required Color iconColor,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
