# Issue #137 Validation

## 작업 목표

- 방문 인증 시 위치 서비스 꺼짐, 위치 권한 거부, 영구 거부 상태를 구분한다.
- 실패 원인을 사용자가 이해할 수 있는 문구로 안내한다.
- 앱 설정 또는 위치 설정으로 이동할 수 있는 복구 액션을 제공한다.

## PAAR 기록

### P: Problem

방문 인증 성공 UI는 연결되어 있었지만, 실제 위치를 가져오지 못하는 모든 상황이 `현재 위치를 확인하지 못했습니다.`로만 표시되고 있었다. GPS 기반 방문 인증은 서비스 핵심 루프이므로 사용자가 위치 서비스를 켜야 하는지, 앱 권한을 다시 허용해야 하는지 알 수 있어야 했다.

### A: Action

- `LocationService`에서 `Geolocator.isLocationServiceEnabled`, `checkPermission`, `requestPermission` 흐름을 먼저 확인하도록 정리했다.
- 위치 실패를 `LocationFailureType.serviceDisabled`, `permissionDenied`, `permissionDeniedForever`, `unavailable`로 분류했다.
- 위치 서비스 비활성 상태는 `위치 설정`, 권한 차단 상태는 `앱 설정` 스낵바 액션을 제공하도록 화면에 연결했다.
- 방문 인증 컨트롤러가 `LocationFailure`를 `ApiException`으로 덮어쓰지 않고 그대로 UI에 전달하게 했다.
- 위젯 테스트에서 앱 설정 액션과 위치 설정 액션 문구가 표시되는지 검증했다.

### A: Analysis

위치 실패를 단순 예외 메시지로만 처리하면 iOS/Android 권한 정책 차이가 화면까지 전파되지 않는다. 그래서 위치 서비스 레이어에서 실패 이유와 복구 대상 설정 화면을 함께 담는 도메인 예외로 변환했다. UI는 해당 예외를 읽어 스낵바 액션만 선택하므로, 방문 인증 API 실패와 위치 권한 실패가 섞이지 않는다.

### R: Result

- 위치 권한 차단 시: `위치 권한이 차단되어 있습니다. 앱 설정에서 위치 권한을 허용해주세요.` + `앱 설정`
- 위치 서비스 꺼짐 시: `휴대폰 위치 서비스가 꺼져 있습니다. 위치 서비스를 켠 뒤 다시 인증해주세요.` + `위치 설정`
- 백엔드 방문 인증 실패는 기존처럼 API 메시지를 그대로 표시한다.

## 실행한 검증

```bash
cd /Users/mac/Desktop/lee/project/potato-mubwanna/frontend
/Users/mac/Documents/flutter/bin/flutter test test/features/spot/spot_detail_screen_test.dart
```

결과: 통과

```bash
cd /Users/mac/Desktop/lee/project/potato-mubwanna/frontend
/Users/mac/Documents/flutter/bin/flutter analyze
```

결과: 통과

## 참고 로그

- `flutter` 명령이 현재 쉘 PATH에 없어 `/Users/mac/Documents/flutter/bin/flutter` 절대 경로로 실행했다.
- 의존성 경고: `health`, `flutter_secure_storage`가 iOS Swift Package Manager를 아직 지원하지 않는다는 Flutter 경고가 표시되었다. 이번 변경 범위와 직접 관련은 없으며 테스트와 분석은 통과했다.

## 남은 리스크

- 실제 iOS/Android 시스템 권한 팝업과 설정 이동은 위젯 테스트로 완전 검증할 수 없다. 실제 기기 또는 시뮬레이터에서 위치 권한 거부, 영구 거부, 위치 서비스 비활성 상태를 수동으로 확인해야 한다.
- Web에서는 브라우저 위치 권한 UX가 브라우저 정책을 따른다. 카카오 지도와 함께 실제 위치 인증을 검증하려면 HTTPS 또는 localhost 조건에서 확인이 필요하다.

## 후속 작업

- 방문 인증 실패 화면을 스낵바보다 더 명확한 바텀시트로 고도화할 수 있다.
- `다음 장소 추천` 버튼은 현재 지도 이동 중심이다. 추천 동선 API와 연결되면 인증 성공 후 추천 장소를 바로 강조 표시해야 한다.
