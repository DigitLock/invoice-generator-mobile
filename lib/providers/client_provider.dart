import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/client_repository.dart';
import '../models/client.dart';

final clientListProvider =
    FutureProvider.family<List<Client>, String?>((ref, status) {
  final repository = ref.watch(clientRepositoryProvider);
  return repository.list(status: status);
});

final clientDetailProvider = FutureProvider.family<Client, int>((ref, id) {
  final repository = ref.watch(clientRepositoryProvider);
  return repository.getById(id);
});
