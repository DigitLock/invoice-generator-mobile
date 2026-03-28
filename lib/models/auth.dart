class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// Wrapper for Expense Tracker API response: {"success": true, "data": {...}}
class ApiSuccessResponse<T> {
  final bool success;
  final T data;

  const ApiSuccessResponse({required this.success, required this.data});

  factory ApiSuccessResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiSuccessResponse(
      success: json['success'] as bool,
      data: fromJsonT(json['data'] as Map<String, dynamic>),
    );
  }
}

class LoginResponse {
  final String token;
  final User user;

  const LoginResponse({
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final String familyId;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.familyId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'] as String,
      name: json['name'] as String,
      familyId: json['family_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'family_id': familyId,
      };
}
