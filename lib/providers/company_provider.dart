import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/company_repository.dart';
import '../models/company.dart';

final companyListProvider = FutureProvider<List<Company>>((ref) {
  final repository = ref.watch(companyRepositoryProvider);
  return repository.list();
});

final companyDetailProvider = FutureProvider.family<Company, int>((ref, id) {
  final repository = ref.watch(companyRepositoryProvider);
  return repository.getById(id);
});
