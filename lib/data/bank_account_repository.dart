import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_mode_provider.dart';
import 'api_client.dart';
import 'repositories/bank_account_repository.dart';
import 'remote/remote_bank_account_repository.dart';
import 'local/stub_bank_account_repository.dart';

export 'repositories/bank_account_repository.dart';

final bankAccountRepositoryProvider = Provider<BankAccountRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.offline) {
    return StubBankAccountRepository();
  }
  return RemoteBankAccountRepository(dio: ref.watch(dioProvider));
});
