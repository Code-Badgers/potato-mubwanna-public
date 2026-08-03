# Issue #238 validation

## 작업 요약

- 이슈: `#238 [FE] fix: 세션 복구 실패 시 푸시 토큰 해제`
- 브랜치: `fix/238-failed-session-push-cleanup`
- 담당 영역: 앱 시작 시 저장된 인증 세션 복구 실패 처리
- 제외 범위: UI, 백엔드, API request/response, DB migration, FCM 실기기 수신 QA
- 목표: 만료되거나 폐기된 세션으로 앱을 시작했을 때 이전 사용자의 푸시 등록을 먼저 해제한 뒤 인증 토큰을 정리하고 로그인 화면으로 이동한다.

## 진행 과정과 원인

- `SessionStartupCoordinator`는 저장된 refresh token으로 세션 복구가 실패하면 access/refresh token만 삭제했다.
- 기존 `registeredPushToken`, Firebase registration token, auto-init 설정과 서버 푸시 토큰 행이 남을 수 있었다.
- foreground 푸시 구독은 인증 상태와 별개로 동작하므로 로그인 화면에서도 이전 사용자의 알림이 노출될 여지가 있었다.
- 세션 복구 실패 분기에 기존 `PushNotificationService.unregister()`를 연결해 별도 API 계약이나 중복 수명주기 구현 없이 해결했다.

## 변경 파일

- `frontend/lib/features/auth/application/session_startup_coordinator.dart`: 세션 복구 실패 시 푸시 해제를 인증 토큰 삭제보다 먼저 best-effort로 실행
- `frontend/test/features/auth/session_startup_coordinator_test.dart`: 호출 순서와 푸시 해제 실패 격리 회귀 테스트 추가
- `frontend/test/features/auth/session_startup_screen_test.dart`: 새 의존성 주입 반영
- `artifacts/validation/issue-238/VALIDATION.md`: 재현, 검증, 리스크 기록

## 공유 파일 / 계약 변경

- 공유 위험 파일: 인증 시작 수명주기 파일을 최소 수정했으며 열린 PR #209, #233, #236과 파일 중복 없음
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 변경 없음
- 외부 API: 기존 푸시 토큰 삭제 API만 사용

## 검증

- 수정 전 재현 테스트: 실패 확인
  - 기대 순서: `unregister-push`, `clear-tokens`
  - 실제 순서: `clear-tokens`만 호출
- 세션 시작·인증·푸시 관련 테스트: 20개 통과
- `flutter analyze`: 통과, 이슈 0건
- 전체 `flutter test`: 227개 통과
- `flutter build apk --debug`: 통과
- `git diff --check`: 통과

## 완료 조건 확인

- 세션 갱신 실패 시 푸시 해제 후 인증 토큰을 삭제하고 `/login`으로 이동한다.
- 푸시 해제에서 예외가 발생해도 인증 토큰 삭제와 `/login` 이동을 계속한다.
- 정상 세션 복구 경로에서는 푸시 해제를 호출하지 않는다.
- 기존 로그아웃·탈퇴 구현과 푸시 서비스 파일은 변경하지 않았다.

## 남은 리스크

- 세션 복구 실패 원인이 만료된 access token인 경우 서버 푸시 토큰 삭제 요청도 인증 실패할 수 있다. 이 경우에도 기존 `PushNotificationService`의 `finally` 처리로 로컬 Firebase token, auto-init, 저장된 registration token은 정리된다.
- 서버에 남은 행은 푸시 발송 시 무효 토큰 응답 또는 등록 시 수행되는 기존 stale-token 정리 정책으로 제거된다.
- 기존 Kotlin Gradle Plugin과 Java 8 호환성 경고가 빌드에 표시되지만 이번 변경과 무관하며 빌드는 성공했다.

## 다음 작업

- 이어서 실행할 명령: `cd frontend; C:\\src\\flutter\\bin\\flutter.bat test test\\features\\auth\\session_startup_coordinator_test.dart`
- 확인해야 할 파일: `frontend/lib/features/auth/application/session_startup_coordinator.dart`
- 조율이 필요한 사람 또는 이슈: PR 검토·머지 후 Team A 추적 이슈 #228 갱신
