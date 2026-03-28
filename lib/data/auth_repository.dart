import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth.dart';
import 'api_client.dart';

const _userKey = 'user_data';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authDio: ref.watch(authDioProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  final Dio _authDio;
  final FlutterSecureStorage _storage;

  AuthRepository({required Dio authDio, required FlutterSecureStorage storage})
      : _authDio = authDio,
        _storage = storage;

  Future<LoginResponse> login(String email, String password) async {
    final response = await _authDio.post(
      '/auth/login',
      data: LoginRequest(email: email, password: password).toJson(),
    );

    final data = response.data as Map<String, dynamic>;

    late final LoginResponse loginResponse;
    if (data.containsKey('success') && data.containsKey('data')) {
      final wrapped = ApiSuccessResponse.fromJson(data, LoginResponse.fromJson);
      loginResponse = wrapped.data;
    } else if (data.containsKey('token')) {
      loginResponse = LoginResponse.fromJson(data);
    } else {
      throw Exception('Unknown login response format');
    }

    await _storage.write(key: tokenKey, value: loginResponse.token);
    await _storage.write(
      key: _userKey,
      value: '${loginResponse.user.id}|${loginResponse.user.email}|${loginResponse.user.name}|${loginResponse.user.familyId}',
    );

    return loginResponse;
  }

  Future<void> logout() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<String?> getStoredToken() async {
    return _storage.read(key: tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getStoredToken();
    return token != null;
  }

  Future<User?> getStoredUser() async {
    final data = await _storage.read(key: _userKey);
    if (data == null) return null;
    final parts = data.split('|');
    if (parts.length != 4) return null;
    return User(
      id: parts[0],
      email: parts[1],
      name: parts[2],
      familyId: parts[3],
    );
  }
}
