import 'package:flutter/material.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice #$invoiceId')),
      body: Center(
        child: Text('Invoice Detail: $invoiceId'),
      ),
    );
  }
}
