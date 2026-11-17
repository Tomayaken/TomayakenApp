import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tomayaken_app/services/disaster_api.dart';

void main() {
  test('認証不要の災害状態GETを呼び、日本語の災害名を取得する', () async {
    final api = DisasterApi(
      baseUrl: 'https://example.test',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/disasters/active');
        expect(request.url.queryParameters, isEmpty);
        expect(request.headers.containsKey('authorization'), isFalse);
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'disaster': {
                'id': 'disaster-1',
                'name': '地震',
                'status': 'active',
                'startedAt': '2026-11-17T00:00:00Z',
                'endedAt': null,
              },
            }),
          ),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final active = await api.active();
    expect(active?.id, 'disaster-1');
    expect(active?.name, '地震');
  });

  for (final json in [
    {'disaster': null},
    {
      'disaster': {'id': 'disaster-1', 'name': '地震', 'status': 'closed'},
    },
  ]) {
    test('災害なし・終了済みでは取得開始の合図を返さない: $json', () async {
      final api = DisasterApi(
        baseUrl: 'https://example.test',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(json),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      addTearDown(api.close);
      expect(await api.active(), isNull);
    });
  }

  for (final body in [
    '{}',
    '[]',
    '{"disaster":{}}',
    '{"disaster":{"id":"1","name":"地震","status":"unknown"}}',
  ]) {
    test('不正な応答を災害の開始や終了とみなさない: $body', () async {
      final api = DisasterApi(
        baseUrl: 'https://example.test',
        client: MockClient(
          (_) async => http.Response(
            body,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      addTearDown(api.close);
      await expectLater(api.active(), throwsFormatException);
    });
  }

  test('サーバーエラーは状態を返さず例外にする', () async {
    final api = DisasterApi(
      baseUrl: 'https://example.test',
      client: MockClient((_) async => http.Response('error', 500)),
    );
    addTearDown(api.close);
    await expectLater(api.active(), throwsA(isA<http.ClientException>()));
  });

  test('接続先未設定時は通信しない', () async {
    final api = DisasterApi(
      baseUrl: '',
      client: MockClient((_) async {
        fail('接続先未設定のとき通信してはいけない');
      }),
    );
    addTearDown(api.close);
    await expectLater(api.active(), throwsStateError);
  });
}
