import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bank_account_repository.dart';
import '../models/bank_account.dart';

final bankAccountListProvider =
    FutureProvider.family<List<BankAccount>, int>((ref, companyId) {
  final repository = ref.watch(bankAccountRepositoryProvider);
  return repository.listByCompany(companyId);
});
