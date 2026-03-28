import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'repositories/company_repository.dart';
import 'remote/remote_company_repository.dart';

export 'repositories/company_repository.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return RemoteCompanyRepository(dio: ref.watch(dioProvider));
});
