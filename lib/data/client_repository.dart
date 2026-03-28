import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'repositories/client_repository.dart';
import 'remote/remote_client_repository.dart';

export 'repositories/client_repository.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return RemoteClientRepository(dio: ref.watch(dioProvider));
});
