import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class Coordinates {
  const Coordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

enum LocationProblem { denied, deniedForever, disabled, timeout, unavailable }

class LocationFailure implements Exception {
  const LocationFailure(this.problem);
  final LocationProblem problem;
}

abstract interface class CurrentLocationService {
  Future<Coordinates> locate();
  Future<bool> openSettings(LocationProblem problem);
}

class DeviceLocationService implements CurrentLocationService {
  @override
  Future<Coordinates> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationFailure(LocationProblem.disabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationFailure(LocationProblem.deniedForever);
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw const LocationFailure(LocationProblem.denied);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return Coordinates(position.latitude, position.longitude);
    } on TimeoutException {
      throw const LocationFailure(LocationProblem.timeout);
    } on LocationServiceDisabledException {
      throw const LocationFailure(LocationProblem.disabled);
    } on PermissionDeniedException {
      throw const LocationFailure(LocationProblem.denied);
    } on LocationFailure {
      rethrow;
    } catch (_) {
      throw const LocationFailure(LocationProblem.unavailable);
    }
  }

  @override
  Future<bool> openSettings(LocationProblem problem) async {
    if (kIsWeb) return false;
    try {
      return problem == LocationProblem.disabled
          ? await Geolocator.openLocationSettings()
          : await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
