# Issue 15 Validation

## 작업 목표

- iOS/Android 카카오 로그인은 기존 Native SDK를 유지한다.
- Web 카카오 로그인은 Kakao JavaScript SDK 팝업 로그인으로 access token을 받아 기존 백엔드 `/auth/kakao` API에 전달한다.
- 카카오 로그인 단계에서 닉네임(`profile_nickname`)과 이메일(`account_email`) 동의를 요청한다.
- 앱 진입 UX는 서비스 소개 온보딩 3장 → 로그인 → 접근권한 안내 → 메인 지도 순서로 정리한다.

## 진행 과정

- `KakaoLoginService`를 conditional export 구조로 분리했다.
  - iOS/Android: `kakao_flutter_sdk_user` 기반 로그인
  - Web: Kakao JavaScript SDK 동적 로드 후 `Kakao.Auth.login` 호출
- Native 로그인 후 token scope에 닉네임/이메일 scope가 없으면 `loginWithNewScopes`로 추가 동의를 요청하도록 했다.
- Web 로그인은 `scope: profile_nickname,account_email`을 함께 요청하도록 했다.
- 권한 안내 화면을 온보딩 내부 페이지가 아니라 `/permissions` 라우트로 분리했다.
- 로그인 성공 또는 로그인 건너뛰기 후 `/permissions`를 거쳐 `/main/map`으로 이동하도록 변경했다.
- Flutter Web 초기화 코드에서 deprecated `loadEntrypoint` 사용을 `load`로 교체했다.

## 확인한 문제와 해결

- `kakao_flutter_sdk_user` 2.0.0+1은 Flutter Web 로그인을 직접 지원하지 않아 Web에서 SDK 호출을 막고 있었다.
  - 해결: Web 전용 구현에서 Kakao JavaScript SDK를 사용하도록 분리했다.
- `dart:js_util`/`package:js` 조합이 현재 analyzer에서 맞지 않아 Web interop 에러가 발생했다.
  - 해결: `dart:js`의 `JsObject`/`JsFunction.withThis` 방식으로 정리했다.
- 기존 온보딩 테스트는 권한 페이지가 온보딩 안에 있다고 가정했다.
  - 해결: 온보딩 소개 흐름 테스트와 권한 안내 화면 테스트를 분리했다.

## 실행한 검증

- `cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze`
  - 결과: 통과
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter test test/features/onboarding/onboarding_screen_test.dart test/features/auth/login_screen_test.dart test/features/auth/auth_repository_test.dart`
  - 결과: 통과
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter build web --dart-define=KAKAO_JAVASCRIPT_KEY=dummy --dart-define=API_BASE_URL=http://localhost:8080/api`
  - 결과: 통과

## 남은 리스크

- Web 카카오 로그인은 Kakao Developers에 현재 실행 도메인이 등록되어 있어야 팝업 로그인이 성공한다.
- Web 로그인 팝업은 브라우저 팝업 차단 정책의 영향을 받을 수 있으므로 반드시 사용자 클릭 이벤트에서 시작해야 한다.
- 이메일은 선택 동의이므로 사용자가 거부하거나 카카오 계정에 이메일이 없으면 DB에는 `null`로 저장된다.
- 빌드 중 Wasm dry run 경고가 표시된다. 현재 HTML/JS Web 빌드는 성공하지만, `flutter_secure_storage_web`과 `geolocator_web`이 Wasm 미지원 API를 사용하므로 향후 Wasm 빌드가 필요하면 별도 대응이 필요하다.
- `flutter_secure_storage`의 iOS Swift Package Manager 미지원 경고는 현재 빌드 중단 오류가 아니며, 플러그인 업그레이드 또는 CocoaPods 유지 정책을 별도 이슈에서 검토한다.
