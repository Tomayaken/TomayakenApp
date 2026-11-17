import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserIdentityService {
  UserIdentityService({
    required SharedPreferences preferences,
    Uuid uuid = const Uuid(),
  }) : _preferences = preferences,
       _uuid = uuid;

  static const _userIdKey = 'user_id';

  final SharedPreferences _preferences;
  final Uuid _uuid;

  Future<String> getOrCreateUserId() async {
    final storedUserId = _preferences.getString(_userIdKey);
    if (storedUserId != null && storedUserId.isNotEmpty) {
      return storedUserId;
    }

    final userId = _uuid.v4();
    final saved = await _preferences.setString(_userIdKey, userId);
    if (!saved) {
      throw const UserIdentityException('利用者IDを保存できませんでした。');
    }
    return userId;
  }
}

class UserIdentityException implements Exception {
  const UserIdentityException(this.message);

  final String message;

  @override
  String toString() => message;
}
