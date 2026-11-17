import 'dart:convert';

import 'package:http/http.dart' as http;

class UserRegistrationService {
  UserRegistrationService({
    http.Client? client,
    Uri? baseUri,
  }) : _client = client ?? http.Client(),
       _baseUri =
           baseUri ??
           Uri.parse(
             const String.fromEnvironment(
               'API_BASE_URL',
               defaultValue: 'http://localhost:8080',
             ),
           );

  final http.Client _client;
  final Uri _baseUri;

  Future<void> registerUser({
    required String userId,
    required String name,
  }) async {
    final endpoint = _baseUri.replace(
      path: '${_baseUri.path.replaceAll(RegExp(r'/$'), '')}/api/v1/users/$userId',
    );

    final response = await _client.put(
      endpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) return;

    String? errorCode;
    String? errorMessage;
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        errorCode = body['code'] as String?;
        errorMessage = body['message'] as String?;
      }
    } on FormatException {
      // Fall back to the HTTP status when the server response is not JSON.
    }
    throw UserRegistrationException(
      code: errorCode,
      message: errorMessage ?? '利用者登録に失敗しました。',
      statusCode: response.statusCode,
    );
  }
}

class UserRegistrationException implements Exception {
  const UserRegistrationException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  final String? code;
  final String message;
  final int statusCode;

  @override
  String toString() => code == null ? message : '$code: $message';
}
