# Issue #200 Validation

## 이슈

- GitHub Issue: `#200 [FE] fix: iOS 위치 권한 요청 설명 추가`
- Branch: `fix/200-ios-location-permission-description`
- 작업일: 2026-08-02

## 작업 목표

iOS에서 권한 안내 화면의 위치 권한 요청이 정상적으로 시스템 팝업으로 이어질 수 있도록 `Info.plist`에 위치 권한 사용 목적 문구를 추가한다.

## PAAR 기록

### Problem

권한 안내 화면에서 `확인`을 눌러도 알림 권한 팝업은 뜨지만 위치 권한 팝업이 뜨지 않고, “위치 권한이 차단되어 있습니다” 메시지로 이어질 수 있었다.

### Analysis

`PermissionService`는 `Permission.locationWhenInUse.request()`를 호출하고 있었지만, iOS `Info.plist`에는 카메라, 사진, Health 권한 설명만 있고 위치 권한 설명인 `NSLocationWhenInUseUsageDescription`이 없었다. iOS는 권한 요청 전 사용 목적 문구를 요구하므로, 위치 권한 팝업이 정상 표시되려면 해당 키가 필요하다.

### Action

- `frontend/ios/Runner/Info.plist`에 `NSLocationWhenInUseUsageDescription` 추가
- 문구: `주변 감자 스팟 탐색과 관광지 방문 인증을 위해 현재 위치를 사용합니다.`

### Result

- 온보딩/권한 안내 테스트 통과
- iOS simulator build 통과

## 실행 명령과 결과

- `cd frontend && /Users/mac/Documents/flutter/bin/flutter test --no-pub test/features/onboarding/onboarding_screen_test.dart`
  - 성공, 6 tests 통과
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter build ios --simulator --no-pub --dart-define=KAKAO_JAVASCRIPT_KEY=dummy --dart-define=KAKAO_NATIVE_APP_KEY=dummy --dart-define=API_BASE_URL=http://localhost:8080`
  - 성공, `build/ios/iphonesimulator/Runner.app` 생성
  - UIScene lifecycle 경고는 기존 후속 대응 항목이다.

## 시뮬레이터 권한 재확인 방법

이미 한 번 거부된 권한은 앱을 다시 실행해도 팝업이 다시 뜨지 않을 수 있다. 이 경우 아래 명령으로 시뮬레이터 권한 상태를 초기화하거나 강제 허용한다.

```bash
xcrun simctl privacy booted reset all com.gamjamubwatna.frontend
xcrun simctl privacy booted grant location com.gamjamubwatna.frontend
```

시뮬레이터 메뉴에서도 위치 시뮬레이션이 켜져 있어야 한다.

- `Features > Location > Apple`
- 또는 `Features > Location > Custom Location`

## 남은 리스크

- 실제 권한 팝업 표시는 시뮬레이터/실기기 상태에 따라 다르므로, 앱 삭제 또는 privacy reset 후 수동 확인이 필요하다.
- 카카오 로그인 실패는 이번 위치 권한 수정 범위가 아니다. URL scheme, Kakao Developers iOS 플랫폼 등록, API 서버 연결 상태를 별도로 확인해야 한다.
