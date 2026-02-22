import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/widgets/cards/inspection_card.dart';
import 'package:medical_lab_flutter/widgets/cards/order_card.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:medical_lab_flutter/providers/user_provider.dart';
import 'package:medical_lab_flutter/providers/order_provider.dart';
import 'package:medical_lab_flutter/providers/inspection_provider.dart';
import 'package:medical_lab_flutter/widgets/common/stats_card.dart';
import 'package:medical_lab_flutter/screens/user/new_order_screen.dart';
import 'package:medical_lab_flutter/screens/user/inspections_screen.dart';
import 'package:medical_lab_flutter/screens/user/orders_screen.dart';

// ✅ التغيير 1: سمينا الكلاس UserDashboard ليكون واضحاً ومختلفاً عن HomeScreen
class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

// ✅ التغيير 2: تحديث اسم الـ State
class _UserDashboardState extends State<UserDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // التأكد من أن الشجرة مبنية قبل استدعاء البروفايدر
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final inspectionProvider =
          Provider.of<InspectionProvider>(context, listen: false);

      await Future.wait([
        orderProvider.fetchUserOrders(),
        inspectionProvider.fetchUserInspections(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final inspectionProvider = Provider.of<InspectionProvider>(context);

    // تعريف المتغير
    final upcomingInspections = inspectionProvider.upcomingInspections;

    return Scaffold(
      // ✅ أضفنا Scaffold ليكون الهيكل صحيحاً
      appBar: AppBar(
        title: const Text('لوحة التحكم', style: TextStyle(fontFamily: 'Cairo')),
        automaticallyImplyLeading: false, // إلغاء زر الرجوع لمنع الخروج بالخطأ
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً ${userProvider.currentUser?.name ?? 'عزيزي'} 👋',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const Gap(8),
                          const Text(
                            'نتمنى لك يومًا صحياً ومليئاً بالطاقة',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),

              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'طلبات نشطة',
                      value: orderProvider.activeOrders.length.toString(),
                      icon: Icons.shopping_bag,
                      color: Colors.blue,
                      progress: 0.12,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: StatsCard(
                      title: 'فحوصات',
                      value: inspectionProvider.inspections.length.toString(),
                      icon: Icons.assignment,
                      color: Colors.purple,
                      progress: 0.08,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: StatsCard(
                      title: 'مكتمل',
                      value: inspectionProvider.completedInspections.length
                          .toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                      progress: 0.15,
                    ),
                  ),
                ],
              ),
              const Gap(24),

              // Quick Actions
              const Text(
                'إجراءات سريعة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const Gap(12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildQuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'طلب جديد',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewOrderScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.calendar_today,
                    label: 'جدولة فحص',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InspectionsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.document_scanner,
                    label: 'تقرير فحص',
                    color: Colors.green,
                    onTap: () {
                      // TODO: Navigate to reports screen
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.location_on,
                    label: 'مواقع المختبرات',
                    color: Colors.orange,
                    onTap: () {
                      // TODO: Navigate to locations screen
                    },
                  ),
                ],
              ),
              const Gap(24),

              // Recent Orders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'طلباتي الأخيرة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrdersScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'عرض الكل',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
              const Gap(12),
              if (orderProvider.orders.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Center(
                    child: Text(
                      'لا توجد طلبات حالية',
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: orderProvider.orders
                      .take(3)
                      .map((order) => OrderCard(
                            order: order,
                            onTap: () {
                              // TODO: Navigate to order details
                            },
                          ))
                      .toList(),
                ),
              const Gap(24),

              // Recent Inspections
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'فحوصاتي الأخيرة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InspectionsScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'عرض الكل',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
              const Gap(12),
              if (inspectionProvider.inspections.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Center(
                    child: Text(
                      'لا توجد فحوصات حالية',
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: inspectionProvider.inspections
                      .take(3)
                      .map((inspection) => InspectionCard(
                            inspection: inspection,
                            onTap: () {
                              // TODO: Navigate to inspection details
                            },
                          ))
                      .toList(),
                ),
              const Gap(24),

              // Upcoming Inspections
              if (upcomingInspections.isNotEmpty) ...[
                const Text(
                  'فحوصات قادمة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const Gap(12),
                Column(
                  children: upcomingInspections
                      .take(2)
                      .map((inspection) => InspectionCard(
                            inspection: inspection,
                            onTap: () {
                              // TODO: Navigate to inspection details
                            },
                          ))
                      .toList(),
                ),
                const Gap(24),
              ],

              // Health Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.lightBlue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.lightBlue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          color: Colors.lightBlue[700],
                        ),
                        const Gap(8),
                        const Text(
                          'نصيحة صحية',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    Text(
                      'احرص على إجراء الفحوصات الدورية للاطمئنان على صحتك. الفحص المبكر ينقذ الأرواح.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[800],
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const Gap(12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
