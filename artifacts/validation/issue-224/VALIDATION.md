# Issue #224 Android 카카오 로그인 콜백 검증

## 변경

- Android 카카오 OAuth 콜백을 `MainActivity`가 아닌 Kakao Flutter SDK의 `AuthCodeHandlerActivity`가 처리하도록 수정했다.

## 환경

- Android Emulator API 36
- 앱 패키지: `com.gamjamubwatna.frontend`
- 로컬 API: Android emulator host loopback를 통해 연결
- 로컬 PostgreSQL 및 Redis 사용

## 검증 결과

- `flutter analyze`: 통과
- Android debug APK 빌드: 통과
- 카카오 OAuth 콜백이 `AuthCodeHandlerActivity`의 `onNewIntent`로 전달됨
- 카카오 액세스 토큰 발급 및 로컬 백엔드 로그인 성공
- DB 사용자 및 refresh token 생성 확인
- 로그인 후 메인 지도 화면 전환 확인
- 앱 재실행 후 로그인 세션 유지 및 메인 화면 복귀 확인
- 앱 치명적 예외 및 ANR 없음

## 증빙

- `login-success-main.png`: 로그인 및 앱 재실행 후 메인 지도 화면

## 참고 사항

- 개발 PC별 Android debug keystore가 다르면 해당 key hash를 Kakao Developers Android 플랫폼 설정에 추가해야 한다.
- 빌드 시 기존 Kotlin Gradle Plugin 호환성 경고가 출력되지만 이번 빌드와 실행에는 영향을 주지 않았다.
