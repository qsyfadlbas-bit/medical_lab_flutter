import 'package:flutter/material.dart';

class NewOrderScreen extends StatelessWidget {
  const NewOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب جديد'),
      ),
      body: const Center(
        child: Text('شاشة طلب جديد'),
      ),
    );
  }
}
