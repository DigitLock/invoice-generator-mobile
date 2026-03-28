import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_mode_provider.dart';
import 'api_client.dart';
import 'repositories/client_repository.dart';
import 'remote/remote_client_repository.dart';
import 'local/stub_client_repository.dart';

export 'repositories/client_repository.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.offline) {
    return StubClientRepository();
  }
  return RemoteClientRepository(dio: ref.watch(dioProvider));
});
