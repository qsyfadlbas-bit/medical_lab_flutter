import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/models/order_model.dart';
import 'package:medical_lab_flutter/services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Order> _orders = [];
  List<Order> _adminOrders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<Order> get orders => _orders;
  List<Order> get adminOrders => _adminOrders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  void setSelectedOrder(Order order) {
    _selectedOrder = order;
    notifyListeners();
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ✅ جلب الطلبات من السيرفر — مع حماية من HTML
  Future<void> fetchUserOrders({
    String? status,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      _orders.clear();
    } else {
      _currentPage++;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      print("🚀 Fetching Real Orders from Server...");

      final response = await _apiService.get('/orders');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ استخدام safeJsonDecode بدلاً من json.decode
        final data = ApiService.safeJsonDecode(response);

        if (data == null) {
          _errorMessage = ApiService.getErrorMessage(response);
          _hasMore = false;
          return;
        }

        if (data['data'] != null) {
          final List<dynamic> ordersJson = data['data'];
          List<Order> fetchedOrders =
              ordersJson.map((json) => Order.fromJson(json)).toList();

          // ترتيب الطلبات: الأحدث في الأعلى
          fetchedOrders.sort((a, b) => b.date.compareTo(a.date));

          // تطبيق فلتر الحالة
          if (status != null) {
            fetchedOrders =
                fetchedOrders.where((o) => o.status == status).toList();
          }

          if (!loadMore) {
            _orders = fetchedOrders;
          } else {
            _orders.addAll(fetchedOrders);
          }

          _hasMore = false;
          print("✅ Successfully fetched ${_orders.length} orders");
        }
      } else {
        _errorMessage = ApiService.getErrorMessage(response);
        print("❌ Server Error: ${response.statusCode}");
        _hasMore = false;
      }
    } catch (e) {
      print("❌ Network/Parsing Error fetching orders: $e");
      _errorMessage = 'حدث خطأ أثناء الاتصال بالسيرفر';
      if (!loadMore) {
        _orders = [];
      }
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyOrders() async {
    await fetchUserOrders();
  }

  // ✅ إرسال طلب جديد — مع حماية من HTML
  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/orders', orderData);

      // ✅ فحص الاستجابة
      if (!ApiService.isJsonResponse(response)) {
        _errorMessage = ApiService.getErrorMessage(response);
        return false;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchUserOrders();
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error creating order: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // الفلاتر
  // ==========================================

  List<Order> get activeOrders => _orders
      .where((order) => !['CANCELLED', 'DELIVERED'].contains(order.status))
      .toList();

  List<Order> get pendingOrders =>
      _orders.where((order) => order.status == 'PENDING').toList();

  List<Order> get completedOrders =>
      _orders.where((order) => order.status == 'DELIVERED').toList();

  List<Order> get cancelledOrders =>
      _orders.where((order) => order.status == 'CANCELLED').toList();
}
