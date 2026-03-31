import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/client_repository.dart';
import '../models/client.dart';
import '../providers/client_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import '../widgets/snackbar_helper.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  const ClientFormScreen({super.key, this.clientId});

  final String? clientId;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Edit mode: loading state for initial fetch
  bool _isFetchingClient = false;
  String? _fetchError;

  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _contractRefController = TextEditingController();
  final _contractNotesController = TextEditingController();
  String _status = 'active';

  bool get isEditing => widget.clientId != null;
  int get _editId => int.parse(widget.clientId!);

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadClient();
    }
  }

  Future<void> _loadClient() async {
    setState(() {
      _isFetchingClient = true;
      _fetchError = null;
    });

    try {
      final client =
          await ref.read(clientRepositoryProvider).getById(_editId);
      if (!mounted) return;
      _populateFromClient(client);
      setState(() => _isFetchingClient = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFetchingClient = false;
        _fetchError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _vatNumberController.dispose();
    _regNumberController.dispose();
    _contractRefController.dispose();
    _contractNotesController.dispose();
    super.dispose();
  }

  void _populateFromClient(Client client) {
    _nameController.text = client.name;
    _contactPersonController.text = client.contactPerson ?? '';
    _emailController.text = client.email ?? '';
    _addressController.text = client.address;
    _vatNumberController.text = client.vatNumber ?? '';
    _regNumberController.text = client.regNumber ?? '';
    _contractRefController.text = client.contractReference ?? '';
    _contractNotesController.text = client.contractNotes ?? '';
    _status = client.status;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'status': _status,
    };

    void addIfNotEmpty(String key, String value) {
      if (value.isNotEmpty) payload[key] = value;
    }

    addIfNotEmpty('contact_person', _contactPersonController.text.trim());
    addIfNotEmpty('email', _emailController.text.trim());
    addIfNotEmpty('vat_number', _vatNumberController.text.trim());
    addIfNotEmpty('reg_number', _regNumberController.text.trim());
    addIfNotEmpty('contract_reference', _contractRefController.text.trim());
    addIfNotEmpty('contract_notes', _contractNotesController.text.trim());

    try {
      final repo = ref.read(clientRepositoryProvider);
      if (isEditing) {
        await repo.update(_editId, payload);
      } else {
        await repo.create(payload);
      }
      ref.invalidate(clientListProvider);
      if (mounted) {
        HapticFeedback.mediumImpact();
        showSuccessSnackbar(
            context, isEditing ? 'Client updated' : 'Client created');
        context.pop();
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
    if (_isFetchingClient) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Client')),
        body: const LoadingIndicator(),
      );
    }

    if (_fetchError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Client')),
        body: ErrorView(
          message: _fetchError!,
          onRetry: _loadClient,
        ),
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client' : 'New Client'),
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
              decoration: const InputDecoration(labelText: 'Name'),
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
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
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
              controller: _vatNumberController,
              decoration: const InputDecoration(labelText: 'VAT Number'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regNumberController,
              decoration:
                  const InputDecoration(labelText: 'Registration Number'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contractRefController,
              decoration:
                  const InputDecoration(labelText: 'Contract Reference'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contractNotesController,
              decoration: const InputDecoration(
                labelText: 'Contract Notes',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Status'),
              subtitle: Text(_status == 'active' ? 'Active' : 'Inactive'),
              value: _status == 'active',
              onChanged: (v) =>
                  setState(() => _status = v ? 'active' : 'inactive'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
