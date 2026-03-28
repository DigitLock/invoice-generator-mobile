class ServerConfig {
  final String id;
  final String name;
  final String apiUrl;
  final String authUrl;

  const ServerConfig({
    required this.id,
    required this.name,
    required this.apiUrl,
    required this.authUrl,
  });

  factory ServerConfig.create({
    required String name,
    required String apiUrl,
    required String authUrl,
  }) {
    return ServerConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      apiUrl: apiUrl,
      authUrl: authUrl,
    );
  }

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      apiUrl: json['api_url'] as String,
      authUrl: json['auth_url'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'api_url': apiUrl,
        'auth_url': authUrl,
      };

  static const preset = ServerConfig(
    id: 'preset_digitlock',
    name: 'DigitLock Cloud',
    apiUrl: 'https://invoice.digitlock.systems',
    authUrl: 'https://api-demo-expensetracker.digitlock.systems',
  );
}
