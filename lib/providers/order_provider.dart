import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/models/order_model.dart';
import 'package:medical_lab_flutter/services/api_service.dart';

class OrderProvider with ChangeNotifier {
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

  // Set selected order
  void setSelectedOrder(Order order) {
    _selectedOrder = order;
    notifyListeners();
  }

  // Clear selected order
  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  // Load user orders
  Future<void> fetchUserOrders({
    String? status,
    bool loadMore = false,
  }) async {
    try {
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

      // TODO: Implement API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      if (!loadMore) {
        _orders = [
          Order(
            id: '1',
            orderNumber: 'ORD001',
            status: 'PENDING',
            totalAmount: 50000,
            finalAmount: 50000,
            paymentMethod: 'CASH',
            paymentStatus: 'PENDING',
            userId: '1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      }

      _hasMore = false;
    } catch (e) {
      _errorMessage = 'فشل تحميل الطلبات';
      if (!loadMore) {
        _orders = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

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
