# Issue #13 Validation - 카카오 로그인 연동 및 토큰 저장

## 작업 목표

- iOS/Android에서는 Kakao Flutter SDK 기반 실제 카카오 로그인을 연결한다.
- Web은 현재 `kakao_flutter_sdk_user 2.0.0+1`이 Web 로그인 메서드를 지원하지 않으므로 안내 상태로 처리한다.
- 카카오 access token을 백엔드 `POST /api/auth/kakao`로 전달하고, 백엔드 JWT를 `TokenStorage`에 저장하는 구조를 만든다.
- 진행 중 발생한 문제, 해결 방법, 새롭게 알게 된 점, 검증 명령과 결과를 기록한다.

## 진행 로그

### 2026-06-17

- `kakao_flutter_sdk_user` 의존성을 추가했다.
- `KakaoSdkInitializer`를 추가해 `KAKAO_NATIVE_APP_KEY`, `KAKAO_JAVASCRIPT_KEY` 기반 SDK 초기화 구조를 만들었다.
- `flutter analyze` 통과 후 아래 커밋을 원격 브랜치에 push했다.
  - `3e41cc9 [FE] chore(auth): 카카오 로그인 SDK 추가 (#13)`
  - `a14c047 [FE] feat(auth): 카카오 SDK 초기화 추가 (#13)`

### 2026-06-19

- 백엔드 카카오 로그인 API를 추가했다.
  - `POST /api/auth/kakao`
  - request: `{ "accessToken": "kakao-access-token" }`
  - response: `success`, `message`, `data.accessToken`, `data.refreshToken`, `data.user`
- 프론트에서 받은 Kakao access token을 백엔드가 카카오 사용자 정보 API로 검증하는 경계를 만들었다.
- 아직 회원 DB가 없으므로 사용자 저장/조회는 구현하지 않고, 카카오 사용자 정보 기반으로 서비스 JWT를 발급하는 MVP 구조로 제한했다.
- JWT는 서버에서만 발급하며, 프론트는 백엔드 JWT 저장만 담당한다.

## 발생한 문제와 해결

### 카카오 로그인에서 프론트엔드와 백엔드 역할 분리

- 질문: 카카오 로그인 연동은 백엔드에서 주로 하는 것이 아닌가?
- 판단: 인증의 최종 검증과 우리 서비스 JWT 발급은 백엔드가 담당하는 것이 맞다.
- 프론트엔드 역할:
  - iOS/Android에서 Kakao Flutter SDK로 사용자 카카오 로그인을 실행한다.
  - 카카오가 발급한 Kakao access token을 백엔드 `POST /api/auth/kakao`로 전달한다.
  - 백엔드가 검증 후 발급한 우리 서비스 `accessToken`, `refreshToken`만 안전한 저장소에 저장한다.
- 백엔드 역할:
  - 프론트에서 받은 Kakao access token을 카카오 서버에 검증한다.
  - 카카오 사용자 식별자와 서비스 사용자를 매핑하거나 신규 가입 처리한다.
  - 우리 서비스용 JWT access/refresh token을 발급한다.
- 이 방법을 선택한 이유:
  - Kakao REST API 키, Admin 키, 사용자 매핑 로직, JWT 서명 키는 프론트에 노출되면 안 된다.
  - 프론트에서 직접 서비스 JWT를 만들면 서명 키가 노출되므로 보안상 부적절하다.
  - iOS/Android SDK는 사용자의 카카오 로그인 UX에 적합하고, 백엔드는 검증과 세션 발급이라는 서버 신뢰 경계를 담당하는 것이 일반적인 구조다.
  - Web 로그인은 현재 Flutter SDK가 직접 지원하지 않으므로 #13에서는 안내 상태로 두고, 필요 시 백엔드 OAuth redirect 기반 Web 로그인으로 별도 설계한다.

### Flutter Web 카카오 로그인 미지원

- 확인 내용: `kakao_flutter_sdk_user 2.0.0+1` 내부 `UserApi.loginWithKakaoTalk`, `loginWithKakaoAccount`, `loginWithKakao`가 `kIsWeb`일 때 `notSupported` 예외를 던진다.
- 해결 방향: #13에서는 iOS/Android 실제 로그인, Web은 안내 상태로 구현한다. Web 실제 로그인은 별도 OAuth redirect 또는 Kakao JavaScript SDK 로그인 연동 이슈로 분리하는 것이 안전하다.

## 새롭게 알게 된 점

- Kakao Flutter SDK의 User 로그인 API는 현재 프로젝트가 해석한 최신 resolvable 버전 기준으로 Web 로그인을 직접 지원하지 않는다.
- Web 지도는 JavaScript 키로 가능하지만, Web 로그인은 Flutter SDK 방식과 별개로 설계해야 한다.
- 백엔드에서는 `KAKAO_REST_API_KEY` 없이도 프론트가 전달한 Kakao access token의 Bearer 인증으로 `/v2/user/me` 사용자 정보 확인이 가능하다.
- JWT 서명 키는 프론트에 절대 노출하지 않고 백엔드 환경변수 `JWT_SECRET`으로 관리해야 한다.

## 검증 기록

- `flutter analyze`: 통과. 단, `flutter_secure_storage`의 iOS Swift Package Manager 미지원 경고가 표시됨.
- Android/iOS 카카오 로그인 callback 설정을 추가했다.
  - Android: `local.properties`의 `kakao.nativeAppKey` 또는 `KAKAO_NATIVE_APP_KEY` 환경변수로 manifest placeholder `kakaoRedirectScheme`을 주입한다.
  - iOS: `ios/Flutter/Secrets.xcconfig`의 `KAKAO_REDIRECT_SCHEME`으로 URL scheme을 주입한다.
