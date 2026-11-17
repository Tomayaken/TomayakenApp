import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tomayaken_app/services/user_registration_service.dart';

void main() {
  test('ユーザー登録は指定されたUUIDと名前をPUTする', () async {
    late http.Request request;
    final client = MockClient((receivedRequest) async {
      request = receivedRequest;
      return http.Response('', 200);
    });

    await UserRegistrationService(
      client: client,
      baseUri: Uri.parse('https://example.com'),
    ).registerUser(userId: '4e2c6e7c-5f6e-4e29-9be5-0a0c2d6e8c11', name: '山田太郎');

    expect(request.method, 'PUT');
    expect(
      request.url.toString(),
      'https://example.com/api/v1/users/4e2c6e7c-5f6e-4e29-9be5-0a0c2d6e8c11',
    );
    expect(request.headers['content-type'], 'application/json');
    expect(jsonDecode(request.body), {'name': '山田太郎'});
  });

  test('INVALID_REQUESTのエラーコードとメッセージを返す', () async {
    final client = MockClient(
      (_) async => http.Response.bytes(
        utf8.encode(jsonEncode({'code': 'INVALID_REQUEST', 'message': '名前が不正です'})),
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );

    await expectLater(
      UserRegistrationService(
        client: client,
        baseUri: Uri.parse('https://example.com'),
      ).registerUser(userId: 'user-id', name: '名前'),
      throwsA(
        isA<UserRegistrationException>()
            .having((error) => error.code, 'code', 'INVALID_REQUEST')
            .having((error) => error.message, 'message', '名前が不正です'),
      ),
    );
  });
}
