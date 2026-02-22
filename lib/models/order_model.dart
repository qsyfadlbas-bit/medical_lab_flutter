import 'dart:convert';
import 'package:flutter/material.dart'; // هذا السطر يحل مشكلة Color و Icons و IconData
import 'user_model.dart'; // هذا السطر يحل مشكلة User و Address
import 'inspection_model.dart'; // هذا السطر يحل مشكلة Inspection

class Order {
  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final double? discountAmount;
  final double? taxAmount;
  final double finalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentId;
  final DateTime? paymentDate;
  final String? notes;
  final String userId;
  final String? addressId;
  final DateTime? deliveryDate;
  final String? deliveryTime;
  final String? trackingNumber;
  final String? shippingCompany;
  final double? shippingCost;
  final DateTime createdAt;
  final DateTime updatedAt;

  // العلاقات
  final User? user;
  final List<OrderItem>? items;
  final List<Inspection>? inspections;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.discountAmount,
    this.taxAmount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentId,
    this.paymentDate,
    this.notes,
    required this.userId,
    this.addressId,
    this.deliveryDate,
    this.deliveryTime,
    this.trackingNumber,
    this.shippingCompany,
    this.shippingCost,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.items,
    this.inspections,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['orderNumber'],
      status: json['status'],
      totalAmount:
          json['totalAmount'] != null ? json['totalAmount'].toDouble() : 0.0,
      discountAmount: json['discountAmount'] != null
          ? json['discountAmount'].toDouble()
          : null,
      taxAmount:
          json['taxAmount'] != null ? json['taxAmount'].toDouble() : null,
      finalAmount:
          json['finalAmount'] != null ? json['finalAmount'].toDouble() : 0.0,
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      paymentId: json['paymentId'],
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : null,
      notes: json['notes'],
      userId: json['userId'],
      addressId: json['addressId'],
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
      deliveryTime: json['deliveryTime'],
      trackingNumber: json['trackingNumber'],
      shippingCompany: json['shippingCompany'],
      shippingCost:
          json['shippingCost'] != null ? json['shippingCost'].toDouble() : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : null,
      inspections: json['inspections'] != null
          ? (json['inspections'] as List)
              .map((item) => Inspection.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'status': status,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'finalAmount': finalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'paymentDate': paymentDate?.toIso8601String(),
      'notes': notes,
      'userId': userId,
      'addressId': addressId,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'deliveryTime': deliveryTime,
      'trackingNumber': trackingNumber,
      'shippingCompany': shippingCompany,
      'shippingCost': shippingCost,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

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
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? productDescription;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final String? specifications;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productDescription,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.specifications,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['orderId'],
      productId: json['productId'],
      productName: json['productName'],
      productDescription: json['productDescription'],
      unitPrice: json['unitPrice'] != null ? json['unitPrice'].toDouble() : 0.0,
      quantity: json['quantity'],
      totalPrice:
          json['totalPrice'] != null ? json['totalPrice'].toDouble() : 0.0,
      specifications: json['specifications'],
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'productDescription': productDescription,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'specifications': specifications,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
