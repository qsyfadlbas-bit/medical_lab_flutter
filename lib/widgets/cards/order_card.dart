import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/models/order_model.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final bool showStatus;
  final bool showActions;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.showStatus = true,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    final timeFormat = DateFormat('hh:mm a', 'ar');
    final currencyFormat = NumberFormat('#,##0', 'ar');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const Gap(4),
                        Text(
                          dateFormat.format(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showStatus)
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.statusIcon,
                            size: 14,
                            color: order.statusColor,
                          ),
                          const Gap(4),
                          Text(
                            order.statusArabic,
                            style: TextStyle(
                              fontSize: 12,
                              color: order.statusColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const Gap(16),

              // Order Details
              Row(
                children: [
                  _buildDetailItem(
                    icon: Icons.attach_money,
                    label: 'المبلغ',
                    value: '${currencyFormat.format(order.finalAmount)} د.ع',
                  ),
                  const Gap(16),
                  _buildDetailItem(
                    icon: Icons.payment,
                    label: 'الدفع',
                    value: order.paymentMethod == 'CASH' ? 'نقداً' : 'إلكتروني',
                  ),
                  const Gap(16),
                  _buildDetailItem(
                    icon: Icons.inventory,
                    label: 'المنتجات',
                    value: order.items?.length.toString() ?? '0',
                  ),
                ],
              ),
              const Gap(12),

              // Delivery Info
              if (order.deliveryDate != null)
                Row(
                  children: [
                    Icon(
                      Icons.delivery_dining,
                      size: 16,
                      color: Colors.green,
                    ),
                    const Gap(8),
                    Text(
                      'التسليم: ${dateFormat.format(order.deliveryDate!)} ${order.deliveryTime ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),

              // Tracking
              if (order.trackingNumber != null) ...[
                const Gap(8),
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const Gap(8),
                    Text(
                      'رقم التتبع: ${order.trackingNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ],

              // Actions
              if (showActions) ...[
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Track order
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          'تتبع',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: View details
                        },
                        child: const Text(
                          'تفاصيل',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Colors.grey[600],
              ),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class OrderStatusCard extends StatelessWidget {
  final String status;
  final String title;
  final String description;
  final DateTime? date;
  final bool isActive;
  final bool isCompleted;

  const OrderStatusCard({
    super.key,
    required this.status,
    required this.title,
    required this.description,
    this.date,
    this.isActive = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Theme.of(context).primaryColor : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).primaryColor
                  : (isActive ? Theme.of(context).primaryColor : Colors.grey),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Theme.of(context).primaryColor
                            : Colors.grey[700],
                        fontFamily: 'Cairo',
                      ),
                    ),
                    if (date != null)
                      Text(
                        DateFormat('hh:mm a', 'ar').format(date!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Cairo',
                        ),
                      ),
                  ],
                ),
                const Gap(4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
