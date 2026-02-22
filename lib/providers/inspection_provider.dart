import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/models/inspection_model.dart';
import 'package:medical_lab_flutter/services/api_service.dart';
import 'package:http/http.dart'
    as http; // لإستخدام MultipartRequest إذا لزم الأمر

class InspectionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Inspection> _inspections = [];
  List<Inspection> _upcomingInspections = [];
  List<Inspection> _completedInspections = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Inspection> get inspections => _inspections;
  List<Inspection> get upcomingInspections => _upcomingInspections;
  List<Inspection> get completedInspections => _completedInspections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // جلب الفحوصات
  Future<void> fetchUserInspections() async {
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ التعديل هنا: استخدام دالة get العامة
      final response = await _apiService.get('/inspections/my-inspections');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> inspectionData = data['data'];
          _inspections =
              inspectionData.map((json) => Inspection.fromJson(json)).toList();

          // تصنيف الفحوصات
          _upcomingInspections = _inspections
              .where((i) =>
                  ['PENDING', 'SCHEDULED', 'CONFIRMED'].contains(i.status))
              .toList();

          _completedInspections = _inspections
              .where((i) => ['COMPLETED', 'REPORT_READY'].contains(i.status))
              .toList();
        }
      } else {
        _errorMessage = 'فشل في تحميل الفحوصات';
      }
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حجز فحص جديد
  Future<bool> createInspection(Map<String, dynamic> inspectionData) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ التعديل هنا: استخدام دالة post العامة
      final response = await _apiService.post('/inspections', inspectionData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchUserInspections(); // تحديث القائمة
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'خطأ: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
