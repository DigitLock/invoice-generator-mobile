import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/server_config.dart';
import '../providers/app_mode_provider.dart';
import '../providers/server_config_provider.dart';
import '../widgets/snackbar_helper.dart';

const _presetConfig = ServerConfig.preset;

class ServerSettingsScreen extends ConsumerStatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  ConsumerState<ServerSettingsScreen> createState() =>
      _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends ConsumerState<ServerSettingsScreen> {
  bool _showAddForm = false;
  bool _isTesting = false;
  bool? _testResult;

  final _nameController = TextEditingController();
  final _apiUrlController = TextEditingController();
  final _authUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
    setState(() => _showAddForm = false);
  }

  Future<void> _testConnection() async {
    final url = _apiUrlController.text.trim();
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

    final server = ServerConfig.create(
      name: _nameController.text.trim(),
      apiUrl: _apiUrlController.text.trim(),
      authUrl: _authUrlController.text.trim(),
    );

    await ref.read(serverConfigProvider.notifier).addServer(server);
    if (mounted) {
      showSuccessSnackbar(context, 'Server added');
      _resetForm();
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

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(serverConfigProvider);
    final theme = Theme.of(context);
    final appMode = ref.watch(appModeProvider);
    final showConnectButton = appMode != AppMode.online;

    return Scaffold(
      appBar: AppBar(title: const Text('Server Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Server list
          if (configState.servers.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No servers configured')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.tonal(
                onPressed: () async {
                  await ref
                      .read(serverConfigProvider.notifier)
                      .addServer(_presetConfig);
                  await ref
                      .read(serverConfigProvider.notifier)
                      .setActive(_presetConfig.id);
                },
                child: const Text('Add DigitLock Cloud'),
              ),
            ),
          ] else
            ...configState.servers.map((server) => _ServerTile(
                  server: server,
                  isActive: server.id == configState.activeServerId,
                  onSelect: () => ref
                      .read(serverConfigProvider.notifier)
                      .setActive(server.id),
                  onDelete: () => ref
                      .read(serverConfigProvider.notifier)
                      .removeServer(server.id),
                )),

          const Divider(height: 32),

          // Add server
          if (!_showAddForm)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showAddForm = true),
                icon: const Icon(Icons.add),
                label: const Text('Add Server'),
              ),
            )
          else
            _buildAddForm(theme),

          // Connect button (when coming from welcome)
          if (showConnectButton && configState.activeServer != null) ...[
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: _connectAndGo,
                child: const Text('Connect & Continue'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Server',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
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
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
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
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
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
                      : const Text('Test Connection'),
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
    required this.onDelete,
  });

  final ServerConfig server;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(server.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
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
        secondary: Icon(
          Icons.cloud_done,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}
