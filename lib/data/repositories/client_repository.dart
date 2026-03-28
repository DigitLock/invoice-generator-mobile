import '../../models/client.dart';

abstract class ClientRepository {
  Future<List<Client>> list({String? status});
  Future<Client> getById(int id);
  Future<Client> create(Map<String, dynamic> data);
  Future<Client> update(int id, Map<String, dynamic> data);
}
