import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../data/invoice_repository.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/overdue_badge.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import '../widgets/snackbar_helper.dart';

const _allowedTransitions = {
  'draft': ['sent', 'cancelled'],
  'sent': ['partially_paid', 'paid', 'cancelled'],
  'partially_paid': ['paid', 'cancelled'],
};

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  int get _id => int.parse(invoiceId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(invoiceDetailProvider(_id));

    return invoice.when(
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(invoiceDetailProvider(_id)),
        ),
      ),
      data: (inv) => _DetailScaffold(invoice: inv, invoiceId: _id),
    );
  }
}

class _DetailScaffold extends ConsumerWidget {
  const _DetailScaffold({required this.invoice, required this.invoiceId});

  final Invoice invoice;
  final int invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transitions = _allowedTransitions[invoice.status] ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? const BackButton()
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
        title: Text(invoice.invoiceNumber),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _onMenuAction(context, ref, v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(invoiceDetailProvider(invoiceId).future),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Status + overdue
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(status: invoice.status),
                  if (invoice.isOverdue) const OverdueBadge(),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _downloadPdf(context, ref),
                      child: const Text('Download PDF'),
                    ),
                  ),
                  if (transitions.isNotEmpty) const SizedBox(width: 8),
                  if (transitions.isNotEmpty)
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () =>
                            _showStatusSheet(context, ref, transitions),
                        child: const Text('Change Status'),
                      ),
                    ),
                ],
              ),
            ),

            // Overdue toggle
            if (invoice.status != 'draft')
              SwitchListTile(
                title: const Text('Overdue'),
                value: invoice.isOverdue,
                onChanged: (v) => _toggleOverdue(context, ref, v),
              ),

            const Divider(),

            // Dates
            _SectionTitle('Dates'),
            _InfoRow('Issue Date', _formatDate(invoice.issueDate)),
            if (invoice.dueDate != null && invoice.dueDate!.isNotEmpty)
              _InfoRow('Due Date', _formatDate(invoice.dueDate!)),
            if (invoice.contractReference != null)
              _InfoRow('Contract Ref', invoice.contractReference!),
            if (invoice.externalReference != null)
              _InfoRow('External Ref', invoice.externalReference!),

            const Divider(),

            // From
            if (invoice.company != null) ...[
              _SectionTitle('From'),
              _CompanyCard(invoice.company!),
              const Divider(),
            ],

            // Bill To
            if (invoice.client != null) ...[
              _SectionTitle('Bill To'),
              _ClientCard(invoice.client!),
              const Divider(),
            ],

            // Line Items
            _SectionTitle('Items'),
            _ItemsTable(invoice.items, invoice.currency),

            const Divider(),

            // Totals
            _SectionTitle('Totals'),
            _InfoRow('Subtotal', _formatAmount(invoice.subtotal, invoice.currency)),
            _InfoRow(
              'VAT (${invoice.vatRate}%)',
              _formatAmount(invoice.vatAmount, invoice.currency),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    _formatAmount(invoice.total, invoice.currency),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // Payment details
            if (invoice.bankAccount != null) ...[
              const Divider(),
              _SectionTitle('Payment Details'),
              _InfoRow('Bank', invoice.bankAccount!.bankName),
              _InfoRow('IBAN', invoice.bankAccount!.iban),
              _InfoRow('SWIFT', invoice.bankAccount!.swift),
            ],

            // Notes
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              const Divider(),
              _SectionTitle('Notes'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(invoice.notes!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onMenuAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'edit') {
      context.push('/invoices/$invoiceId/edit');
    } else if (action == 'duplicate') {
      context.push('/invoices/new', extra: invoice);
    } else if (action == 'delete') {
      _confirmDelete(context, ref);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Delete ${invoice.invoiceNumber}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              HapticFeedback.mediumImpact();
              try {
                await ref
                    .read(invoiceRepositoryProvider)
                    .delete(invoiceId);
                ref.invalidate(invoiceListProvider);
                if (context.mounted) context.pop();
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

  void _showStatusSheet(
      BuildContext context, WidgetRef ref, List<String> transitions) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Change Status',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...transitions.map((status) => ListTile(
                  leading: StatusBadge(status: status),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _confirmStatusChange(context, ref, status);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmStatusChange(
      BuildContext context, WidgetRef ref, String newStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Status Change'),
        content: Text(
          'Change status from "${_statusLabel(invoice.status)}" to "${_statusLabel(newStatus)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              HapticFeedback.mediumImpact();
              try {
                await ref
                    .read(invoiceRepositoryProvider)
                    .changeStatus(invoiceId, newStatus);
                ref.invalidate(invoiceDetailProvider(invoiceId));
                ref.invalidate(invoiceListProvider);
                if (context.mounted) {
                  showSuccessSnackbar(context, 'Status updated to ${_statusLabel(newStatus)}');
                }
              } catch (e) {
                if (context.mounted) {
                  showErrorSnackbar(context, 'Status change failed: $e');
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _toggleOverdue(BuildContext context, WidgetRef ref, bool value) async {
    try {
      await ref
          .read(invoiceRepositoryProvider)
          .toggleOverdue(invoiceId, value);
      ref.invalidate(invoiceDetailProvider(invoiceId));
      ref.invalidate(invoiceListProvider);
    } catch (e) {
      if (context.mounted) {
        showErrorSnackbar(context, 'Failed: $e');
      }
    }
  }

  void _downloadPdf(BuildContext context, WidgetRef ref) async {
    try {
      showSuccessSnackbar(context, 'Downloading PDF...');
      final path = await ref
          .read(invoiceRepositoryProvider)
          .downloadPdf(invoiceId);
      await OpenFile.open(path);
    } catch (e) {
      if (context.mounted) {
        showErrorSnackbar(context, 'PDF download failed: $e');
      }
    }
  }

  static String _formatDate(String isoDate) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  static String _formatAmount(String amount, String currency) {
    final symbol = currency == 'EUR' ? '\u20AC' : currency;
    try {
      return '$symbol${double.parse(amount).toStringAsFixed(2)}';
    } catch (_) {
      return '$symbol$amount';
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'draft': return 'Draft';
      case 'sent': return 'Sent';
      case 'partially_paid': return 'Partially Paid';
      case 'paid': return 'Paid';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard(this.company);
  final dynamic company;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company.name,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            if (company.contactPerson.isNotEmpty)
              Text(company.contactPerson),
            Text(company.address),
            if (company.vatNumber != null)
              Text('VAT: ${company.vatNumber}'),
            if (company.regNumber != null)
              Text('Reg: ${company.regNumber}'),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard(this.client);
  final dynamic client;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(client.name,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            if (client.contactPerson != null)
              Text(client.contactPerson!),
            if (client.email != null) Text(client.email!),
            Text(client.address),
            if (client.vatNumber != null)
              Text('VAT: ${client.vatNumber}'),
          ],
        ),
      ),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable(this.items, this.currency);
  final List<InvoiceItem> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = currency == 'EUR' ? '\u20AC' : currency;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            children: [
              _headerCell('Description', theme),
              _headerCell('Qty', theme),
              _headerCell('Price', theme),
              _headerCell('Total', theme),
            ],
          ),
          ...items.map((item) => TableRow(
                children: [
                  _cell(item.description),
                  _cell(item.quantity),
                  _cell('$symbol${item.unitPrice}'),
                  _cell('$symbol${item.total}'),
                ],
              )),
        ],
      ),
    );
  }

  Widget _headerCell(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text,
          style: theme.textTheme.labelSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _cell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, overflow: TextOverflow.ellipsis),
    );
  }
}
