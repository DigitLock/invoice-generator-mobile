import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_mode_provider.dart';
import '../providers/server_config_provider.dart';
import '../widgets/snackbar_helper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider).mode;
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

          // Debug section
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Debug',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined,
                color: theme.colorScheme.error),
            title: const Text('Clear Server Config'),
            subtitle: const Text('Remove all saved servers'),
            onTap: () => _confirmClearServers(context, ref),
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(appModeProvider.notifier).clear();
              if (context.mounted) context.go('/welcome');
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }

  void _confirmClearServers(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Server Config'),
        content: const Text(
          'Remove all saved servers? The app will use dart-define fallback URLs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(serverConfigProvider.notifier).clearAll();
              showSuccessSnackbar(context, 'Server config cleared');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
