import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// دالة لمعالجة الإشعارات والتطبيق مغلق (يجب أن تكون خارج الكلاس)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("تم استلام إشعار في الخلفية: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // تهيئة الإشعارات
  static Future<void> initialize() async {
    // 1. طلب الإذن (للايفون واندرويد 13+)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. إعدادات الإشعار المحلي (لإظهاره والتطبيق مفتوح)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // تأكد من وجود أيقونة التطبيق

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);

    // 3. ضبط معالج الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. الاستماع للإشعارات والتطبيق مفتوح (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 إشعار جديد وصل: ${message.notification?.title}");
      _showNotification(message);
    });

    print("✅ تم تفعيل خدمة الإشعارات");
  }

  // اشتراك الأدمن في قناة الإشعارات
  static Future<void> subscribeToAdminTopic() async {
    await _firebaseMessaging.subscribeToTopic('admin_orders');
    print("🔔 تم الاشتراك في قناة إشعارات الأدمن");
  }

  // عرض الإشعار محلياً
  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'admin_channel', // id
      'طلبات جديدة', // name
      channelDescription: 'إشعارات عند وصول طلب جديد',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'طلب جديد',
      message.notification?.body ?? 'يرجى مراجعة لوحة التحكم',
      platformChannelSpecifics,
    );
  }
}
