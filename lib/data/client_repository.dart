import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_mode_provider.dart';
import '../services/database_service.dart';
import 'api_client.dart';
import 'repositories/client_repository.dart';
import 'remote/remote_client_repository.dart';
import 'local/local_client_repository.dart';

export 'repositories/client_repository.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.offline) {
    final dbAsync = ref.watch(databaseServiceProvider);
    return dbAsync.whenOrNull(data: (db) => LocalClientRepository(db: db))
        ?? _ThrowingClientRepository();
  }
  return RemoteClientRepository(dio: ref.watch(dioProvider));
});

class _ThrowingClientRepository implements ClientRepository {
  @override
  dynamic noSuchMethod(Invocation i) => throw StateError('Database not ready');
}
