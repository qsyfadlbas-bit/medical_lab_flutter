import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/screens/user/home_screen.dart';
import 'package:medical_lab_flutter/screens/user/orders_screen.dart';
import 'package:medical_lab_flutter/screens/user/inspections_screen.dart';
import 'package:medical_lab_flutter/screens/user/profile_screen.dart';
import 'package:medical_lab_flutter/screens/user/support_screen.dart';
import 'package:medical_lab_flutter/widgets/common/custom_app_bar.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:medical_lab_flutter/providers/user_provider.dart';
import 'package:medical_lab_flutter/widgets/common/custom_app_bar.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const UserDashboard(),
    const OrdersScreen(),
    const InspectionsScreen(),
    const ProfileScreen(),
    const SupportScreen(),
  ];

  final List<String> _screenTitles = [
    'الرئيسية',
    'طلباتي',
    'فحوصاتي',
    'الملف الشخصي',
    'الدعم',
  ];

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    return Scaffold(
      appBar: CustomAppBar(
        title: _screenTitles[_selectedIndex],
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: الذهاب إلى صفحة الإشعارات
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
          ),
          selectedItemColor: const Color(0xFF1E40AF),
          unselectedItemColor: const Color(0xFF64748B),
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
              ),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 1
                    ? Icons.shopping_bag
                    : Icons.shopping_bag_outlined,
              ),
              label: 'طلباتي',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 2
                    ? Icons.assignment
                    : Icons.assignment_outlined,
              ),
              label: 'فحوصاتي',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 3 ? Icons.person : Icons.person_outline,
              ),
              label: 'الملف',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 4
                    ? Icons.support_agent
                    : Icons.support_agent_outlined,
              ),
              label: 'الدعم',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // TODO: إنشاء طلب جديد
              },
              backgroundColor: const Color(0xFF1E40AF),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
