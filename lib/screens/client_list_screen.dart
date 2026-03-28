import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/client.dart';
import '../providers/app_mode_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/client_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import '../widgets/ad_placeholder.dart';

const _filters = [
  _Filter(null, 'All'),
  _Filter('active', 'Active'),
  _Filter('inactive', 'Inactive'),
];

class _Filter {
  final String? value;
  final String label;
  const _Filter(this.value, this.label);
}

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(appModeProvider) == AppMode.online;
    if (isOnline) {
      final authState = ref.watch(authProvider);
      if (authState.status != AuthStatus.authenticated) {
        return const Scaffold(body: LoadingIndicator());
      }
    }

    final clients = ref.watch(clientListProvider(_statusFilter));

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _statusFilter == filter.value;
                return FilterChip(
                  label: Text(filter.label),
                  selected: isSelected,
                  onSelected: (_) {
                    if (_statusFilter != filter.value) {
                      setState(() => _statusFilter = filter.value);
                    }
                  },
                );
              },
            ),
          ),

          Expanded(
            child: clients.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(clientListProvider(_statusFilter)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outlined,
                            size: 64, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 16),
                        const Text('No clients found'),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => context.push('/clients/new'),
                          child: const Text('Create Client'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref
                      .refresh(clientListProvider(_statusFilter).future),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) =>
                        _ClientCard(client: list[index]),
                  ),
                );
              },
            ),
          ),
          const AdPlaceholder(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/clients/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/clients/${client.id}/edit'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      client.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: client.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                client.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (client.contractReference != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Ref: ${client.contractReference}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
