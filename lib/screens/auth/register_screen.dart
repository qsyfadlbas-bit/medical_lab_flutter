import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:medical_lab_flutter/providers/auth_provider.dart';
import 'package:medical_lab_flutter/widgets/common/gradient_button.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ أضفنا استيراد الروابط

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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isGettingLocation = false;
  bool _isLocalLoading = false;

  // ✅ متغير الموافقة على الشروط
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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

  // ✅ دالة لفتح روابط الشروط والخصوصية
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('يرجى تفعيل خدمة الموقع (GPS)',
                style: TextStyle(fontFamily: 'Cairo'))));
        setState(() => _isGettingLocation = false);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم رفض إذن الموقع',
                  style: TextStyle(fontFamily: 'Cairo'))));
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('إذن الموقع مرفوض نهائياً',
                style: TextStyle(fontFamily: 'Cairo'))));
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
              content: Text('تم تحديد الموقع بنجاح',
                  style: TextStyle(fontFamily: 'Cairo')),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('فشل تحديد الموقع', style: TextStyle(fontFamily: 'Cairo'))));
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  // تنظيف رقم الهاتف: إزالة المسافات والرموز وتحويل +964 إلى 0
  String _normalizePhone(String raw) {
    String phone = raw.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (phone.startsWith('+964')) {
      phone = '0${phone.substring(4)}';
    } else if (phone.startsWith('00964')) {
      phone = '0${phone.substring(5)}';
    } else if (phone.startsWith('964')) {
      phone = '0${phone.substring(3)}';
    }
    return phone;
  }

  void _handleRegister() async {
    // ✅ التأكد من الموافقة على الشروط قبل الإرسال
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يجب الموافقة على شروط الخدمة وسياسة الخصوصية أولاً',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLocalLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        final phone = _normalizePhone(_phoneController.text);
        final generatedUsername = phone; // اسم المستخدم هو رقم الهاتف
        final generatedEmail =
            "$phone@lab.com"; // إيميل تلقائي مبني على رقم الهاتف

        final success = await authProvider.register(
          name: _nameController.text.trim(),
          username: generatedUsername,
          email: generatedEmail,
          password: _passwordController.text,
          phone: phone,
          adminCode: _adminCodeController.text.trim(),
          address: _addressController.text.trim(),
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
                content: Text('حدث خطأ غير متوقع',
                    style: TextStyle(fontFamily: 'Cairo')),
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
                // الاسم الكامل
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

                // الهاتف
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: '07XXXXXXXXX',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'مطلوب';
                    final cleaned = _normalizePhone(v);
                    if (!RegExp(r'^07[0-9]{9}$').hasMatch(cleaned)) {
                      return 'أدخل رقماً عراقياً صحيحاً (07XXXXXXXXX)';
                    }
                    return null;
                  },
                ),
                const Gap(16),

                // حقل العنوان والموقع
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
                  validator: (v) => (v == null || v.length < 6)
                      ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
                      : null,
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
                const Gap(24),

                // ✅ قسم الموافقة على شروط الخدمة والخصوصية
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        activeColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'بإنشاء حساب، أنت توافق على ',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.grey),
                          ),
                          InkWell(
                            onTap: () => _launchURL(
                                'https://alqimmalab.alqadateam.com/privacy-policy.html'),
                            child: Text(
                              'شروط الخدمة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(
                            ' و ',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.grey),
                          ),
                          InkWell(
                            onTap: () => _launchURL(
                                'https://alqimmalab.alqadateam.com/privacy-policy.html'),
                            child: Text(
                              'سياسة الخصوصية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(24),

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
