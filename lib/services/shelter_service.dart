import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/shelter.dart';

class ShelterService {
  ShelterService({
    http.Client? client,
    Uri? baseUri,
  }) : _client = client ?? http.Client(),
       _baseUri = baseUri ??
           Uri.parse(
             const String.fromEnvironment(
               'API_BASE_URL',
               defaultValue: 'http://localhost:8080',
             ),
           );

  final http.Client _client;
  final Uri _baseUri;

  Future<List<Shelter>> fetchShelters() async {
    final response = await _client.get(_endpoint('/api/v1/shelters'));
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    final items = decoded is List
        ? decoded
        : decoded is Map<String, dynamic>
            ? decoded['shelters']
            : null;
    if (items is! List) {
      throw const ShelterServiceException('避難所一覧の形式が不正です。');
    }
    return items
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ShelterServiceException('避難所データの形式が不正です。');
          }
          return Shelter.fromJson(item);
        })
        .toList();
  }

  Future<Shelter> fetchShelter(String shelterId) async {
    final response = await _client.get(
      _endpoint('/api/v1/shelters/$shelterId'),
    );
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ShelterServiceException('避難所詳細の形式が不正です。');
    }
    return Shelter.fromJson(decoded['shelter'] is Map<String, dynamic>
        ? decoded['shelter'] as Map<String, dynamic>
        : decoded);
  }

  Uri _endpoint(String path) {
    return _baseUri.replace(
      path: '${_baseUri.path.replaceAll(RegExp(r'/$'), '')}$path',
    );
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ShelterServiceException(
        '避難所情報の取得に失敗しました。（HTTP ${response.statusCode}）',
      );
    }
  }
}

class ShelterServiceException implements Exception {
  const ShelterServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
