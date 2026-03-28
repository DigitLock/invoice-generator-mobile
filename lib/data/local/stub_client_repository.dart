import '../../models/client.dart';
import '../repositories/client_repository.dart';

/// Temporary stub for offline mode. Returns empty data.
/// Will be replaced by SQLite implementation in Stage 4.10.
class StubClientRepository implements ClientRepository {
  @override
  Future<List<Client>> list({String? status}) async => [];

  @override
  Future<Client> getById(int id) =>
      throw UnimplementedError('Offline client detail not yet implemented');

  @override
  Future<Client> create(Map<String, dynamic> data) =>
      throw UnimplementedError('Offline client create not yet implemented');

  @override
  Future<Client> update(int id, Map<String, dynamic> data) =>
      throw UnimplementedError('Offline client update not yet implemented');
}
