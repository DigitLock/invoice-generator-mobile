import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/server_config_provider.dart';

const _fallbackApiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8081');
const _fallbackAuthUrl = String.fromEnvironment('AUTH_URL', defaultValue: 'http://localhost:8080');
const tokenKey = 'jwt_token';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Resolves the active API URL from server config, falling back to dart-define.
String _resolveApiUrl(Ref ref) {
  final active = ref.watch(serverConfigProvider).activeServer;
  return active?.apiUrl ?? _fallbackApiUrl;
}

String _resolveAuthUrl(Ref ref) {
  final active = ref.watch(serverConfigProvider).activeServer;
  return active?.authUrl ?? _fallbackAuthUrl;
}

/// Main Dio instance — points to Invoice Generator API, includes JWT interceptor.
/// Rebuilds when the active server changes.
final dioProvider = Provider<Dio>((ref) {
  final apiUrl = _resolveApiUrl(ref);
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: '$apiUrl/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(storage: storage));

  return dio;
});

/// Auth Dio instance — points to Expense Tracker API, no JWT interceptor.
/// Rebuilds when the active server changes.
final authDioProvider = Provider<Dio>((ref) {
  final authUrl = _resolveAuthUrl(ref);

  return Dio(BaseOptions(
    baseUrl: '$authUrl/api/v1',
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
        final data = err.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('error')) {
          return data['error'] as String;
        }
        return 'Something went wrong. Please try again.';
    }
  }
}
