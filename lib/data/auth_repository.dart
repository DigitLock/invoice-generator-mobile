import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth.dart';
import 'api_client.dart';

const _tokenKey = 'jwt_token';
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
    developer.log('[AuthRepository] POST $url');
    developer.log('[AuthRepository] Request body: {email: $email, password: ***}');

    try {
      final response = await _authDio.post(
        '/auth/login',
        data: LoginRequest(email: email, password: password).toJson(),
      );

      developer.log('[AuthRepository] Response status: ${response.statusCode}');
      developer.log('[AuthRepository] Response data: ${response.data}');

      // Expense Tracker wraps response: {"success": true, "data": {...}}
      final data = response.data as Map<String, dynamic>;

      late final LoginResponse loginResponse;
      if (data.containsKey('success') && data.containsKey('data')) {
        // Expense Tracker format: {"success": true, "data": {token, user, expires_in}}
        developer.log('[AuthRepository] Parsing Expense Tracker wrapped format');
        final wrapped = ApiSuccessResponse.fromJson(data, LoginResponse.fromJson);
        loginResponse = wrapped.data;
      } else if (data.containsKey('token')) {
        // Direct format: {token, user, expires_at}
        developer.log('[AuthRepository] Parsing direct format');
        loginResponse = LoginResponse.fromJson(data);
      } else {
        developer.log('[AuthRepository] Unknown response format: $data');
        throw Exception('Unknown login response format');
      }

      await _storage.write(key: _tokenKey, value: loginResponse.token);
      await _storage.write(
        key: _userKey,
        value: '${loginResponse.user.id}|${loginResponse.user.email}|${loginResponse.user.name}|${loginResponse.user.familyId}',
      );

      return loginResponse;
    } on DioException catch (e) {
      developer.log('[AuthRepository] DioException: ${e.type}');
      developer.log('[AuthRepository] Status: ${e.response?.statusCode}');
      developer.log('[AuthRepository] Response data: ${e.response?.data}');
      developer.log('[AuthRepository] Message: ${e.message}');
      rethrow;
    } catch (e) {
      developer.log('[AuthRepository] Unexpected error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<String?> getStoredToken() async {
    return _storage.read(key: _tokenKey);
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
