import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/services/api_service.dart';

class ManageTestsScreen extends StatefulWidget {
  const ManageTestsScreen({super.key});

  @override
  State<ManageTestsScreen> createState() => _ManageTestsScreenState();
}

class _ManageTestsScreenState extends State<ManageTestsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _tests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTests();
  }

  // 1. جلب التحاليل
  Future<void> _fetchTests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/tests');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tests = data['data'];
        });
      }
    } catch (e) {
      print("Error fetching tests: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. إضافة تحليل جديد
  Future<void> _addTest(Map<String, dynamic> testData) async {
    try {
      Navigator.pop(context); // إغلاق النافذة
      _showLoadingSnackBar('جاري الإضافة...');

      final response = await _apiService.post('/tests', testData);

      if (response.statusCode == 201) {
        _showSuccessSnackBar('✅ تم إضافة التحليل بنجاح');
        _fetchTests();
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      _showErrorSnackBar('❌ فشل الإضافة: تأكد أن الكود غير مكرر');
    }
  }

  // ✅ 3. تعديل تحليل موجود
  Future<void> _updateTest(String id, Map<String, dynamic> testData) async {
    try {
      Navigator.pop(context); // إغلاق النافذة
      _showLoadingSnackBar('جاري التعديل...');

      final response = await _apiService.put('/tests/$id', testData);

      if (response.statusCode == 200) {
        _showSuccessSnackBar('✅ تم تعديل البيانات بنجاح');
        _fetchTests();
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      print(e);
      _showErrorSnackBar('❌ فشل التعديل');
    }
  }

  // ✅ 4. حذف تحليل
  Future<void> _confirmDelete(String id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا التحليل؟',
            style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteTest(id);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTest(String id) async {
    try {
      final response = await _apiService.delete('/tests/$id');
      if (response.statusCode == 200) {
        setState(() {
          _tests.removeWhere((item) => item['_id'] == id);
        });
        _showSuccessSnackBar('تم الحذف بنجاح');
      }
    } catch (e) {
      _showErrorSnackBar('فشل الحذف');
    }
  }

  void _showLoadingSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ✅ نافذة الإضافة والتعديل (مع التصنيفات الجديدة)
  void _showTestDialog({Map<String, dynamic>? testToEdit}) {
    final isEditing = testToEdit != null;

    final nameArController =
        TextEditingController(text: isEditing ? testToEdit['nameAr'] : '');
    final nameEnController =
        TextEditingController(text: isEditing ? testToEdit['nameEn'] : '');
    final codeController =
        TextEditingController(text: isEditing ? testToEdit['code'] : '');
    final priceController = TextEditingController(
        text: isEditing ? testToEdit['price'].toString() : '');

    String category =
        isEditing ? (testToEdit['category'] ?? 'فحوصات الدم') : 'فحوصات الدم';

    // ✅ القائمة المحدثة (أضيفت لها الأقسام الجديدة والعروض)
    final categories = [
      'فحوصات الدم',
      'الكيمياء الحيوية', // جديد
      'فايروسات', // جديد
      'مناعة', // جديد
      'البكتيريا', // جديد
      'الهرمونات',
      'الفيتامينات',
      'وظائف الأعضاء',
      'أخرى'
    ];

    if (!categories.contains(category)) category = 'أخرى';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل التحليل' : 'إضافة تحليل جديد',
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameArController,
                  decoration: const InputDecoration(
                      labelText: 'الاسم بالعربي',
                      hintText: 'مثال: تحليل دم شامل')),
              const SizedBox(height: 10),
              TextField(
                  controller: nameEnController,
                  decoration: const InputDecoration(
                      labelText: 'الاسم بالإنجليزي', hintText: 'Ex: CBC')),
              const SizedBox(height: 10),
              TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                      labelText: 'الكود', hintText: 'Ex: CBC01')),
              const SizedBox(height: 10),
              TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'السعر (د.ع)', hintText: 'مثال: 5000')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: categories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => category = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () {
              if (nameArController.text.isEmpty ||
                  priceController.text.isEmpty ||
                  codeController.text.isEmpty) {
                _showErrorSnackBar('يرجى ملء الحقول الأساسية!');
                return;
              }

              String rawPrice =
                  priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
              if (rawPrice.isEmpty) {
                _showErrorSnackBar('السعر غير صحيح!');
                return;
              }

              final data = {
                "nameAr": nameArController.text,
                "nameEn": nameEnController.text.isNotEmpty
                    ? nameEnController.text
                    : nameArController.text,
                "code": codeController.text,
                "price": int.parse(rawPrice),
                "category": category
              };

              if (isEditing) {
                _updateTest(testToEdit['_id'], data);
              } else {
                _addTest(data);
              }
            },
            child: Text(isEditing ? 'تحديث' : 'حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('إدارة التحاليل', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tests.isEmpty
              ? const Center(
                  child: Text("لا توجد تحاليل، أضف واحداً الآن!",
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 18)))
              : ListView.builder(
                  itemCount: _tests.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final test = _tests[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          child: Text(
                            test['code'] != null && test['code'].length >= 2
                                ? test['code'].substring(0, 2).toUpperCase()
                                : 'LB',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo),
                          ),
                        ),
                        title: Text(test['nameAr'] ?? 'بدون اسم',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo')),
                        subtitle: Text(
                          '${test['nameEn'] ?? ''}\n${test['price']} د.ع - ${test['category'] ?? ''}',
                          style: const TextStyle(
                              fontFamily: 'Cairo', fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showTestDialog(testToEdit: test),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(test['_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTestDialog(),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
