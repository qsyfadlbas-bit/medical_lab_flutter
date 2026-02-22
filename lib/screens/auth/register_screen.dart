import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:medical_lab_flutter/providers/auth_provider.dart';
import 'package:medical_lab_flutter/widgets/common/gradient_button.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:medical_lab_flutter/screens/home/home_screen.dart';
import 'package:medical_lab_flutter/screens/admin/admin_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  // final _usernameController = TextEditingController(); // ❌ لم نعد بحاجة لهذا
  final _passwordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isGettingLocation = false;
  bool _isLocalLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    // _usernameController.dispose(); // ❌
    _passwordController.dispose();
    _adminCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLocalLoading = false;
        });
      }
    });
  }

  // ... (دالة _getCurrentLocation تبقى كما هي بدون تغيير) ...
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى تفعيل خدمة الموقع (GPS)')));
        setState(() => _isGettingLocation = false);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('تم رفض إذن الموقع')));
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('إذن الموقع مرفوض نهائياً')));
        setState(() => _isGettingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String fullAddress =
              "${place.administrativeArea ?? ''} - ${place.locality ?? ''} - ${place.street ?? ''}";

          setState(() {
            _addressController.text = fullAddress;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم تحديد الموقع بنجاح'),
              backgroundColor: Colors.green));
        }
      } catch (e) {
        setState(() {
          _addressController.text =
              "${position.latitude}, ${position.longitude}";
        });
      }
    } catch (e) {
      print("Location Error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فشل تحديد الموقع')));
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLocalLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // ✅ هنا التغيير: نمرر الاسم الكامل كـ username أيضاً
        final success = await authProvider.register(
          name: _nameController.text,
          username: _nameController.text, // 👈 استخدمنا الاسم الكامل هنا
          email: _emailController.text,
          password: _passwordController.text,
          phone: _phoneController.text,
          adminCode: _adminCodeController.text,
          address: _addressController.text,
        );

        if (!mounted) return;

        setState(() {
          _isLocalLoading = false;
        });

        if (success) {
          final role = authProvider.currentUser?.role;
          if (role == 'ADMIN') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'حدث خطأ أثناء التسجيل',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLocalLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('حدث خطأ غير متوقع'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إنشاء حساب جديد',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // الاسم الكامل (الذي سيستخدم كاسم مستخدم أيضاً)
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const Gap(16),

                // ❌ تم حذف حقل اسم المستخدم من هنا

                // الهاتف
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const Gap(16),

                // حقل العنوان
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'العنوان',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: IconButton(
                      onPressed:
                          _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, color: Colors.blue),
                      tooltip: "تحديد موقعي",
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    helperText:
                        'اضغط على الأيقونة الزرقاء لتحديد موقعك تلقائياً',
                    helperStyle:
                        const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                  ),
                  validator: (v) => v!.isEmpty ? 'العنوان مطلوب' : null,
                ),
                const Gap(16),

                // كلمة المرور
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.length < 6 ? 'كلمة المرور قصيرة' : null,
                ),
                const Gap(16),

                // كود المسؤول
                TextFormField(
                  controller: _adminCodeController,
                  decoration: InputDecoration(
                    labelText: 'كود المسؤول (اختياري)',
                    prefixIcon: const Icon(Icons.security),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    helperText: 'اتركه فارغاً للمستخدم العادي',
                    helperStyle: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                const Gap(32),

                if (_isLocalLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onPressed: _handleRegister,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade600,
                          Colors.green.shade400,
                        ],
                      ),
                      child: const Text(
                        'تسجيل',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
