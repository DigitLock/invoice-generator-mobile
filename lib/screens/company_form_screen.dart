import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/company_repository.dart';
import '../providers/company_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import '../widgets/snackbar_helper.dart';

class CompanyFormScreen extends ConsumerStatefulWidget {
  const CompanyFormScreen({super.key, this.companyId});

  final String? companyId;

  @override
  ConsumerState<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends ConsumerState<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _initialized = false;

  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _regNumberController = TextEditingController();

  bool get isEditing => widget.companyId != null;
  int get _editId => int.parse(widget.companyId!);

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _vatNumberController.dispose();
    _regNumberController.dispose();
    super.dispose();
  }

  void _populateFrom(dynamic company) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = company.name;
    _contactPersonController.text = company.contactPerson ?? '';
    _addressController.text = company.address;
    _phoneController.text = company.phone ?? '';
    _vatNumberController.text = company.vatNumber ?? '';
    _regNumberController.text = company.regNumber ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'contact_person': _contactPersonController.text.trim(),
      'address': _addressController.text.trim(),
    };

    void addIfNotEmpty(String key, String value) {
      if (value.isNotEmpty) payload[key] = value;
    }

    addIfNotEmpty('phone', _phoneController.text.trim());
    addIfNotEmpty('vat_number', _vatNumberController.text.trim());
    addIfNotEmpty('reg_number', _regNumberController.text.trim());

    try {
      final repo = ref.read(companyRepositoryProvider);
      if (isEditing) {
        await repo.update(_editId, payload);
      } else {
        await repo.create(payload);
      }
      ref.invalidate(companyListProvider);
      if (mounted) {
        HapticFeedback.mediumImpact();
        showSuccessSnackbar(
            context, isEditing ? 'Company updated' : 'Company created');
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
    if (isEditing && !_initialized) {
      final companyAsync = ref.watch(companyDetailProvider(_editId));
      return companyAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Company')),
          body: const LoadingIndicator(),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Company')),
          body: ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(companyDetailProvider(_editId)),
          ),
        ),
        data: (company) {
          _populateFrom(company);
          return _buildForm();
        },
      );
    }
    return _buildForm();
  }

  Widget _buildForm() {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Company' : 'New Company'),
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
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Company Name'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactPersonController,
              decoration: const InputDecoration(labelText: 'Contact Person'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              textInputAction: TextInputAction.next,
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vatNumberController,
              decoration: const InputDecoration(labelText: 'VAT Number'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regNumberController,
              decoration:
                  const InputDecoration(labelText: 'Registration Number'),
            ),
          ],
        ),
      ),
    );
  }
}
