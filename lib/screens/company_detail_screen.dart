import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company.dart';
import '../models/bank_account.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../providers/bank_account_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';

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
    final authState = ref.watch(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      return const Scaffold(body: LoadingIndicator());
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No companies yet.\nCreate one via the web dashboard.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Auto-select first company
          final selectedId = _selectedCompanyId ?? list.first.id;
          final company =
              list.firstWhere((c) => c.id == selectedId, orElse: () => list.first);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(companyListProvider);
              ref.invalidate(bankAccountListProvider(company.id));
            },
            child: ListView(
              children: [
                // Company selector (if multiple)
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

                _CompanyInfoCard(company: company),

                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Bank Accounts',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                _BankAccountsList(companyId: company.id),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompanyInfoCard extends StatelessWidget {
  const _CompanyInfoCard({required this.company});

  final Company company;

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
            Text(company.name,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
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
  const _BankAccountsList({required this.companyId});

  final int companyId;

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
          children:
              list.map((account) => _BankAccountCard(account: account)).toList(),
        );
      },
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  const _BankAccountCard({required this.account});

  final BankAccount account;

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
