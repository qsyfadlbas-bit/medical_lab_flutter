import 'dart:convert';
import 'package:flutter/material.dart';
import 'user_model.dart'; // أضف هذا
import 'order_model.dart';

class Inspection {
  final String id;
  final String type;
  final String status;
  final String? description;
  final DateTime? scheduledDate;
  final DateTime? actualDate;
  final String? location;
  final String? notes;
  final String? result;
  final String? resultDetails;
  final bool? passed;
  final double? score;
  final List<String> images;
  final List<String> documents;
  final String? reportUrl;
  final DateTime? reportGeneratedAt;
  final String? signedBy;
  final DateTime? signatureDate;
  final String? orderId;
  final String userId;
  final String? inspectorId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // العلاقات
  final User? user;
  final User? inspector;
  final Order? order;

  Inspection({
    required this.id,
    required this.type,
    required this.status,
    this.description,
    this.scheduledDate,
    this.actualDate,
    this.location,
    this.notes,
    this.result,
    this.resultDetails,
    this.passed,
    this.score,
    required this.images,
    required this.documents,
    this.reportUrl,
    this.reportGeneratedAt,
    this.signedBy,
    this.signatureDate,
    this.orderId,
    required this.userId,
    this.inspectorId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.inspector,
    this.order,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'],
      type: json['type'],
      status: json['status'],
      description: json['description'],
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : null,
      actualDate: json['actualDate'] != null
          ? DateTime.parse(json['actualDate'])
          : null,
      location: json['location'],
      notes: json['notes'],
      result: json['result'],
      resultDetails: json['resultDetails'],
      passed: json['passed'],
      score: json['score'] != null ? json['score'].toDouble() : null,
      images: List<String>.from(json['images'] ?? []),
      documents: List<String>.from(json['documents'] ?? []),
      reportUrl: json['reportUrl'],
      reportGeneratedAt: json['reportGeneratedAt'] != null
          ? DateTime.parse(json['reportGeneratedAt'])
          : null,
      signedBy: json['signedBy'],
      signatureDate: json['signatureDate'] != null
          ? DateTime.parse(json['signatureDate'])
          : null,
      orderId: json['orderId'],
      userId: json['userId'],
      inspectorId: json['inspectorId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      inspector:
          json['inspector'] != null ? User.fromJson(json['inspector']) : null,
      order: json['order'] != null ? Order.fromJson(json['order']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'description': description,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'actualDate': actualDate?.toIso8601String(),
      'location': location,
      'notes': notes,
      'result': result,
      'resultDetails': resultDetails,
      'passed': passed,
      'score': score,
      'images': images,
      'documents': documents,
      'reportUrl': reportUrl,
      'reportGeneratedAt': reportGeneratedAt?.toIso8601String(),
      'signedBy': signedBy,
      'signatureDate': signatureDate?.toIso8601String(),
      'orderId': orderId,
      'userId': userId,
      'inspectorId': inspectorId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get typeArabic {
    switch (type) {
      case 'PRE_PURCHASE':
        return 'فحص ما قبل الشراء';
      case 'QUALITY':
        return 'فحص الجودة';
      case 'SAFETY':
        return 'فحص السلامة';
      case 'COMPLIANCE':
        return 'فحص المطابقة';
      case 'TECHNICAL':
        return 'فحص تقني';
      case 'PERIODIC':
        return 'فحص دوري';
      case 'EMERGENCY':
        return 'فحص طارئ';
      default:
        return type;
    }
  }

  String get statusArabic {
    switch (status) {
      case 'PENDING':
        return 'معلق';
      case 'SCHEDULED':
        return 'مجدول';
      case 'IN_PROGRESS':
        return 'قيد التنفيذ';
      case 'COMPLETED':
        return 'مكتمل';
      case 'CANCELLED':
        return 'ملغى';
      case 'FAILED':
        return 'فاشل';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case 'SCHEDULED':
        return const Color(0xFF3B82F6);
      case 'IN_PROGRESS':
        return const Color(0xFF8B5CF6);
      case 'COMPLETED':
        return const Color(0xFF10B981);
      case 'CANCELLED':
        return const Color(0xFF6B7280);
      case 'FAILED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'PENDING':
        return Icons.pending;
      case 'SCHEDULED':
        return Icons.calendar_today;
      case 'IN_PROGRESS':
        return Icons.build;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      case 'FAILED':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}

class InspectionRequest {
  final String id;
  final String type;
  final String priority;
  final String reason;
  final DateTime? desiredDate;
  final String location;
  final String contactPerson;
  final String contactPhone;
  final String? specifications;
  final String? requirements;
  final List<String> files;
  final String status;
  final String? assignedTo;
  final double? estimatedCost;
  final double? actualCost;
  final String userId;
  final String? inspectionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  InspectionRequest({
    required this.id,
    required this.type,
    required this.priority,
    required this.reason,
    this.desiredDate,
    required this.location,
    required this.contactPerson,
    required this.contactPhone,
    this.specifications,
    this.requirements,
    required this.files,
    required this.status,
    this.assignedTo,
    this.estimatedCost,
    this.actualCost,
    required this.userId,
    this.inspectionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InspectionRequest.fromJson(Map<String, dynamic> json) {
    return InspectionRequest(
      id: json['id'],
      type: json['type'],
      priority: json['priority'],
      reason: json['reason'],
      desiredDate: json['desiredDate'] != null
          ? DateTime.parse(json['desiredDate'])
          : null,
      location: json['location'],
      contactPerson: json['contactPerson'],
      contactPhone: json['contactPhone'],
      specifications: json['specifications'],
      requirements: json['requirements'],
      files: List<String>.from(json['files'] ?? []),
      status: json['status'],
      assignedTo: json['assignedTo'],
      estimatedCost: json['estimatedCost'] != null
          ? json['estimatedCost'].toDouble()
          : null,
      actualCost:
          json['actualCost'] != null ? json['actualCost'].toDouble() : null,
      userId: json['userId'],
      inspectionId: json['inspectionId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
