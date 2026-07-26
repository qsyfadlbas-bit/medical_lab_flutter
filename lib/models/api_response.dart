import 'dart:convert';
import 'package:flutter/material.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<dynamic>? errors;
  final Map<String, dynamic>? meta;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
    required this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'],
      meta: json['meta'],
      statusCode: json['statusCode'] ?? 200,
    );
  }

  Map<String, dynamic> toJson(dynamic Function(T)? toJsonT) {
    return {
      'success': success,
      'message': message,
      'data': toJsonT != null && data != null ? toJsonT(data!) : data,
      'errors': errors,
      'meta': meta,
      'statusCode': statusCode,
    };
  }

  String toJsonString(dynamic Function(T)? toJsonT) {
    return json.encode(toJson(toJsonT));
  }

  // Factory methods for common responses
  factory ApiResponse.success({
    required String message,
    T? data,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      meta: meta,
      statusCode: 200,
    );
  }

  factory ApiResponse.error({
    required String message,
    List<dynamic>? errors,
    int statusCode = 400,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.fromError(dynamic error) {
    return ApiResponse<T>(
      success: false,
      message: error.toString(),
      statusCode: 500,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta meta;

  PaginatedResponse({
    required this.data,
    required this.meta,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      data: (json['data'] as List).map(fromJsonT).toList(),
      meta: PaginationMeta.fromJson(json['meta']),
    );
  }
}

class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}

class Notification {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;
  final String userId;

  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.read,
    required this.createdAt,
    required this.userId,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      data: json['data'],
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'],
    );
  }

  IconData get typeIcon {
    switch (type) {
      case 'ORDER':
        return Icons.shopping_bag;
      case 'INSPECTION':
        return Icons.assignment;
      case 'PAYMENT':
        return Icons.payment;
      case 'SYSTEM':
        return Icons.notifications;
      case 'ALERT':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color get typeColor {
    switch (type) {
      case 'ORDER':
        return Colors.blue;
      case 'INSPECTION':
        return Colors.purple;
      case 'PAYMENT':
        return Colors.green;
      case 'SYSTEM':
        return Colors.orange;
      case 'ALERT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
