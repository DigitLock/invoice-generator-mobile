import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'repositories/bank_account_repository.dart';
import 'remote/remote_bank_account_repository.dart';

export 'repositories/bank_account_repository.dart';

final bankAccountRepositoryProvider = Provider<BankAccountRepository>((ref) {
  return RemoteBankAccountRepository(dio: ref.watch(dioProvider));
});
