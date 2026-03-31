import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/company_repository.dart';
import '../data/bank_account_repository.dart';
import '../models/company.dart';
import '../models/bank_account.dart';
import '../providers/app_mode_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../providers/bank_account_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import '../widgets/snackbar_helper.dart';

class CompanyDetailScreen extends ConsumerStatefulWidget {
  const CompanyDetailScreen({super.key});

  @override
  ConsumerState<CompanyDetailScreen> createState() =>
      _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  int? _selectedCompanyId;

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(appModeProvider).mode == AppMode.offline;
    final isOnline = !isOffline;

    if (isOnline) {
      final authState = ref.watch(authProvider);
      if (authState.status != AuthStatus.authenticated) {
        return const Scaffold(body: LoadingIndicator());
      }
    }

    final companies = ref.watch(companyListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Company')),
      body: companies.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(companyListProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business_outlined,
                        size: 64, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 16),
                    Text(
                      isOffline
                          ? 'No companies yet'
                          : 'No companies yet.\nCreate one via the web dashboard.',
                      textAlign: TextAlign.center,
                    ),
                    if (isOffline) ...[
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () => context.push('/company/new'),
                        child: const Text('Create Company'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          final selectedId = _selectedCompanyId ?? list.first.id;
          final company = list.firstWhere((c) => c.id == selectedId,
              orElse: () => list.first);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(companyListProvider);
              ref.invalidate(bankAccountListProvider(company.id));
            },
            child: ListView(
              children: [
                if (list.length > 1)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: DropdownButtonFormField<int>(
                      value: company.id,
                      decoration:
                          const InputDecoration(labelText: 'Select Company'),
                      items: list
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCompanyId = v),
                    ),
                  ),

                _CompanyInfoCard(
                  company: company,
                  showEdit: isOffline,
                  onDelete: isOffline
                      ? () => _confirmDeleteCompany(context, company)
                      : null,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Bank Accounts',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isOffline)
                        TextButton.icon(
                          onPressed: () => context
                              .push('/company/${company.id}/bank-accounts/new'),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                    ],
                  ),
                ),

                _BankAccountsList(
                  companyId: company.id,
                  allowDelete: isOffline,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: (ref.watch(appModeProvider).mode == AppMode.offline)
          ? FloatingActionButton(
              onPressed: () => context.push('/company/new'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _confirmDeleteCompany(BuildContext context, Company company) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text('Delete "${company.name}" and all its bank accounts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(companyRepositoryProvider).delete(company.id);
                ref.invalidate(companyListProvider);
                if (mounted) {
                  HapticFeedback.mediumImpact();
                  showSuccessSnackbar(context, 'Company deleted');
                  setState(() => _selectedCompanyId = null);
                }
              } catch (e) {
                if (mounted) showErrorSnackbar(context, 'Delete failed: $e');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CompanyInfoCard extends StatelessWidget {
  const _CompanyInfoCard({
    required this.company,
    this.showEdit = false,
    this.onDelete,
  });

  final Company company;
  final bool showEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(company.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (showEdit)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () =>
                        context.push('/company/${company.id}/edit'),
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20,
                        color: theme.colorScheme.error),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _Row('Contact', company.contactPerson),
            _Row('Address', company.address),
            if (company.phone != null) _Row('Phone', company.phone!),
            if (company.vatNumber != null) _Row('VAT', company.vatNumber!),
            if (company.regNumber != null) _Row('Reg No.', company.regNumber!),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _BankAccountsList extends ConsumerWidget {
  const _BankAccountsList({
    required this.companyId,
    this.allowDelete = false,
  });

  final int companyId;
  final bool allowDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(bankAccountListProvider(companyId));

    return accounts.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading bank accounts: $e'),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No bank accounts'),
          );
        }
        return Column(
          children: list
              .map((account) => _BankAccountCard(
                    account: account,
                    onEdit: allowDelete
                        ? () => context.push(
                            '/company/$companyId/bank-accounts/${account.id}/edit')
                        : null,
                    onDelete: allowDelete
                        ? () => _confirmDelete(context, ref, account)
                        : null,
                  ))
              .toList(),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, BankAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bank Account'),
        content: Text('Delete "${account.bankName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(bankAccountRepositoryProvider)
                    .delete(account.id);
                ref.invalidate(bankAccountListProvider(companyId));
                HapticFeedback.mediumImpact();
                if (context.mounted) {
                  showSuccessSnackbar(context, 'Bank account deleted');
                }
              } catch (e) {
                if (context.mounted) {
                  showErrorSnackbar(context, 'Delete failed: $e');
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  const _BankAccountCard({
    required this.account,
    this.onEdit,
    this.onDelete,
  });

  final BankAccount account;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(account.bankName,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                if (account.isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Default',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer)),
                  ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20,
                        color: theme.colorScheme.error),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _Row('IBAN', account.iban),
            _Row('SWIFT', account.swift),
            _Row('Currency', account.currency),
            if (account.bankAddress.isNotEmpty)
              _Row('Address', account.bankAddress),
          ],
        ),
      ),
    );
  }
}
