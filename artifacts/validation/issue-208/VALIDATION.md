# Issue #208 Validation

## 작업 정보

- GitHub Issue: `#208 [FE] feat: iOS HealthKit 백그라운드 감자걸음 동기화`
- Branch: `feat/208-ios-background-step-sync`
- 작업일: 2026-08-02

## PAAR 기록

### Problem

Android는 WorkManager로 백그라운드 걸음 동기화를 수행하지만 iOS는 HealthKit 권한과 전면 동기화만 있어 앱이 백그라운드일 때 새 걸음을 서버에 반영하지 못했다.

### Analysis

- iOS HealthKit 백그라운드 전달에는 `HKObserverQuery`, `enableBackgroundDelivery`, background-delivery entitlement가 필요하다.
- observer가 앱을 깨운 뒤 기존 Dart 인증, 걸음 조회, 서버 동기화 코드를 실행하려면 headless Flutter 엔진과 native/Dart 완료 신호가 필요하다.
- HealthKit은 읽기 권한 상태를 공개하지 않으므로 백그라운드 경로에서 권한 UI 없이 실제 조회 결과로 접근 가능 여부를 판별해야 한다.
- iOS Keychain 기본 `when unlocked` 정책과 isolate별 SharedPreferences 캐시는 잠금 상태 토큰 조회 및 전면 레벨업 전달을 방해할 수 있다.

### Action

- 앱 시작 시 step count observer와 시간 단위 background delivery를 등록했다.
- observer 호출마다 headless Flutter 엔진에서 기존 감자걸음 동기화 서비스를 실행하고, 중복 호출은 하나의 실행으로 합쳤다.
- 성공, 오류, 엔진 시작 실패, 25초 timeout 모든 경로에서 observer completion handler를 호출하도록 구성했다.
- 최초 HealthKit 권한 승인 직후에도 native background delivery를 다시 활성화한다.
- iOS 토큰을 `first_unlock_this_device` 접근 정책으로 저장하고 pending growth 조회 전 SharedPreferences를 reload한다.
- HealthKit background-delivery entitlement와 Dart/native bridge 계약 정적 검증을 추가 수행했다.

### Result

- `flutter analyze`: 성공, 이슈 없음.
- `flutter test`: 성공, 226개 테스트 통과.
- `flutter build apk --debug`: 성공, Android 공용 코드 회귀 없음.
- entitlement XML, channel 이름, entrypoint, start/completed method 일치 정적 검사: 성공.

## 제한 및 잔여 검증

- 현재 작업 환경이 Windows라 `flutter build ios`, Xcode compile, code signing을 실행하지 못했다.
- HealthKit background server query는 Simulator에서 지원되지 않으므로 iOS 실기기에서 최종 검증해야 한다.
- 실기기에서 Health 권한 승인 및 로그인 후 앱을 백그라운드로 보내고 새 걸음을 기록한 뒤, 서버 활동 반영과 다음 전면 진입의 pending level-up 표시를 확인해야 한다.
- Android 빌드에는 기존 Built-in Kotlin 전환 경고가 남지만 빌드는 성공했으며 이번 iOS 변경 범위와 무관하다.

## 참고

- Apple HealthKit observer queries: https://developer.apple.com/documentation/healthkit/executing-observer-queries
- Apple HealthKit background delivery entitlement: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.healthkit.background-delivery
- Flutter iOS `FlutterEngine`: https://api.flutter.dev/ios-embedder/interface_flutter_engine.html
