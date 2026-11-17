import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tomayaken_app/models/shelter.dart';
import 'package:tomayaken_app/services/shelter_api.dart';

Map<String, Object> shelterJson(
  String name,
  num distance, {
  bool full = false,
}) => {
  'name': name,
  'distanceMeters': distance,
  'capacity': 100,
  'currentOccupancy': 40,
  'isOverCapacity': full,
};

void main() {
  test('現在地をクエリに渡し、日本語の避難所を距離順に返す。満員も残す', () async {
    final api = ShelterApi(
      baseUrl: 'https://example.test',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/shelters/nearby');
        expect(request.url.queryParameters, {
          'latitude': '35.0',
          'longitude': '139.0',
          'limit': '20',
        });
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'items': [
                shelterJson('遠い避難所', 1500),
                shelterJson('満員の避難所', 100, full: true),
              ],
            }),
          ),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final result = await api.nearby(latitude: 35, longitude: 139);
    expect(result.map((s) => s.name), ['満員の避難所', '遠い避難所']);
    expect(result.first.isFull, isTrue);
    expect(result.last.isFull, isFalse);
  });

  test('API未設定時は通信しない', () async {
    var calls = 0;
    final api = ShelterApi(
      baseUrl: '',
      client: MockClient((_) async {
        calls++;
        return http.Response('[]', 200);
      }),
    );
    addTearDown(api.close);
    await expectLater(
      api.nearby(latitude: 35, longitude: 139),
      throwsStateError,
    );
    expect(calls, 0);
  });

  test('不正な座標は送信しない', () async {
    final api = ShelterApi(
      baseUrl: 'https://example.test',
      client: MockClient((_) async {
        fail('座標が不正なときに通信してはいけない');
      }),
    );
    addTearDown(api.close);
    await expectLater(
      api.nearby(latitude: 91, longitude: 139),
      throwsArgumentError,
    );
  });

  for (final body in [
    '{"shelters":[]}',
    '{"items":[{"name":"incomplete"}]}',
    '[]',
    'not json',
  ]) {
    test('仕様と異なる応答を空の一覧として扱わない: $body', () async {
      final api = ShelterApi(
        baseUrl: 'https://example.test',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(api.close);
      await expectLater(
        api.nearby(latitude: 35, longitude: 139),
        throwsFormatException,
      );
    });
  }

  test('HTTPエラーを成功として扱わない', () async {
    final api = ShelterApi(
      baseUrl: 'https://example.test',
      client: MockClient((_) async => http.Response('error', 503)),
    );
    addTearDown(api.close);
    await expectLater(
      api.nearby(latitude: 35, longitude: 139),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('空配列は正常な検索結果', () async {
    final api = ShelterApi(
      baseUrl: 'https://example.test',
      client: MockClient((_) async => http.Response('{"items":[]}', 200)),
    );
    addTearDown(api.close);
    expect(await api.nearby(latitude: 35, longitude: 139), isEmpty);
  });

  test('収容人数ちょうど、超過、収容人数ゼロも満員になる', () {
    for (final capacity in [40, 39, 0]) {
      expect(
        Shelter.fromJson({
          ...shelterJson('避難所', 0),
          'capacity': capacity,
        }).isFull,
        isTrue,
      );
    }
    expect(
      () => Shelter.fromJson(shelterJson('避難所', -1)),
      throwsFormatException,
    );
  });
}
