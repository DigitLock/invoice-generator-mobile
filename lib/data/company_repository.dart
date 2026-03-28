import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_mode_provider.dart';
import 'api_client.dart';
import 'repositories/company_repository.dart';
import 'remote/remote_company_repository.dart';
import 'local/stub_company_repository.dart';

export 'repositories/company_repository.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.offline) {
    return StubCompanyRepository();
  }
  return RemoteCompanyRepository(dio: ref.watch(dioProvider));
});
