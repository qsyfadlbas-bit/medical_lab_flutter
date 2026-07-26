import 'package:flutter/material.dart';

class InspectionsScreen extends StatelessWidget {
  const InspectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحوصاتي'),
      ),
      body: const Center(
        child: Text('شاشة الفحوصات'),
      ),
    );
  }
}
