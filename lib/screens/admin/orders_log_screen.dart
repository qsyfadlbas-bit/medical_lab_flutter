import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/services/api_service.dart';
import 'package:gap/gap.dart';
import 'package:flutter/services.dart';

class OrdersLogScreen extends StatefulWidget {
  const OrdersLogScreen({super.key});

  @override
  State<OrdersLogScreen> createState() => _OrdersLogScreenState();
}

class _OrdersLogScreenState extends State<OrdersLogScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // 1. جلب الطلبات
  Future<void> _fetchOrders() async {
    try {
      final response = await _apiService.get('/orders');
      if (response.statusCode == 200) {
        // ✅ استخدام safeJsonDecode
        final data = ApiService.safeJsonDecode(response);
        if (data != null && data['data'] != null) {
          setState(() {
            _orders = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching orders: $e");
      setState(() => _isLoading = false);
    }
  }

  // ✅ 2. دالة قبول الطلب
  Future<void> _acceptOrder(String id) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('جاري الاتصال بالسيرفر...',
              style: TextStyle(fontFamily: 'Cairo')),
          duration: Duration(milliseconds: 500)),
    );

    try {
      var response =
          await _apiService.patch('/orders/$id', {'status': 'PROCESSING'});

      if (response.statusCode == 404 || response.statusCode == 405) {
        print("PATCH failed, trying alternative endpoint...");
        response = await _apiService
            .patch('/orders/$id/status', {'status': 'PROCESSING'});
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          final index = _orders.indexWhere((order) => order['id'] == id);
          if (index != -1) {
            _orders[index]['status'] = 'PROCESSING';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم قبول الطلب وحفظ التغيير في النظام',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'فشل الحفظ: السيرفر يرفض التعديل (${response.statusCode})',
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Network Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('خطأ في الاتصال', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red),
      );
    }
  }

  // 3. دالة الحذف
  Future<void> _deleteOrder(String id) async {
    try {
      final response = await _apiService.delete('/orders/$id');
      if (response.statusCode == 200) {
        setState(() {
          _orders.removeWhere((order) => order['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ تم حذف الطلب بنجاح',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('❌ حدث خطأ أثناء الحذف',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red),
      );
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا الطلب؟',
            style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteOrder(id);
            },
            child: const Text('حذف',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ تنسيق الوقت (تم تقويتها لتجنب اختفاء التاريخ)
  String _formatDateTime(dynamic dateData) {
    if (dateData == null) return "تاريخ غير معروف";
    String dateStr = dateData.toString();
    if (dateStr.isEmpty) return "تاريخ غير معروف";

    try {
      final DateTime dt = DateTime.parse(dateStr).toLocal();
      // تنسيق جميل: YYYY-MM-DD  HH:MM
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}   ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      // في حال فشل التحويل نرجع أول 10 حروف من النص (التاريخ فقط)
      return dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الطلبات (إدارة)',
            style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Text("لا توجد طلبات حتى الآن",
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order =
                        _orders[_orders.length - 1 - index]; // عكس الترتيب

                    String status = order['status'] ?? 'PENDING';

                    bool isAccepted =
                        (status == 'PROCESSING' || status == 'COMPLETED');

                    Color statusColor =
                        isAccepted ? Colors.green : Colors.orange;

                    if (status == 'CANCELLED') statusColor = Colors.red;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Icon(
                              isAccepted
                                  ? Icons.check_circle
                                  : Icons.access_time_filled,
                              color: statusColor),
                        ),
                        title: Text(
                          order['patientName'] ?? 'مستخدم',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order['phone'] ?? 'لا يوجد رقم',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    color: Colors.grey[700])),
                            Builder(
                              builder: (context) {
                                String addressText =
                                    order['address']?.toString() ?? '';
                                String locationText =
                                    order['location']?.toString() ?? '';

                                String finalLocation = addressText;
                                if (finalLocation.isEmpty)
                                  finalLocation = locationText;

                                if (addressText.isNotEmpty &&
                                    locationText.isNotEmpty &&
                                    addressText != locationText) {
                                  finalLocation =
                                      '$addressText - $locationText';
                                }

                                if (finalLocation.isNotEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 16, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            finalLocation,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black87,
                                                fontFamily: 'Cairo'),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(
                                                text: finalLocation));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'تم نسخ الموقع',
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'Cairo'))));
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.all(4.0),
                                            child: Icon(Icons.copy,
                                                size: 16, color: Colors.grey),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${order['totalAmount']} د.ع',
                                    style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.purple,
                                        fontWeight: FontWeight.bold)),
                                // ✅ تم حل مشكلة اختفاء التاريخ هنا وإضافة أيقونة
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                        _formatDateTime(order['createdAt'] ??
                                            order['date']),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold),
                                        textDirection: TextDirection.ltr),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        children: [
                          Container(
                            color: Colors.grey[50],
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                ...List<Widget>.from(
                                    (order['items'] as List).map((item) {
                                  String testName = 'تحليل (طلب قديم)';
                                  String testPrice = '0';

                                  try {
                                    if (item is Map) {
                                      testName = item['testName']?.toString() ??
                                          item['nameAr']?.toString() ??
                                          item['nameEn']?.toString() ??
                                          'تحليل';
                                      testPrice =
                                          item['price']?.toString() ?? '0';
                                    } else if (item is List) {
                                      testName = item.isNotEmpty
                                          ? item[0].toString()
                                          : 'تحليل';
                                    } else {
                                      testName = item.toString();
                                    }
                                  } catch (e) {
                                    testName = 'عنصر غير معروف';
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.science,
                                            size: 16, color: Colors.purple),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            testName,
                                            style: const TextStyle(
                                                fontFamily: 'Cairo'),
                                          ),
                                        ),
                                        Text(
                                          "$testPrice د.ع",
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })),
                                const Divider(height: 25),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: isAccepted
                                            ? null
                                            : () => _acceptOrder(order['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isAccepted
                                              ? Colors.grey
                                              : Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          disabledBackgroundColor:
                                              Colors.grey[300],
                                          disabledForegroundColor:
                                              Colors.grey[600],
                                        ),
                                        icon: Icon(isAccepted
                                            ? Icons.check
                                            : Icons.thumb_up),
                                        label: Text(
                                          isAccepted
                                              ? 'تم القبول'
                                              : 'قبول الطلب',
                                          style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    InkWell(
                                      onTap: () => _confirmDelete(order['id']),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color:
                                                  Colors.red.withOpacity(0.3)),
                                        ),
                                        child: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
