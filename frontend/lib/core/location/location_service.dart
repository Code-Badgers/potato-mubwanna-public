import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationFailureType {
  consentRequired,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  inaccurate,
  unavailable,
}

enum LocationSettingsTarget {
  app,
  location,
}

class LocationFailure implements Exception {
  const LocationFailure({
    required this.type,
    required this.message,
    this.settingsTarget,
    this.actionLabel,
  });

  final LocationFailureType type;
  final String message;
  final LocationSettingsTarget? settingsTarget;
  final String? actionLabel;
}

class LocationService {
  LocationService({
    Future<bool> Function()? hasPersonalLocationConsent,
  }) : _hasPersonalLocationConsent =
            hasPersonalLocationConsent ?? _acceptExistingLocationCall;

  final Future<bool> Function() _hasPersonalLocationConsent;

  Future<Position> getCurrentPosition() async {
    if (!await _hasPersonalLocationConsent()) {
      throw const LocationFailure(
        type: LocationFailureType.consentRequired,
        message: '방문 인증을 하려면 먼저 개인위치정보 이용에 동의해주세요.',
        actionLabel: '동의하기',
      );
    }
    await _ensureLocationServiceEnabled();
    await _ensurePermissionGranted();

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(const Duration(seconds: 15));
    } on LocationServiceDisabledException {
      throw const LocationFailure(
        type: LocationFailureType.serviceDisabled,
        message: '휴대폰 위치 서비스가 꺼져 있습니다. 위치 서비스를 켠 뒤 다시 인증해주세요.',
        settingsTarget: LocationSettingsTarget.location,
        actionLabel: '위치 설정',
      );
    } on PermissionDeniedException {
      throw const LocationFailure(
        type: LocationFailureType.permissionDenied,
        message: '위치 권한이 없어 방문 인증을 진행할 수 없습니다.',
        settingsTarget: LocationSettingsTarget.app,
        actionLabel: '앱 설정',
      );
    } on TimeoutException {
      throw const LocationFailure(
        type: LocationFailureType.timeout,
        message: '위치 확인에 시간이 걸리고 있습니다. GPS가 잘 잡히는 곳에서 다시 시도해주세요.',
        actionLabel: '다시 시도',
      );
    } on LocationFailure {
      rethrow;
    } catch (_) {
      throw const LocationFailure(
        type: LocationFailureType.unavailable,
        message: '현재 위치를 확인하지 못했습니다. 잠시 후 다시 시도해주세요.',
        actionLabel: '다시 시도',
      );
    }
  }

  Future<bool> openSettings(LocationSettingsTarget target) {
    switch (target) {
      case LocationSettingsTarget.app:
        return Geolocator.openAppSettings();
      case LocationSettingsTarget.location:
        return Geolocator.openLocationSettings();
    }
  }

  Future<void> _ensureLocationServiceEnabled() async {
    if (kIsWeb) {
      return;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        type: LocationFailureType.serviceDisabled,
        message: '휴대폰 위치 서비스가 꺼져 있습니다. 위치 서비스를 켠 뒤 다시 인증해주세요.',
        settingsTarget: LocationSettingsTarget.location,
        actionLabel: '위치 설정',
      );
    }
  }

  Future<void> _ensurePermissionGranted() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        type: LocationFailureType.permissionDenied,
        message: '위치 권한이 없어 방문 인증을 진행할 수 없습니다.',
        settingsTarget: LocationSettingsTarget.app,
        actionLabel: '앱 설정',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        type: LocationFailureType.permissionDeniedForever,
        message: '위치 권한이 차단되어 있습니다. 앱 설정에서 위치 권한을 허용해주세요.',
        settingsTarget: LocationSettingsTarget.app,
        actionLabel: '앱 설정',
      );
    }
  }
}

Future<bool> _acceptExistingLocationCall() async => true;
