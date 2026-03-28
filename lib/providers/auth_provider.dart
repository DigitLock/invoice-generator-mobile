import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../models/auth.dart';
import 'invoice_provider.dart';
import 'company_provider.dart';
import 'client_provider.dart';
import 'bank_account_provider.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(const AuthState()) {
    _checkStoredAuth();
  }

  Future<void> _checkStoredAuth() async {
    try {
      final isAuth = await _repository.isAuthenticated();
      if (!mounted) return;
      if (isAuth) {
        final user = await _repository.getStoredUser();
        if (!mounted) return;
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      if (!mounted) return;
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.login(email, password);

      // Invalidate all data providers so they refetch with valid token
      _invalidateDataProviders();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        error: message,
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _invalidateDataProviders();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _invalidateDataProviders() {
    _ref.invalidate(invoiceListProvider);
    _ref.invalidate(invoiceDetailProvider);
    _ref.invalidate(companyListProvider);
    _ref.invalidate(companyDetailProvider);
    _ref.invalidate(clientListProvider);
    _ref.invalidate(clientDetailProvider);
    _ref.invalidate(bankAccountListProvider);
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      // Expense Tracker format: {"success": false, "error": {"message": "..."}}
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return error['message'] as String? ?? 'Login failed';
      }
      if (error is String) return error;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});
