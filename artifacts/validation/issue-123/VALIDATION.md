# Issue 123 Validation

## 작업 목표

- Xcode 26 환경에서 iOS 시뮬레이터 빌드가 실패하는 문제를 복구한다.
- 원래 실패 로그:
  - `No visible @interface for 'NSProcessInfo' declares the selector 'isiOSAppOnVision'`
  - 발생 위치: `device_info_plus-12.4.0/ios/.../FPPDeviceInfoPlusPlugin.m`
- 검증 대상:
  - `flutter pub get`
  - `flutter analyze`
  - 지도 관련 테스트
  - `flutter build ios --simulator --debug --no-codesign`

## PAAR 기록

### Problem

Flutter iOS 시뮬레이터 빌드가 Xcode 26에서 실패했다. 직접 원인은 `health 13.3.1`이 전이 의존성으로 가져온 `device_info_plus 12.4.0`이었다. 해당 버전의 iOS 코드가 Xcode 26.0 SDK에는 없는 `NSProcessInfo#isiOSAppOnVision` selector를 호출해 Objective-C 컴파일 단계에서 실패했다.

첫 번째 오류를 해결한 뒤에는 `health` iOS Pod에서 `health/health-Swift.h`를 찾지 못하는 추가 오류가 드러났다.

### Approach

처음에는 `device_info_plus`를 13.x로 올리는 방식을 검토했다. 하지만 `device_info_plus 13.x`는 `win32 6.x`를 요구하고, 현재 `flutter_secure_storage 9.2.4`의 Windows 구현은 `win32 5.x`를 요구해 의존성 충돌이 발생했다. 따라서 관련 패키지를 연쇄적으로 업그레이드하는 대신, `health 13.3.1`이 허용하는 12.x 범위 안에서 문제가 없는 `device_info_plus 12.3.0`으로 고정했다.

이후 `health-Swift.h` 오류는 `health` Pod의 Objective-C wrapper가 module-qualified generated Swift header를 import하는 방식 때문에 발생했다. Xcode 26/CocoaPods 조합에서 이 경로가 해석되지 않아 `Podfile`의 `post_install` 단계에서 `#import <health/health-Swift.h>`를 `#import "health-Swift.h"`로 바꾸는 재현 가능한 패치를 추가했다.

### Action

- `frontend/pubspec.yaml`
  - `dependency_overrides.device_info_plus: 12.3.0` 추가
- `frontend/pubspec.lock`
  - `device_info_plus`를 `12.4.0`에서 `12.3.0`으로 잠금
- `frontend/ios/Podfile`
  - `patch_health_swift_header_import` 추가
  - `post_install`에서 `health` plugin import 경로 패치
- `frontend/ios/Podfile.lock`
  - 현재 `pubspec.yaml` 기준으로 누락되어 있던 `health 13.3.1` Pod 반영

### Result

다음 명령을 실행했고 모두 통과했다.

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter pub get
/Users/mac/Documents/flutter/bin/flutter analyze
/Users/mac/Documents/flutter/bin/flutter test test/features/map/map_screen_test.dart test/features/map/favorite_spot_route_test.dart
PATH="/usr/local/lib/ruby/gems/4.0.0/bin:$PATH" /Users/mac/Documents/flutter/bin/flutter build ios --simulator --debug --no-codesign
```

결과 요약:

- `flutter pub get`: 통과
- `flutter analyze`: `No issues found`
- 지도 테스트: `All tests passed`
- iOS 시뮬레이터 빌드: `✓ Built build/ios/iphonesimulator/Runner.app`

## 실패했던 시도와 배운 점

- `device_info_plus 13.0.0` 및 13.x 계열 override 시도
  - 실패 원인: `flutter_secure_storage_windows`와 `win32` 메이저 버전 충돌
  - 판단: 이번 이슈 범위보다 큰 의존성 업그레이드가 필요해 제외
- `health 13.2.0`, `health 12.2.0` 다운그레이드 검토
  - 결과: 둘 다 iOS wrapper의 Swift header import 구조가 동일했다.
  - 판단: `health` 버전 다운그레이드는 근본 해결이 아니며 기능 의존성만 불필요하게 낮춘다.
- `Podfile`의 `use_modular_headers!` 제거 시도
  - 결과: `health-Swift.h` 오류가 계속 발생했다.
  - 판단: 전역 modular headers 설정이 직접 원인은 아니었다.

## 남은 리스크

- `health` Pod import 패치는 upstream 패키지의 iOS 소스 파일을 `pod install` 시점에 보정한다. 패키지 구조가 바뀌면 패치 경로가 더 이상 맞지 않을 수 있다.
- `device_info_plus 12.3.0` 고정은 Xcode 26 빌드 복구를 위한 임시 안정화 조치다. 추후 `flutter_secure_storage`를 10.x 이상으로 올릴 수 있는 별도 이슈에서 `device_info_plus 13.x`로 다시 올리는 것이 좋다.
- Flutter 경고:
  - `health`, `flutter_secure_storage`가 아직 iOS Swift Package Manager를 지원하지 않는다는 경고가 표시된다. 현재는 경고이며 빌드는 통과한다.
  - UIScene lifecycle 지원이 향후 필요하다는 경고가 표시된다. 별도 iOS 플랫폼 정비 이슈로 다루는 것이 적절하다.

## 변경 파일

- `frontend/pubspec.yaml`
- `frontend/pubspec.lock`
- `frontend/ios/Podfile`
- `frontend/ios/Podfile.lock`

