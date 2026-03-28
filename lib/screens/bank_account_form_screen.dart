import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/bank_account_repository.dart';
import '../providers/bank_account_provider.dart';
import '../widgets/snackbar_helper.dart';

class BankAccountFormScreen extends ConsumerStatefulWidget {
  const BankAccountFormScreen({super.key, required this.companyId});

  final int companyId;

  @override
  ConsumerState<BankAccountFormScreen> createState() =>
      _BankAccountFormScreenState();
}

class _BankAccountFormScreenState
    extends ConsumerState<BankAccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _bankNameController = TextEditingController();
  final _bankAddressController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _ibanController = TextEditingController();
  final _swiftController = TextEditingController();
  String _currency = 'EUR';
  bool _isDefault = false;

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankAddressController.dispose();
    _accountHolderController.dispose();
    _ibanController.dispose();
    _swiftController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'bank_name': _bankNameController.text.trim(),
      'bank_address': _bankAddressController.text.trim(),
      'account_holder': _accountHolderController.text.trim(),
      'iban': _ibanController.text.trim(),
      'swift': _swiftController.text.trim(),
      'currency': _currency,
      'is_default': _isDefault,
    };

    try {
      await ref
          .read(bankAccountRepositoryProvider)
          .create(widget.companyId, payload);
      ref.invalidate(bankAccountListProvider(widget.companyId));
      if (mounted) {
        HapticFeedback.mediumImpact();
        showSuccessSnackbar(context, 'Bank account created');
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bank Account'),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(labelText: 'Bank Name'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bankAddressController,
              decoration: const InputDecoration(labelText: 'Bank Address'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountHolderController,
              decoration: const InputDecoration(labelText: 'Account Holder'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ibanController,
              decoration: const InputDecoration(labelText: 'IBAN'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _swiftController,
              decoration: const InputDecoration(labelText: 'SWIFT'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
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
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Default Account'),
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
