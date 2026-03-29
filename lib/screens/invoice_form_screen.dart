import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/invoice_repository.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/bank_account.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import '../providers/company_provider.dart';
import '../providers/client_provider.dart';
import '../providers/bank_account_provider.dart';
import '../widgets/line_item_row.dart';
import '../widgets/snackbar_helper.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  const InvoiceFormScreen({super.key, this.invoiceId, this.duplicateFrom});

  final String? invoiceId;
  final Invoice? duplicateFrom;

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _initialized = false;

  // Entity selection
  int? _companyId;
  int? _clientId;
  int? _bankAccountId;

  // Invoice details
  final _invoiceNumberController = TextEditingController();
  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;
  String _currency = 'EUR';
  final _vatRateController = TextEditingController(text: '0');
  final _contractRefController = TextEditingController();
  final _externalRefController = TextEditingController();
  final _notesController = TextEditingController();

  // Line items
  final List<LineItemData> _items = [LineItemData()];

  bool get isEditing => widget.invoiceId != null;
  int get _editId => int.parse(widget.invoiceId!);

  @override
  void initState() {
    super.initState();
    final date = DateFormat('ddMMyyyy').format(DateTime.now());
    final newNumber = 'INV-$date-${DateTime.now().millisecondsSinceEpoch % 1000}';

    if (widget.duplicateFrom != null) {
      _populateDuplicate(widget.duplicateFrom!, newNumber);
    } else if (!isEditing) {
      _invoiceNumberController.text = newNumber;
    }
  }

  void _populateDuplicate(Invoice inv, String newNumber) {
    _initialized = true;
    _companyId = inv.companyId;
    _clientId = inv.clientId;
    _bankAccountId = inv.bankAccountId;
    _invoiceNumberController.text = newNumber;
    _issueDate = DateTime.now();
    _dueDate = (inv.dueDate != null && inv.dueDate!.isNotEmpty) ? DateTime.tryParse(inv.dueDate!) : null;
    _currency = inv.currency;
    _vatRateController.text = inv.vatRate;
    _contractRefController.text = inv.contractReference ?? '';
    _externalRefController.text = inv.externalReference ?? '';
    _notesController.text = inv.notes ?? '';

    _items.clear();
    for (final item in inv.items) {
      _items.add(LineItemData(
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      ));
    }
    if (_items.isEmpty) _items.add(LineItemData());
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _vatRateController.dispose();
    _contractRefController.dispose();
    _externalRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.total);

  double get _vatAmount {
    final rate = double.tryParse(_vatRateController.text) ?? 0;
    return (_subtotal * rate / 100 * 100).roundToDouble() / 100;
  }

  double get _total => _subtotal + _vatAmount;

  void _populateFromInvoice(Invoice inv) {
    if (_initialized) return;
    _initialized = true;

    _companyId = inv.companyId;
    _clientId = inv.clientId;
    _bankAccountId = inv.bankAccountId;
    _invoiceNumberController.text = inv.invoiceNumber;
    _issueDate = DateTime.tryParse(inv.issueDate) ?? DateTime.now();
    _dueDate = inv.dueDate != null ? DateTime.tryParse(inv.dueDate!) : null;
    _currency = inv.currency;
    _vatRateController.text = inv.vatRate;
    _contractRefController.text = inv.contractReference ?? '';
    _externalRefController.text = inv.externalReference ?? '';
    _notesController.text = inv.notes ?? '';

    _items.clear();
    for (final item in inv.items) {
      _items.add(LineItemData(
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      ));
    }
    if (_items.isEmpty) _items.add(LineItemData());
  }

  Future<void> _pickDate(BuildContext context, bool isIssueDate) async {
    final initial = isIssueDate ? _issueDate : (_dueDate ?? _issueDate);
    final first = isIssueDate ? DateTime(2020) : _issueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
          if (_dueDate != null && _dueDate!.isBefore(_issueDate)) _dueDate = _issueDate;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_companyId == null || _clientId == null || _bankAccountId == null) {
      showErrorSnackbar(context, 'Please select company, client, and bank account');
      return;
    }
    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'company_id': _companyId,
      'client_id': _clientId,
      'bank_account_id': _bankAccountId,
      'issue_date': DateFormat('yyyy-MM-dd').format(_issueDate),
      if (_dueDate != null)
        'due_date': DateFormat('yyyy-MM-dd').format(_dueDate!),
      'currency': _currency,
      'vat_rate': _vatRateController.text,
      'items': _items.map((i) => i.toJson()).toList(),
    };

    if (_contractRefController.text.isNotEmpty) {
      payload['contract_reference'] = _contractRefController.text;
    }
    if (_externalRefController.text.isNotEmpty) {
      payload['external_reference'] = _externalRefController.text;
    }
    if (_notesController.text.isNotEmpty) {
      payload['notes'] = _notesController.text;
    }

    payload['invoice_number'] = _invoiceNumberController.text;

    try {
      final repo = ref.read(invoiceRepositoryProvider);
      if (isEditing) {
        await repo.update(_editId, payload);
        ref.invalidate(invoiceListProvider);
        ref.invalidate(invoiceDetailProvider(_editId));
        if (mounted) {
          HapticFeedback.mediumImpact();
          showSuccessSnackbar(context, 'Invoice updated');
          context.pop();
        }
      } else {
        final created = await repo.create(payload);
        ref.invalidate(invoiceListProvider);
        if (mounted) {
          HapticFeedback.mediumImpact();
          showSuccessSnackbar(context, 'Invoice created');
          context.pop();
          context.push('/invoices/${created.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Save failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load existing invoice for edit mode
    if (isEditing && !_initialized) {
      final invoiceAsync = ref.watch(invoiceDetailProvider(_editId));
      return invoiceAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Invoice')),
          body: const LoadingIndicator(),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Invoice')),
          body: ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(invoiceDetailProvider(_editId)),
          ),
        ),
        data: (inv) {
          _populateFromInvoice(inv);
          return _buildForm(context);
        },
      );
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final companies = ref.watch(companyListProvider);
    final clients = ref.watch(clientListProvider('active'));
    final bankAccounts = _companyId != null
        ? ref.watch(bankAccountListProvider(_companyId!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Invoice' : 'New Invoice'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Entity selection
            _SectionHeader('Entity Selection'),

            // Company
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: companies.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading companies: $e'),
                data: (list) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _companyId,
                        decoration: const InputDecoration(labelText: 'Company'),
                        items: list
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _companyId = v;
                            _bankAccountId = null;
                          });
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'New Company',
                        onPressed: () async {
                          await context.push('/company/new');
                          if (mounted) ref.invalidate(companyListProvider);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Client
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: clients.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading clients: $e'),
                data: (list) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _clientId,
                        decoration: const InputDecoration(labelText: 'Client'),
                        items: list
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _clientId = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'New Client',
                        onPressed: () async {
                          await context.push('/clients/new');
                          if (mounted) ref.invalidate(clientListProvider('active'));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bank account
            if (bankAccounts != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: bankAccounts.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (list) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bankAccountId,
                          decoration:
                              const InputDecoration(labelText: 'Bank Account'),
                          items: list
                              .map((b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text('${b.bankName} (${b.currency})')))
                              .toList(),
                          onChanged: (v) => setState(() => _bankAccountId = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'New Bank Account',
                          onPressed: () async {
                            await context.push(
                                '/company/$_companyId/bank-accounts/new');
                            if (mounted) {
                              ref.invalidate(
                                  bankAccountListProvider(_companyId!));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 32),
            _SectionHeader('Invoice Details'),

            // Invoice number
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: _invoiceNumberController,
                decoration: const InputDecoration(labelText: 'Invoice Number'),
              ),
            ),

            // Dates
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Issue Date',
                      date: _issueDate,
                      onTap: () => _pickDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due Date',
                          suffixIcon: _dueDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () =>
                                      setState(() => _dueDate = null),
                                )
                              : null,
                        ),
                        child: _dueDate != null
                            ? Text(DateFormat('dd MMM yyyy').format(_dueDate!))
                            : Text('Select date',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Currency + VAT rate
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: const [
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'RSD', child: Text('RSD')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _currency = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _vatRateController,
                      decoration: const InputDecoration(
                        labelText: 'VAT Rate (%)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),

            // Contract + external ref
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: _contractRefController,
                decoration:
                    const InputDecoration(labelText: 'Contract Reference'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: _externalRefController,
                decoration:
                    const InputDecoration(labelText: 'External Reference'),
              ),
            ),

            const Divider(height: 32),
            _SectionHeader('Line Items'),

            // Items
            ..._items.asMap().entries.map((entry) => LineItemRow(
                  index: entry.key,
                  item: entry.value,
                  onChanged: () => setState(() {}),
                  onDismissed: () {
                    setState(() {
                      _items.removeAt(entry.key);
                      if (_items.isEmpty) _items.add(LineItemData());
                    });
                  },
                )),

            if (_items.length < 10)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _items.add(LineItemData())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ),

            const Divider(height: 32),
            _SectionHeader('Totals'),
            _TotalRow('Subtotal', _subtotal, _currency),
            _TotalRow('VAT', _vatAmount, _currency),
            _TotalRow('Total', _total, _currency, bold: true),

            const Divider(height: 32),
            _SectionHeader('Notes'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: date != null
            ? Text(DateFormat('dd MMM yyyy').format(date!))
            : Text(
                'Select date',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.amount, this.currency, {this.bold = false});

  final String label;
  final double amount;
  final String currency;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final symbol = currency == 'EUR' ? '\u20AC' : currency;
    final style = bold
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('$symbol${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
