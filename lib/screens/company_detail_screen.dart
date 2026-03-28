import 'package:flutter/material.dart';

class CompanyDetailScreen extends StatelessWidget {
  const CompanyDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company')),
      body: const Center(
        child: Text('Company'),
      ),
    );
  }
}
