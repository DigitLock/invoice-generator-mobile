import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_mode_provider.dart';
import '../services/database_service.dart';
import 'api_client.dart';
import 'repositories/company_repository.dart';
import 'remote/remote_company_repository.dart';
import 'local/local_company_repository.dart';

export 'repositories/company_repository.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final mode = ref.watch(appModeProvider).mode;
  if (mode == AppMode.offline) {
    final dbAsync = ref.watch(databaseServiceProvider);
    return dbAsync.whenOrNull(data: (db) => LocalCompanyRepository(db: db))
        ?? _ThrowingCompanyRepository();
  }
  return RemoteCompanyRepository(dio: ref.watch(dioProvider));
});

class _ThrowingCompanyRepository implements CompanyRepository {
  @override
  dynamic noSuchMethod(Invocation i) => throw StateError('Database not ready');
}
