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
    final token = await storage.read(key: tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await storage.delete(key: tokenKey);
    }

    final message = _userFriendlyMessage(err);
    handler.next(err.copyWith(message: message));
  }

  String _userFriendlyMessage(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your internet.';
    }
    if (err.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    switch (err.response?.statusCode) {
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        // Try to extract error message from API response
        final data = err.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('error')) {
          return data['error'] as String;
        }
        return 'Something went wrong. Please try again.';
    }
  }
}
