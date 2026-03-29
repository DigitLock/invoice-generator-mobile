import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/server_config.dart';
import '../providers/app_mode_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/server_config_provider.dart';
import '../widgets/snackbar_helper.dart';

String _cleanUrl(String url) {
  var cleaned = url.trim();
  while (cleaned.endsWith('/')) {
    cleaned = cleaned.substring(0, cleaned.length - 1);
  }
  return cleaned;
}

String? _validateUrl(String? value) {
  if (value == null || value.trim().isEmpty) return 'Required';
  final cleaned = _cleanUrl(value);
  if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
    return 'Must start with http:// or https://';
  }
  return null;
}

class ServerSettingsScreen extends ConsumerStatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  ConsumerState<ServerSettingsScreen> createState() =>
      _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends ConsumerState<ServerSettingsScreen> {
  bool _showForm = false;
  bool _isTesting = false;
  bool? _testResult;
  String? _editingServerId;

  final _nameController = TextEditingController();
  final _apiUrlController = TextEditingController();
  final _authUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isEditMode => _editingServerId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _apiUrlController.dispose();
    _authUrlController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _apiUrlController.clear();
    _authUrlController.clear();
    _testResult = null;
    _editingServerId = null;
    setState(() => _showForm = false);
  }

  void _startEdit(ServerConfig server) {
    _editingServerId = server.id;
    _nameController.text = server.name;
    _apiUrlController.text = server.apiUrl;
    _authUrlController.text = server.authUrl;
    _testResult = null;
    setState(() => _showForm = true);
  }

  void _startAdd() {
    _editingServerId = null;
    _nameController.clear();
    _apiUrlController.clear();
    _authUrlController.clear();
    _testResult = null;
    setState(() => _showForm = true);
  }

  Future<void> _testConnection() async {
    final url = _cleanUrl(_apiUrlController.text);
    if (url.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await dio.get('$url/health');
      setState(() => _testResult = response.statusCode == 200);
    } catch (_) {
      setState(() => _testResult = false);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _saveServer() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(serverConfigProvider.notifier);

    if (_isEditMode) {
      // Update: remove old, add new with same id
      await notifier.removeServer(_editingServerId!);
      final updated = ServerConfig(
        id: _editingServerId!,
        name: _nameController.text.trim(),
        apiUrl: _cleanUrl(_apiUrlController.text),
        authUrl: _cleanUrl(_authUrlController.text),
      );
      await notifier.addServer(updated);
      // If this was the active server, re-select and logout
      final configState = ref.read(serverConfigProvider);
      if (configState.activeServerId == _editingServerId) {
        await notifier.setActive(_editingServerId!);
        _logoutIfOnline();
      }
      if (mounted) showSuccessSnackbar(context, 'Server updated');
    } else {
      final server = ServerConfig.create(
        name: _nameController.text.trim(),
        apiUrl: _cleanUrl(_apiUrlController.text),
        authUrl: _cleanUrl(_authUrlController.text),
      );
      await notifier.addServer(server);
      if (mounted) showSuccessSnackbar(context, 'Server added');
    }

    if (mounted) _resetForm();
  }

  Future<void> _addPreset() async {
    final notifier = ref.read(serverConfigProvider.notifier);
    await notifier.addServer(ServerConfig.preset);
    await notifier.setActive(ServerConfig.preset.id);
    _logoutIfOnline();
  }

  void _selectServer(String id) {
    final currentActive = ref.read(serverConfigProvider).activeServerId;
    if (currentActive == id) return;
    ref.read(serverConfigProvider.notifier).setActive(id);
    _logoutIfOnline();
  }

  void _logoutIfOnline() {
    final appMode = ref.read(appModeProvider).mode;
    if (appMode == AppMode.online) {
      ref.read(authProvider.notifier).logout();
    }
  }

  void _connectAndGo() {
    final active = ref.read(serverConfigProvider).activeServer;
    if (active == null) {
      showErrorSnackbar(context, 'Please add and select a server first');
      return;
    }
    ref.read(appModeProvider.notifier).setMode(AppMode.online);
    context.go('/');
  }

  void _confirmDelete(BuildContext context, ServerConfig server) {
    final configState = ref.read(serverConfigProvider);
    if (server.id == configState.activeServerId) {
      showErrorSnackbar(context, 'Deselect server first');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Server'),
        content: Text('Remove "${server.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(serverConfigProvider.notifier).removeServer(server.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(serverConfigProvider);
    final theme = Theme.of(context);
    final appMode = ref.watch(appModeProvider).mode;
    final showContinue = appMode != AppMode.online;
    final hasPreset =
        configState.servers.any((s) => s.id == ServerConfig.preset.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Server Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Suggested preset (when not yet added)
          if (!hasPreset) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Suggested',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(Icons.cloud_outlined,
                    color: theme.colorScheme.primary),
                title: Text(ServerConfig.preset.name),
                subtitle: Text(ServerConfig.preset.apiUrl,
                    style: theme.textTheme.bodySmall),
                trailing: FilledButton.tonal(
                  onPressed: _addPreset,
                  child: const Text('Add'),
                ),
              ),
            ),
          ],

          // Saved servers
          if (configState.servers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Servers',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            ...configState.servers.map((server) => _ServerTile(
                  server: server,
                  isActive: server.id == configState.activeServerId,
                  onSelect: () => _selectServer(server.id),
                  onEdit: () => _startEdit(server),
                  onDelete: () => _confirmDelete(context, server),
                )),
          ],

          if (configState.servers.isEmpty && hasPreset)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No servers configured')),
            ),

          const Divider(height: 32),

          // Add/Edit form
          if (!_showForm)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _startAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Custom Server'),
              ),
            )
          else
            _buildForm(theme),

          // Continue to Login (only from welcome flow)
          if (showContinue && configState.activeServer != null) ...[
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: _connectAndGo,
                child: const Text('Continue to Login'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditMode ? 'Edit Server' : 'Add Custom Server',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                labelText: 'API URL',
                hintText: 'https://invoice.example.com',
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              validator: _validateUrl,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _authUrlController,
              decoration: const InputDecoration(
                labelText: 'Auth URL',
                hintText: 'https://auth.example.com',
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              validator: _validateUrl,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _isTesting ? null : _testConnection,
                  child: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test'),
                ),
                const SizedBox(width: 8),
                if (_testResult != null)
                  Icon(
                    _testResult! ? Icons.check_circle : Icons.cancel,
                    color: _testResult! ? Colors.green : Colors.red,
                    size: 20,
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _resetForm,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saveServer,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  const _ServerTile({
    required this.server,
    required this.isActive,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final ServerConfig server;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(server.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: RadioListTile<bool>(
        value: true,
        groupValue: isActive,
        onChanged: (_) => onSelect(),
        title: Text(server.name),
        subtitle: Text(
          server.apiUrl,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        secondary: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: onEdit,
        ),
      ),
    );
  }
}
