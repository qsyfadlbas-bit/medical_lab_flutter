import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DeveloperDashboard extends StatelessWidget {
  const DeveloperDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'لوحة تحكم المطورين',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات النظام
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'معلومات النظام',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Gap(12),
                  _buildSystemInfoItem('إصدار التطبيق', '1.0.0'),
                  _buildSystemInfoItem('إصدار Flutter', '3.10.0+'),
                  _buildSystemInfoItem('نظام التشغيل', 'Android/iOS/Web'),
                  _buildSystemInfoItem('آخر تحديث', '2024'),
                ],
              ),
            ),
            const Gap(20),

            // أدوات المطورين
            const Text(
              'أدوات المطورين',
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
                _buildDevTool(
                  icon: Icons.bug_report,
                  label: 'سجلات النظام',
                  color: Colors.red,
                  onTap: () {},
                ),
                _buildDevTool(
                  icon: Icons.api,
                  label: 'اختبار API',
                  color: Colors.blue,
                  onTap: () {},
                ),
                _buildDevTool(
                  icon: Icons.storage,
                  label: 'قاعدة البيانات',
                  color: Colors.green,
                  onTap: () {},
                ),
                _buildDevTool(
                  icon: Icons.security,
                  label: 'الأمان',
                  color: Colors.orange,
                  onTap: () {},
                ),
                _buildDevTool(
                  icon: Icons.analytics,
                  label: 'تحليلات',
                  color: Colors.purple,
                  onTap: () {},
                ),
                _buildDevTool(
                  icon: Icons.settings,
                  label: 'الإعدادات',
                  color: Colors.grey,
                  onTap: () {},
                ),
              ],
            ),
            const Gap(20),

            // إحصائيات النظام
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إحصائيات النظام',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Gap(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('5.2K', 'طلب'),
                      _buildStatItem('2.1K', 'مستخدم'),
                      _buildStatItem('98%', 'استقرار'),
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

  Widget _buildSystemInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevTool({
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
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
