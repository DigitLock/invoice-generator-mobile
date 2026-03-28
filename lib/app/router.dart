import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/invoice_list_screen.dart';
import '../screens/invoice_detail_screen.dart';
import '../screens/invoice_form_screen.dart';
import '../screens/client_list_screen.dart';
import '../screens/client_form_screen.dart';
import '../screens/company_detail_screen.dart';
import '../widgets/shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.uri.path == '/login';
      final isSplash = state.uri.path == '/splash';

      // While checking stored auth, stay on splash
      if (authState.status == AuthStatus.unknown) {
        return isSplash ? null : '/splash';
      }

      // Splash done — redirect based on auth
      if (isSplash) return isAuth ? '/' : '/login';

      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && isLoggingIn) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
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
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => InvoiceFormScreen(
              invoiceId: state.pathParameters['id'],
            ),
          ),
        ],
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
});

class _AuthChangeNotifier extends ChangeNotifier {
  late final Function _removeListener;

  _AuthChangeNotifier(Ref ref) {
    _removeListener = ref.listen(authProvider, (_, __) {
      notifyListeners();
    }).close;
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }
}
