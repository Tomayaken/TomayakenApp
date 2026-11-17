import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tomayaken_app/services/current_location_service.dart';

class _LocationPlatform extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission requestedPermission = LocationPermission.whileInUse;
  int requests = 0;
  int positionRequests = 0;
  bool timeout = false;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return requestedPermission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionRequests++;
    expect(locationSettings?.timeLimit, const Duration(seconds: 20));
    if (timeout) throw TimeoutException('GPS timeout');
    return Position(
      longitude: 139,
      latitude: 35,
      timestamp: DateTime(2026),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  late GeolocatorPlatform original;
  late _LocationPlatform platform;
  setUp(() {
    original = GeolocatorPlatform.instance;
    platform = _LocationPlatform();
    GeolocatorPlatform.instance = platform;
  });
  tearDown(() => GeolocatorPlatform.instance = original);

  test('未許可なら権限を要求し、許可後だけ座標を取得する', () async {
    final result = await DeviceLocationService().locate();
    expect(platform.requests, 1);
    expect(result.latitude, 35);
    expect(result.longitude, 139);
  });

  test('許可済みなら再要求しない', () async {
    platform.permission = LocationPermission.whileInUse;
    await DeviceLocationService().locate();
    expect(platform.requests, 0);
    expect(platform.positionRequests, 1);
  });

  test('ブラウザーで権限状態を判別できない場合も許可を要求する', () async {
    platform.permission = LocationPermission.unableToDetermine;
    await DeviceLocationService().locate();
    expect(platform.requests, 1);
    expect(platform.positionRequests, 1);
  });

  for (final permission in [
    LocationPermission.denied,
    LocationPermission.deniedForever,
  ]) {
    test('拒否時はGPSへ進まない: $permission', () async {
      platform.permission = permission;
      platform.requestedPermission = permission;
      final expectedProblem = permission == LocationPermission.denied
          ? LocationProblem.denied
          : LocationProblem.deniedForever;
      await expectLater(
        DeviceLocationService().locate(),
        throwsA(
          isA<LocationFailure>().having(
            (f) => f.problem,
            'problem',
            expectedProblem,
          ),
        ),
      );
      expect(platform.positionRequests, 0);
      expect(
        platform.requests,
        permission == LocationPermission.denied ? 1 : 0,
      );
    });
  }

  test('位置情報サービスが無効なら権限要求・GPS取得をしない', () async {
    platform.enabled = false;
    await expectLater(
      DeviceLocationService().locate(),
      throwsA(
        isA<LocationFailure>().having(
          (f) => f.problem,
          'problem',
          LocationProblem.disabled,
        ),
      ),
    );
    expect(platform.requests, 0);
    expect(platform.positionRequests, 0);
  });

  test('GPSタイムアウトを案内用の状態へ変換する', () async {
    platform.timeout = true;
    await expectLater(
      DeviceLocationService().locate(),
      throwsA(
        isA<LocationFailure>().having(
          (f) => f.problem,
          'problem',
          LocationProblem.timeout,
        ),
      ),
    );
  });
}
