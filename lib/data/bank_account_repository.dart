import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_mode_provider.dart';
import '../services/database_service.dart';
import 'api_client.dart';
import 'repositories/bank_account_repository.dart';
import 'remote/remote_bank_account_repository.dart';
import 'local/local_bank_account_repository.dart';

export 'repositories/bank_account_repository.dart';

final bankAccountRepositoryProvider = Provider<BankAccountRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.offline) {
    final dbAsync = ref.watch(databaseServiceProvider);
    return dbAsync.whenOrNull(data: (db) => LocalBankAccountRepository(db: db))
        ?? _ThrowingBankAccountRepository();
  }
  return RemoteBankAccountRepository(dio: ref.watch(dioProvider));
});

class _ThrowingBankAccountRepository implements BankAccountRepository {
  @override
  dynamic noSuchMethod(Invocation i) => throw StateError('Database not ready');
}
