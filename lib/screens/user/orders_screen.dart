import 'package:flutter/material.dart'
    hide ErrorWidget; // ✅ إخفاء ErrorWidget الأصلي لمنع التضارب
import 'package:medical_lab_flutter/widgets/cards/order_card.dart';
import 'package:medical_lab_flutter/widgets/common/loading_widget.dart';
import 'package:medical_lab_flutter/widgets/common/error_widget.dart'; // هذا هو الودجت الخاص بك
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:medical_lab_flutter/providers/order_provider.dart';
import 'package:medical_lab_flutter/models/order_model.dart'; // ✅ ضروري لتعريف Order
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:intl/intl.dart'; // ✅ ضروري لتعريف NumberFormat
import 'package:medical_lab_flutter/utils/helpers.dart'; // ✅ ضروري لتعريف AppHelpers

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RefreshController _refreshController = RefreshController();
  final Map<String, String> _statusTabs = {
    'all': 'الكل',
    'pending': 'معلقة',
    'active': 'نشطة',
    'completed': 'مكتملة',
    'cancelled': 'ملغاة',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _statusTabs.length,
      vsync: this,
    );
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.fetchUserOrders();
  }

  void _onRefresh() async {
    await _loadOrders();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.fetchUserOrders(loadMore: true);
    _refreshController.loadComplete();
  }

  List<Order> _getOrdersForTab(int index) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final tabKey = _statusTabs.keys.elementAt(index);

    switch (tabKey) {
      case 'pending':
        return orderProvider.pendingOrders;
      case 'active':
        return orderProvider.activeOrders;
      case 'completed':
        return orderProvider.completedOrders;
      case 'cancelled':
        return orderProvider.cancelledOrders;
      default:
        return orderProvider.orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'طلباتي',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: _statusTabs.values
                  .map((title) => Tab(
                        text: title,
                        iconMargin: EdgeInsets.zero,
                      ))
                  .toList(),
              labelStyle: const TextStyle(fontFamily: 'Cairo'),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children:
                  _statusTabs.keys.map((_) => _buildOrdersList()).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to new order screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOrdersList() {
    final orderProvider = Provider.of<OrderProvider>(context);
    final orders = _getOrdersForTab(_tabController.index);

    if (orderProvider.isLoading && orders.isEmpty) {
      return const LoadingWidget(message: 'جاري تحميل الطلبات...');
    }

    if (orderProvider.errorMessage != null && orders.isEmpty) {
      return ErrorWidget(
        message: 'حدث خطأ',
        details: orderProvider.errorMessage!,
        onRetry: _loadOrders,
        fullScreen: false,
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const Gap(16),
            const Text(
              'لا توجد طلبات',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontFamily: 'Cairo',
              ),
            ),
            const Gap(8),
            const Text(
              'يمكنك إنشاء طلب جديد بالنقر على زر (+)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      enablePullUp: orderProvider.hasMore,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            onTap: () {
              _showOrderDetails(order);
            },
            showActions: true,
          );
        },
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => OrderDetailsSheet(order: order),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تصفية الطلبات',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حالة الطلب:',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            // TODO: Add filter options
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Apply filters
              Navigator.pop(context);
            },
            child: const Text(
              'تطبيق',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDetailsSheet extends StatelessWidget {
  final Order order;

  const OrderDetailsSheet({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: order.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: order.statusColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  order.statusArabic,
                  style: TextStyle(
                    color: order.statusColor,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),

          // Order Details
          const Text(
            'تفاصيل الطلب',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const Gap(12),

          _buildDetailRow(
              'تاريخ الطلب', AppHelpers.formatDate(order.createdAt)),
          _buildDetailRow('طريقة الدفع',
              order.paymentMethod == 'CASH' ? 'نقداً' : 'إلكتروني'),
          _buildDetailRow('حالة الدفع', order.paymentStatus),
          if (order.deliveryDate != null)
            _buildDetailRow(
                'تاريخ التسليم', AppHelpers.formatDate(order.deliveryDate!)),
          if (order.trackingNumber != null)
            _buildDetailRow('رقم التتبع', order.trackingNumber!),

          const Gap(16),

          // Order Items
          if (order.items != null && order.items!.isNotEmpty) ...[
            const Text(
              'المنتجات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const Gap(12),
            ...order.items!.map((item) => _buildOrderItem(item)).toList(),
          ],

          const Gap(16),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildTotalRow(context, 'المبلغ الإجمالي', order.totalAmount),
                if (order.discountAmount != null && order.discountAmount! > 0)
                  _buildTotalRow(context, 'الخصم', -order.discountAmount!),
                if (order.taxAmount != null && order.taxAmount! > 0)
                  _buildTotalRow(context, 'الضريبة', order.taxAmount!),
                if (order.shippingCost != null && order.shippingCost! > 0)
                  _buildTotalRow(context, 'رسوم الشحن', order.shippingCost!),
                const Divider(),
                _buildTotalRow(context, 'المبلغ النهائي', order.finalAmount,
                    isTotal: true),
              ],
            ),
          ),
          const Gap(24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Track order
                  },
                  child: const Text(
                    'تتبع الطلب',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Contact support
                  },
                  child: const Text(
                    'طلب مساعدة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
                if (item.productDescription != null)
                  Text(
                    item.productDescription!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Cairo',
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormat('#,##0', 'ar').format(item.unitPrice)} د.ع',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'الكمية: ${item.quantity}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, double amount,
      {bool isTotal = false}) {
    final formattedAmount = NumberFormat('#,##0', 'ar').format(amount.abs());

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            '${amount < 0 ? '-' : ''}$formattedAmount د.ع',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Theme.of(context).primaryColor : Colors.black,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
