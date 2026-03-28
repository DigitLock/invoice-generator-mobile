import 'package:flutter/material.dart';

class ClientFormScreen extends StatelessWidget {
  const ClientFormScreen({super.key, this.clientId});

  final String? clientId;

  bool get isEditing => clientId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client' : 'New Client'),
      ),
      body: Center(
        child: Text(isEditing ? 'Edit Client: $clientId' : 'New Client'),
      ),
    );
  }
}
