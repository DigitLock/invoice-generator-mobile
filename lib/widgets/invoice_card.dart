import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/invoice.dart';
import 'status_badge.dart';
import 'overdue_badge.dart';

class InvoiceCard extends StatelessWidget {
  const InvoiceCard({super.key, required this.invoice});

  final InvoiceListItem invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = _formatDate(invoice.issueDate);
    final totalStr = _formatAmount(invoice.total, invoice.currency);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/invoices/${invoice.id}'),
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
                      invoice.invoiceNumber,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    totalStr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.clientName,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  StatusBadge(status: invoice.status),
                  if (invoice.isOverdue) const OverdueBadge(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  static String _formatAmount(String amount, String currency) {
    final symbol = currency == 'EUR' ? '\u20AC' : currency;
    try {
      final value = double.parse(amount);
      return '$symbol${value.toStringAsFixed(2)}';
    } catch (_) {
      return '$symbol$amount';
    }
  }
}
