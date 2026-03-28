import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/invoice_list_screen.dart';
import '../screens/invoice_detail_screen.dart';
import '../screens/invoice_form_screen.dart';
import '../screens/client_list_screen.dart';
import '../screens/client_form_screen.dart';
import '../screens/company_detail_screen.dart';
import '../widgets/shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/invoices',
          builder: (context, state) => const InvoiceListScreen(),
        ),
        GoRoute(
          path: '/clients',
          builder: (context, state) => const ClientListScreen(),
        ),
        GoRoute(
          path: '/company',
          builder: (context, state) => const CompanyDetailScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/invoices/new',
      builder: (context, state) => const InvoiceFormScreen(),
    ),
    GoRoute(
      path: '/invoices/:id',
      builder: (context, state) => InvoiceDetailScreen(
        invoiceId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/invoices/:id/edit',
      builder: (context, state) => InvoiceFormScreen(
        invoiceId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/clients/new',
      builder: (context, state) => const ClientFormScreen(),
    ),
    GoRoute(
      path: '/clients/:id/edit',
      builder: (context, state) => ClientFormScreen(
        clientId: state.pathParameters['id'],
      ),
    ),
  ],
);
