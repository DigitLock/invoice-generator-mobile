import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/invoice_provider.dart';
import '../widgets/invoice_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import '../widgets/ad_placeholder.dart';

const _dashboardParams = InvoiceListParams(page: 1, pageSize: 10);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      return const Scaffold(body: LoadingIndicator());
    }

    final invoices = ref.watch(invoiceListProvider(_dashboardParams));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(invoiceListProvider(_dashboardParams).future),
              child: invoices.when(
                loading: () => const LoadingIndicator(),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(invoiceListProvider(_dashboardParams)),
                ),
                data: (response) => _DashboardContent(
                  invoices: response.items,
                ),
              ),
            ),
          ),
          const AdPlaceholder(),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.invoices});

  final List invoices;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: FilledButton.icon(
            onPressed: () => context.push('/invoices/new'),
            icon: const Icon(Icons.add),
            label: const Text('New Invoice'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Recent Invoices',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (invoices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('No invoices yet'),
            ),
          )
        else
          ...invoices.map((invoice) => InvoiceCard(invoice: invoice)),
        const SizedBox(height: 8),
      ],
    );
  }
}
