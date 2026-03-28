import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);
    final theme = Theme.of(context);
    final isOffline = appMode == AppMode.offline;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Mode section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'App Mode',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              isOffline ? Icons.cloud_off : Icons.cloud_done,
              color: theme.colorScheme.primary,
            ),
            title: Text(isOffline ? 'Offline Mode' : 'Online Mode'),
            subtitle: Text(
              isOffline
                  ? 'Data stored locally on device'
                  : 'Connected to server',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => _confirmSwitchMode(context, ref),
              child: Text(
                isOffline ? 'Switch to Online' : 'Switch to Offline',
              ),
            ),
          ),

          // Server section (online only)
          if (!isOffline) ...[
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Server',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: const Text('Server Settings'),
              subtitle: const Text('Configure server connection'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/server-settings'),
            ),
          ],

          // About section
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'About',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Invoice Generator'),
            subtitle: Text('v1.0.0'),
          ),
        ],
      ),
    );
  }

  void _confirmSwitchMode(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch Mode'),
        content: const Text(
          'This will take you back to the welcome screen. Your existing data will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(appModeProvider.notifier).clear();
              context.go('/welcome');
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}
