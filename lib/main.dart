import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// استيراد الشاشات والبروفايدرز
import 'package:medical_lab_flutter/app/theme.dart';
import 'package:medical_lab_flutter/providers/auth_provider.dart';
import 'package:medical_lab_flutter/providers/user_provider.dart';
import 'package:medical_lab_flutter/providers/order_provider.dart';
import 'package:medical_lab_flutter/providers/inspection_provider.dart';

// استيراد الشاشات
import 'package:medical_lab_flutter/screens/auth/login_screen.dart';
import 'package:medical_lab_flutter/screens/home/home_screen.dart';
import 'package:medical_lab_flutter/screens/admin/admin_dashboard.dart';

// =======================================================
// 🟢 إعدادات العمل في الخلفية
// =======================================================
const String fetchBackground = "fetchBackground";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == fetchBackground) {
      await _checkNewOrders();
    }
    return Future.value(true);
  });
}

Future<void> _checkNewOrders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final role = prefs.getString('userRole');

  if (token != null && role == 'ADMIN') {
    try {
      final response = await http.get(
        Uri.parse('https://medical-lab-backend.vercel.app/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List orders = data['data'] ?? [];
        int lastCount = prefs.getInt('last_orders_count') ?? 0;

        if (orders.length > lastCount) {
          await _showLocalNotification(
              "طلب جديد 🔔", "هناك طلبات جديدة بانتظارك!");
          await prefs.setInt('last_orders_count', orders.length);
        }
      }
    } catch (e) {
      print("❌ خطأ في الخلفية: $e");
    }
  }
}

Future<void> _showLocalNotification(String title, String body) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'admin_bg_channel',
    'تنبيهات الأدمن',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecond,
    title,
    body,
    notificationDetails,
  );
}

// =======================================================
// 🟢 دالة Main
// =======================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ إعدادات الفايربيس الذكية (للويب، الآيفون، والأندرويد)
  if (kIsWeb) {
    // إعدادات الويب
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD3oz1eKrRS077zCQTzee5QJ0Nlw02Orzo",
        authDomain: "medical-lab-52086.firebaseapp.com",
        projectId: "medical-lab-52086",
        storageBucket: "medical-lab-52086.firebasestorage.app",
        messagingSenderId: "731388772856",
        appId: "1:731388772856:web:f3eb5b0ca87eec9095560d",
        measurementId: "G-MS196W9Z1H",
      ),
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    // ✅ إعدادات الآيفون والآيباد (تمت إضافة الكود مالتك هنا)
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD3oz1eKrRS077zCQTzee5QJ0Nlw02Orzo",
        authDomain: "medical-lab-52086.firebaseapp.com",
        projectId: "medical-lab-52086",
        storageBucket: "medical-lab-52086.firebasestorage.app",
        messagingSenderId: "731388772856",
        appId: "1:731388772856:ios:d433f64684c9e30d95560d", // الكود اللي جبته
        iosBundleId: "com.example.medicalLabFlutter",
      ),
    );
  } else {
    // إعدادات الأندرويد (يعتمد على ملف google-services.json)
    await Firebase.initializeApp();
  }

  // ✅ إعدادات Workmanager (للإشعارات) تشتغل بس على الموبايل
  if (!kIsWeb) {
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      await Workmanager().registerPeriodicTask(
        "1",
        fetchBackground,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      print("Workmanager init failed: $e");
    }
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ScreenUtil.ensureScreenSize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => InspectionProvider()),
        ChangeNotifierProvider(create: (_) => LabAppModel()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return Consumer<LabAppModel>(
            builder: (context, appModel, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'مختبر القمة',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: appModel.isDark ? ThemeMode.dark : ThemeMode.light,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('ar', 'SA'),
                  Locale('en', 'US'),
                ],
                locale: const Locale('ar', 'SA'),
                home: const SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------
// ✅ شاشة البداية الاحترافية (Splash Screen)
// --------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // إعداد الأنيميشن
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _checkLoginStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = await authProvider.tryAutoLogin();

    if (!mounted) return;

    if (role == 'ADMIN') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else if (role == 'USER') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResponsiveHomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // خلفية متدرجة (Gradient) بدلاً من لون واحد
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF047857), // لون القمة الغامق
              Color(0xFF0D9488), // لون أفتح قليلاً للعمق
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الأنيميشن للشعار
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 200,
                    height: 200,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40), // زوايا ناعمة
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 30, // ظل ناعم وكبير
                          offset: const Offset(0, 15), // اتجاه الظل للأسفل
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // اسم المختبر
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      "مختبر القمة",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "للتحليلات المرضية المتقدمة",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: 'Cairo',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // مؤشر التحميل
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
