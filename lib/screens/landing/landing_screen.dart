import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/screens/auth/login_screen.dart';
import 'package:medical_lab_flutter/screens/auth/register_screen.dart';
import 'package:gap/gap.dart';

// زر بتدرج لوني (كما هو في كودك الأصلي)
class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Gradient? gradient;
  final Widget child;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.onPressed,
    this.gradient,
    required this.child,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        child: child,
      ),
    );
  }
}

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            // ✅ تم تغيير الألوان إلى تدرجات الأخضر الاحترافي
            colors: [
              Color(0xFF064E3B), // أخضر غامق جداً (Emerald 900)
              Color(0xFF059669), // أخضر زمردي (Emerald 600)
              Color(0xFF34D399), // أخضر فاتح حيوي (Emerald 400)
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Gap(40),
                  // الشعار
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(32),
                  // العنوان الرئيسي
                  const Text(
                    'مختبر القمة الطبي',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(12),

                  // الوصف (تم تعديل الكلمة هنا)
                  const Text(
                    // ✅ تم تغيير "المخبرية" إلى "مختبر" وضبط الجملة
                    'نظام فحوصات المختبر الذكي والأكثر تطوراً في المنطقة',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontFamily: 'Cairo',
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(48),

                  // بطاقة الموثوقية
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 20,
                        ),
                        const Gap(8),
                        Text(
                          ' مختبر طبي موثوق',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(40),

                  // الأزرار الرئيسية
                  Column(
                    children: [
                      // زر تطبيق المستخدم
                      GradientButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(
                                userType: 'USER',
                              ),
                            ),
                          );
                        },
                        gradient: const LinearGradient(
                          colors: [
                            Colors.white,
                            Color(0xFFECFDF5)
                          ], // خلفية فاتحة جداً للأخضر
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              color:
                                  Color(0xFF047857), // لون الأيقونة أخضر غامق
                            ),
                            Gap(12),
                            Text(
                              'تطبيق المستخدم',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF047857), // لون النص أخضر غامق
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(187),
                      // // زر لوحة الإدارة
                      // GradientButton(
                      //   onPressed: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => const LoginScreen(
                      //           userType: 'ADMIN',
                      //         ),
                      //       ),
                      //     );
                      //   },
                      //   gradient: const LinearGradient(
                      //     colors: [Colors.white, Color(0xFFF3E8FF)],
                      //   ),
                      //   child: const Row(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     children: [
                      //       Icon(
                      //         Icons.admin_panel_settings_outlined,
                      //         color: Color(0xFF7C3AED),
                      //       ),
                      //       Gap(12),
                      //       Text(
                      //         'لوحة الإدارة',
                      //         style: TextStyle(
                      //           fontSize: 18,
                      //           fontWeight: FontWeight.bold,
                      //           color: Color(0xFF7C3AED),
                      //           fontFamily: 'Cairo',
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // const Gap(16),

                      // // زر بوابة المطورين
                      // GradientButton(
                      //   onPressed: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => const LoginScreen(
                      //           userType: 'DEVELOPER',
                      //         ),
                      //       ),
                      //     );
                      //   },
                      //   gradient: const LinearGradient(
                      //     colors: [Colors.white, Color(0xFFDCFCE7)],
                      //   ),
                      //   child: const Row(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     children: [
                      //       Icon(
                      //         Icons.code_outlined,
                      //         color: Color(0xFF16A34A),
                      //       ),
                      //       Gap(12),
                      //       Text(
                      //         'بوابة المطورين',
                      //         style: TextStyle(
                      //           fontSize: 18,
                      //           fontWeight: FontWeight.bold,
                      //           color: Color(0xFF16A34A),
                      //           fontFamily: 'Cairo',
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),

                      // الروابط الإضافية (إنشاء حساب)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ليس لديك حساب؟',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontFamily: 'Cairo',
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'سجل الآن',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