- `flutter analyze`: 통과.
- `cd frontend/android && ./gradlew :app:processDebugMainManifest`: 통과.
  - 관찰된 경고: Gradle 9/AGP 9 환경에서 Kotlin Gradle Plugin 및 일부 의존 패키지 AndroidManifest `package` 속성 deprecation 경고가 출력됨.
  - 판단: 현재 카카오 redirect scheme 설정 실패가 아니라 빌드 도구/의존성 호환성 경고이므로 별도 기술부채로 분리 가능.
- Auth repository/service/controller를 추가하고 LoginScreen의 카카오 로그인 버튼을 실제 auth 흐름에 연결했다.
  - iOS/Android: Kakao SDK 로그인 시도 후 Kakao access token을 백엔드 `POST /api/auth/kakao`로 전달한다.
  - Web: Flutter용 Kakao SDK 로그인 API 미지원 안내 메시지를 표시한다.
  - 백엔드 응답 `data.accessToken`, `data.refreshToken`은 `TokenStorage`에 저장한다.
- 사용자가 요청한 `frontend_kakao_web_map.png`를 `frontend/assets/kakao_login_button.png`로 복사해 카카오 로그인 버튼의 작은 썸네일로 활용했다.
- `flutter test` 1차 시도: 실패.
  - 원인: `flutter analyze`와 `flutter test`를 동시에 실행해 iOS ephemeral 파일 삭제 충돌 발생.
  - 해결: Flutter 명령을 순차 실행.
- `flutter analyze`: 통과.
- `flutter test`: 통과. 총 7개 테스트 통과.
- AuthRepository 테스트를 추가해 백엔드 JWT 저장 구조를 검증했다.
  - 성공 응답 시 `TokenStorage`에 `accessToken`, `refreshToken` 저장 확인.
  - 백엔드 응답에 토큰이 비어 있으면 예외 발생 확인.
- `flutter test test/features/auth`: 통과. 총 4개 테스트 통과.
- `flutter analyze && flutter test`: 통과. 총 9개 테스트 통과.
- 로그인 화면 캡처를 진행했다.
  - `flutter run -d web-server` + Playwright headless 캡처: 실패. Flutter Web debug/DDC 렌더링에서 흰 화면이 캡처됨.
  - 실제 Chrome 실행 캡처: 실패. 같은 흰 화면 현상.
  - `flutter build web` release 빌드 + `python3 -m http.server` + Playwright headless 캡처: 성공.
  - 산출물: `artifacts/validation/issue-13/login-web-release.png`
  - 관찰: Playwright `wait_for_selector('text=카카오 로그인')`는 Flutter canvas 기반 렌더링 텍스트를 DOM 텍스트로 잡지 못해 timeout이 발생했지만, 스크린샷 픽셀 렌더링은 정상이었다.
- Apple 로그인 준비 중 버튼을 제거하고 카카오 로그인만 남겼다.
- `frontend_kakao_web_map.png`에서 복사한 `assets/kakao_login_button.png`를 카카오 로그인 버튼 전체 배경으로 사용하도록 변경했다.
- `flutter analyze && flutter test`: 통과. 총 9개 테스트 통과.
- 카카오 로그인 버튼 이미지를 `assets/kakao_login_medium_wide.png`로 교체했다.
  - 버튼은 이미지 자체를 전체 표시하고, 접근성을 위해 `Semantics(label: '카카오 로그인')`을 유지했다.
  - 버튼 그룹을 조금 더 위로 올리기 위해 하단 `Spacer`를 추가했다.
- `flutter analyze && flutter test`: 통과. 총 9개 테스트 통과.
- `flutter build web`: 통과. Wasm dry run 경고와 web/index 초기화 deprecation 경고는 기존과 동일하게 관찰됨.
- 로그인 화면 캡처 갱신: `artifacts/validation/issue-13/login-web-release.png`
- 백엔드 카카오 로그인 controller/service/JWT 발급 테스트를 추가했다.
  - `AuthControllerTest`: `/auth/kakao` 성공 응답 계약, 빈 accessToken 400 검증.
  - `AuthServiceTest`: Kakao 사용자 정보가 서비스 JWT와 user 응답으로 변환되는지 검증.
- `cd backend && env GRADLE_USER_HOME=... ./gradlew test`: 1차 실패.
  - 원인: 기본 Gradle cache 경로 `~/.gradle` 쓰기가 샌드박스에 막힘.
  - 해결: `GRADLE_USER_HOME=/Users/mac/Desktop/lee/project/potato-mubwanna/backend/.gradle`로 프로젝트 내부 cache 사용.
- `cd backend && env GRADLE_USER_HOME=... ./gradlew test`: 2차 실패.
  - 원인: 제한된 네트워크에서 Gradle 배포본 다운로드 불가.
  - 해결: 승인된 네트워크 실행으로 Gradle wrapper 배포본 다운로드.
- `cd backend && env GRADLE_USER_HOME=... ./gradlew test`: 통과.
- `cd backend && env GRADLE_USER_HOME=... ./gradlew test build`: 통과.

## 남은 작업

- iOS/Android 실제 기기 또는 시뮬레이터에서 카카오 로그인 redirect 동작 확인.
- 회원 DB 저장/조회, refresh token rotation, JWT 검증 필터, 권한 인가 정책은 후속 백엔드 인증 고도화 이슈로 분리한다.
- 필요한 경우 백엔드 성능 테스트는 #13 인증 흐름과 분리해 별도 검증 섹션 또는 후속 이슈로 기록한다.
