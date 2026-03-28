import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_mode_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/invoice_list_screen.dart';
import '../screens/invoice_detail_screen.dart';
import '../screens/invoice_form_screen.dart';
import '../screens/client_list_screen.dart';
import '../screens/client_form_screen.dart';
import '../screens/company_detail_screen.dart';
import '../screens/company_form_screen.dart';
import '../screens/bank_account_form_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final appMode = ref.read(appModeProvider);
      final path = state.uri.path;

      // First launch — mode not chosen yet
      if (appMode == null) {
        return path == '/welcome' ? null : '/welcome';
      }

      // Never redirect away from welcome/settings/server-settings
      if (path == '/welcome' || path == '/settings' || path == '/server-settings') {
        return null;
      }

      // Offline mode — no auth needed, go straight to app
      if (appMode == AppMode.offline) {
        if (path == '/splash' || path == '/login') return '/';
        return null;
      }

      // Online mode — full auth flow
      final authState = ref.read(authProvider);
      final isAuth = authState.status == AuthStatus.authenticated;
      final isLoggingIn = path == '/login';
      final isSplash = path == '/splash';

      if (authState.status == AuthStatus.unknown) {
        return isSplash ? null : '/splash';
      }

      if (isSplash) return isAuth ? '/' : '/login';

      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && isLoggingIn) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
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
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // TODO: /server-settings route — Stage 4.9
      GoRoute(
        path: '/server-settings',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Server Settings')),
          body: const Center(child: Text('Coming soon')),
        ),
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
      GoRoute(
        path: '/company/new',
        builder: (context, state) => const CompanyFormScreen(),
      ),
      GoRoute(
        path: '/company/:id/edit',
        builder: (context, state) => CompanyFormScreen(
          companyId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/company/:id/bank-accounts/new',
        builder: (context, state) => BankAccountFormScreen(
          companyId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  late final Function _removeAuthListener;
  late final Function _removeModeListener;

  _RouterRefreshNotifier(Ref ref) {
    _removeAuthListener = ref.listen(authProvider, (_, __) {
      notifyListeners();
    }).close;
    _removeModeListener = ref.listen(appModeProvider, (_, __) {
      notifyListeners();
    }).close;
  }

  @override
  void dispose() {
    _removeAuthListener();
    _removeModeListener();
    super.dispose();
  }
}
