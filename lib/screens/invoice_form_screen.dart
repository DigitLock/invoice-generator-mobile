import 'package:flutter/material.dart';

class InvoiceFormScreen extends StatelessWidget {
  const InvoiceFormScreen({super.key, this.invoiceId});

  final String? invoiceId;

  bool get isEditing => invoiceId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Invoice' : 'New Invoice'),
      ),
      body: Center(
        child: Text(isEditing ? 'Edit Invoice: $invoiceId' : 'New Invoice'),
      ),
    );
  }
}
