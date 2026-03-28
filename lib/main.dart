import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: InvoiceGeneratorApp(),
    ),
  );
}

class InvoiceGeneratorApp extends StatelessWidget {
  const InvoiceGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Invoice Generator',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
