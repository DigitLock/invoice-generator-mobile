import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8081');
const _authUrl = String.fromEnvironment('AUTH_URL', defaultValue: 'http://localhost:8080');
const _tokenKey = 'jwt_token';

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

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;

  AuthInterceptor({required this.storage});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: _tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await storage.delete(key: _tokenKey);
    }
    handler.next(err);
  }
}
