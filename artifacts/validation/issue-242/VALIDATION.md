# Issue #242 validation

## 작업 요약

- 이슈: `#242 [FE] fix: 로그아웃 상태 foreground 푸시 노출 차단`
- 브랜치: `fix/242-signed-out-foreground-push`
- 담당 영역: Team A 인증 상태와 foreground 푸시 표시 경계
- 제외 범위: UI 디자인·레이아웃·문구, 백엔드/API/DB, Android/iOS FCM 실기기 수신 QA
- 목표: signed-out 또는 세션 만료 상태에서 이전 사용자 대상 foreground 푸시의 내용과 이동 액션을 화면에 노출하지 않는다.

## 원인과 해결

- 앱은 로그인 여부와 관계없이 foreground/opened 푸시 stream을 구독한다.
- opened 메시지는 인증 상태를 확인했지만 foreground 메시지는 표시 내용 유무만 확인했다.
- 로그아웃 직후 토큰 해제가 진행 중이거나 이미 수신 큐에 들어간 메시지가 로그인 화면에서 스낵바로 보일 수 있었다.
- foreground 메시지 처리에도 기존 opened 메시지와 동일한 `AuthStatus.authenticated` 가드를 추가했다.

## 변경 파일

- `frontend/lib/app/app.dart`: authenticated 상태에서만 foreground 푸시 스낵바 표시
- `frontend/test/app/app_push_notification_test.dart`: 같은 앱에서 signed-out 차단과 authenticated 표시를 검증하는 widget test 추가
- `artifacts/validation/issue-242/VALIDATION.md`: 재현, 검증, 리스크 기록

## 공유 파일 / 계약 변경

- 공유 위험 파일: 앱 루트 푸시 표시 처리 파일을 한 조건식만 수정
- 협업 확인: 열린 PR #209, #236과 변경 파일 중복 없음
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 변경 없음
- 외부 API: 변경 없음

## 검증

- 수정 전 widget test 실패로 재현
  - 기대: signed-out 상태에서 `이전 사용자 알림` 미표시
  - 실제: 해당 문구가 포함된 스낵바 `Text` 1개 표시
- 수정 후 관련 앱·인증·푸시 테스트: 18개 통과
- `flutter analyze`: 통과, 이슈 0건
- 전체 `flutter test`: 232개 통과
- `flutter build apk --debug`: 통과
- `git diff --check`: 통과

## 실패했던 시도

- 정적 분석, 전체 테스트, Android 빌드를 한 명령으로 실행했을 때 도구의 2분 실행 제한에 걸려 결과를 확정할 수 없었다. 각 명령을 분리해 다시 실행했고 모두 통과했다.

## 완료 조건 확인

- signed-out 상태의 foreground 메시지는 내용과 `보기` 액션을 렌더링하지 않는다.
- 동일 앱이 authenticated 상태가 된 뒤에는 기존 메시지 내용과 `보기` 액션을 표시한다.
- opened 메시지와 푸시 토큰 수명주기, 스낵바 UI는 변경하지 않았다.

## 산출물

- 검증 기록: `artifacts/validation/issue-242/VALIDATION.md`
- 화면 캡처: UI 변경이 없고 실제 FCM QA는 제외 범위이므로 생성하지 않음

## 남은 리스크

- 실제 Android/iOS 수신 타이밍과 OS 알림 표시는 Team B 실기기 FCM QA 범위에 남는다.
- 기존 Kotlin Gradle Plugin 호환성 경고는 이번 변경과 무관하며 Android 빌드는 성공했다.

## 다음 작업

- 이어서 실행할 명령: `cd frontend; C:\\src\\flutter\\bin\\flutter.bat test test\\app\\app_push_notification_test.dart`
- 확인해야 할 파일: `frontend/lib/app/app.dart`, `frontend/test/app/app_push_notification_test.dart`
- 조율이 필요한 사람 또는 이슈: PR 검토·머지 후 Team A 추적 이슈 #228 갱신
