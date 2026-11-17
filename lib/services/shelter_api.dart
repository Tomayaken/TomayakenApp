import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/shelter.dart';

class ShelterApi {
  ShelterApi({
    String baseUrl = const String.fromEnvironment('API_BASE_URL'),
    http.Client? client,
  }) : _baseUrl = baseUrl,
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<List<Shelter>> nearby({
    required double latitude,
    required double longitude,
  }) async {
    if (!latitude.isFinite ||
        latitude.abs() > 90 ||
        !longitude.isFinite ||
        longitude.abs() > 180) {
      throw ArgumentError('Invalid coordinates');
    }
    final base = Uri.tryParse(_baseUrl);
    if (base == null ||
        !base.hasAuthority ||
        (base.scheme != 'https' && base.scheme != 'http')) {
      throw StateError('API_BASE_URL is not configured');
    }
    // OpenAPI: 緯度・経度と最大20件を指定する（このGETは認証不要）。
    final uri = base
        .resolve('/api/v1/shelters/nearby')
        .replace(
          queryParameters: {
            'latitude': latitude.toString(),
            'longitude': longitude.toString(),
            'limit': '20',
          },
        );
    final response = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw http.ClientException('Shelter API returned ${response.statusCode}');
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is! Map<String, dynamic> || json['items'] is! List) {
      throw const FormatException('Expected shelter items response');
    }
    final shelters = (json['items'] as List).map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Expected a shelter object');
      }
      return Shelter.fromJson(item);
    }).toList();
    // APIの返却順にかかわらず直線距離の昇順で表示する。満員も除外しない。
    shelters.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return shelters;
  }

  void close() => _client.close();
}
