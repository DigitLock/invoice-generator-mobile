import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8081');
const _authUrl = String.fromEnvironment('AUTH_URL', defaultValue: 'http://localhost:8080');
const tokenKey = 'jwt_token';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Main Dio instance — points to Invoice Generator API, includes JWT interceptor.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: '$_apiUrl/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(storage: storage));

  return dio;
});

/// Auth Dio instance — points to Expense Tracker API, no JWT interceptor.
final authDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: '$_authUrl/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
});

/// Uses QueuedInterceptor so async storage read completes before request is sent.
class AuthInterceptor extends QueuedInterceptor {
  final FlutterSecureStorage storage;

  AuthInterceptor({required this.storage});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    print('[AuthInterceptor] --- Request ---');
    print('[AuthInterceptor] URL: ${options.uri}');
    print('[AuthInterceptor] Storage key: "$tokenKey", storage instance: ${identityHashCode(storage)}');

    final token = await storage.read(key: tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('[AuthInterceptor] Token attached (${token.length} chars): ${token.substring(0, token.length < 20 ? token.length : 20)}...');

      // Decode JWT payload to inspect claims types
      _logJwtClaims(token);
    } else {
      print('[AuthInterceptor] WARNING: No token in storage! token=$token');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    print('[AuthInterceptor] --- Error ---');
    print('[AuthInterceptor] ${err.response?.statusCode} for ${err.requestOptions.uri}');
    print('[AuthInterceptor] Response body: ${err.response?.data}');
    if (err.response?.statusCode == 401) {
      print('[AuthInterceptor] Clearing token from storage');
      await storage.delete(key: tokenKey);
    }
    handler.next(err);
  }

  void _logJwtClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('[AuthInterceptor] JWT: invalid format (${parts.length} parts)');
        return;
      }
      var payload = parts[1];
      payload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(payload));
      print('[AuthInterceptor] JWT claims: $decoded');
    } catch (e) {
      print('[AuthInterceptor] JWT decode error: $e');
    }
  }
}
