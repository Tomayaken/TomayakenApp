import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tomayaken_app/services/user_identity_service.dart';

void main() {
  test('利用者IDを初回だけ生成して保存し、以降は同じIDを返す', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = UserIdentityService(preferences: preferences);

    final firstId = await service.getOrCreateUserId();
    final secondId = await service.getOrCreateUserId();

    expect(firstId, secondId);
    expect(
      firstId,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(preferences.getString('user_id'), firstId);
  });
}
