import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/active_disaster.dart';

class DisasterApi {
  DisasterApi({
    String baseUrl = const String.fromEnvironment('API_BASE_URL'),
    http.Client? client,
  }) : _baseUrl = baseUrl,
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<ActiveDisaster?> active() async {
    final base = Uri.tryParse(_baseUrl);
    if (base == null ||
        !base.hasAuthority ||
        (base.scheme != 'https' && base.scheme != 'http')) {
      throw StateError('API_BASE_URL is not configured');
    }
    // OpenAPI: このGETは認証不要。管理者の災害開始APIは呼び出さない。
    final response = await _client
        .get(
          base.resolve('/api/v1/disasters/active'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Disaster API returned ${response.statusCode}',
      );
    }
    return ActiveDisaster.fromResponse(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );
  }

  void close() => _client.close();
}
