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
    final url = '${_authDio.options.baseUrl}/auth/login';
    print('[AuthRepository] POST $url');
    print('[AuthRepository] Request body: {email: $email, password: ***}');

    try {
      final response = await _authDio.post(
        '/auth/login',
        data: LoginRequest(email: email, password: password).toJson(),
      );

      print('[AuthRepository] Response status: ${response.statusCode}');
      print('[AuthRepository] Response data: ${response.data}');

      // Expense Tracker wraps response: {"success": true, "data": {...}}
      final data = response.data as Map<String, dynamic>;

      late final LoginResponse loginResponse;
      if (data.containsKey('success') && data.containsKey('data')) {
        // Expense Tracker format: {"success": true, "data": {token, user, expires_in}}
        print('[AuthRepository] Parsing Expense Tracker wrapped format');
        final wrapped = ApiSuccessResponse.fromJson(data, LoginResponse.fromJson);
        loginResponse = wrapped.data;
      } else if (data.containsKey('token')) {
        // Direct format: {token, user, expires_at}
        print('[AuthRepository] Parsing direct format');
        loginResponse = LoginResponse.fromJson(data);
      } else {
        print('[AuthRepository] Unknown response format: $data');
        throw Exception('Unknown login response format');
      }

      print('[AuthRepository] Storage key: "$tokenKey", storage instance: ${identityHashCode(_storage)}');
      await _storage.write(key: tokenKey, value: loginResponse.token);
      print('[AuthRepository] Token saved (${loginResponse.token.length} chars): ${loginResponse.token.substring(0, 20)}...');

      // Verify token was actually written back
      final verify = await _storage.read(key: tokenKey);
      print('[AuthRepository] Verify read-back: ${verify != null ? 'OK (${verify.length} chars, ${verify.substring(0, 20)}...)' : 'FAILED — NULL!'}');
      print('[AuthRepository] Tokens match: ${verify == loginResponse.token}');

      await _storage.write(
        key: _userKey,
        value: '${loginResponse.user.id}|${loginResponse.user.email}|${loginResponse.user.name}|${loginResponse.user.familyId}',
      );
      print('[AuthRepository] User data saved');

      return loginResponse;
    } on DioException catch (e) {
      print('[AuthRepository] DioException: ${e.type}');
      print('[AuthRepository] Status: ${e.response?.statusCode}');
      print('[AuthRepository] Response data: ${e.response?.data}');
      print('[AuthRepository] Message: ${e.message}');
      rethrow;
    } catch (e) {
      print('[AuthRepository] Unexpected error: $e');
      rethrow;
    }
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
