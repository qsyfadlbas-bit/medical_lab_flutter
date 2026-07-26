import 'package:flutter/material.dart';

// ❌ تم إيقاف استيراد user_model و inspection_model لأننا لم نعد بحاجة لها هنا (لتخفيف الكود ومنع الأخطاء)

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final String patientName;
  final String phone;
  final String? location;
  final double totalAmount;
  final String status;
  final DateTime date;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.patientName,
    required this.phone,
    this.location,
    required this.totalAmount,
    required this.status,
    required this.date,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<OrderItem> parsedItems =
        itemsList.map((i) => OrderItem.fromJson(i)).toList();

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber:
          json['orderNumber']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      // دعم قراءة العنوان سواء كان اسمه location أو address في السيرفر
      location: json['location']?.toString() ?? json['address']?.toString(),
      totalAmount:
          double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      date: json['date'] != null || json['createdAt'] != null
          ? DateTime.parse((json['date'] ?? json['createdAt']).toString())
              .toLocal()
          : DateTime.now(),
      items: parsedItems,
    );
  }

  // ==========================================
  // ✅ تم الاحتفاظ بدوال التصميم والترجمة الخاصة بك
  // ==========================================

  String get statusArabic {
    switch (status) {
      case 'PENDING':
        return 'معلق';
      case 'CONFIRMED':
        return 'مؤكد';
      case 'PROCESSING':
        return 'قيد المعالجة';
      case 'READY_FOR_INSPECTION':
        return 'جاهز للفحص';
      case 'INSPECTION_IN_PROGRESS':
        return 'فحص قيد التنفيذ';
      case 'READY_FOR_DELIVERY':
        return 'جاهز للتسليم';
      case 'SHIPPED':
        return 'تم الشحن';
      case 'DELIVERED':
        return 'تم التسليم';
      case 'CANCELLED':
        return 'ملغى';
      case 'REFUNDED':
        return 'تم الاسترجاع';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case 'CONFIRMED':
        return const Color(0xFF3B82F6);
      case 'PROCESSING':
        return const Color(0xFF8B5CF6);
      case 'READY_FOR_INSPECTION':
        return const Color(0xFF10B981);
      case 'INSPECTION_IN_PROGRESS':
        return const Color(0xFFEC4899);
      case 'READY_FOR_DELIVERY':
        return const Color(0xFF14B8A6);
      case 'SHIPPED':
        return const Color(0xFFF97316);
      case 'DELIVERED':
        return const Color(0xFF22C55E);
      case 'CANCELLED':
        return const Color(0xFF6B7280);
      case 'REFUNDED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'PENDING':
        return Icons.pending;
      case 'CONFIRMED':
        return Icons.check_circle_outline;
      case 'PROCESSING':
        return Icons.build;
      case 'READY_FOR_INSPECTION':
        return Icons.assignment_turned_in;
      case 'INSPECTION_IN_PROGRESS':
        return Icons.search;
      case 'READY_FOR_DELIVERY':
        return Icons.local_shipping;
      case 'SHIPPED':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      case 'REFUNDED':
        return Icons.money_off;
      default:
        return Icons.help;
    }
  }
}

class OrderItem {
  final String testId;
  final String testName;
  final double price;
  final int quantity;

  OrderItem({
    required this.testId,
    required this.testName,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromJson(dynamic json) {
    // التحقق تحسباً لأي بيانات قديمة مسجلة كنص عادي
    if (json is Map<String, dynamic>) {
      return OrderItem(
        testId: json['testId']?.toString() ?? json['id']?.toString() ?? '',
        testName: json['testName']?.toString() ??
            json['nameAr']?.toString() ??
            'تحليل',
        price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
        quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      );
    } else {
      // إذا كان الباك إند القديم يرسل اسم التحليل كنص فقط
      return OrderItem(
        testId: '',
        testName: json.toString(),
        price: 0.0,
        quantity: 1,
      );
    }
  }
}
