import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tomayaken_app/services/shelter_service.dart';

void main() {
  test('避難所一覧を取得してモデルへ変換する', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/shelters');
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'shelters': [
            {
              'id': 'shelter-1',
              'name': '中央避難所',
              'latitude': 35.68,
              'longitude': 139.76,
              'crowding': '空き',
              'distanceMeters': 850,
            },
          ],
        })),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final shelters = await ShelterService(
      client: client,
      baseUri: Uri.parse('https://example.com'),
    ).fetchShelters();

    expect(shelters, hasLength(1));
    expect(shelters.single.name, '中央避難所');
    expect(shelters.single.distanceMeters, 850);
  });

  test('避難所詳細を取得する', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/shelters/shelter-1');
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'id': 'shelter-1',
          'name': '中央避難所',
          'latitude': 35.68,
          'longitude': 139.76,
          'address': '東京都千代田区',
        })),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final shelter = await ShelterService(
      client: client,
      baseUri: Uri.parse('https://example.com'),
    ).fetchShelter('shelter-1');

    expect(shelter.address, '東京都千代田区');
  });
}
