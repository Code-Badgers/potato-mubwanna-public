# Issue #176 FCM push flow validation

## 작업 요약

- 이슈: #176 `[FE/BE] feat: FCM 푸시 등록·발송·수신 흐름 연결`
- 브랜치: `feat/176-fcm-push-flow`
- 담당 영역: push token API/DB, Firebase Admin 발송 서비스, Flutter FCM token 수명주기, 수신과 탭 라우팅, Android/iOS capability
- 제외 범위: Web push, 공개 관리자 발송 endpoint, Firebase 프로젝트 비밀값, 실제 Android/iOS 기기 수신 확인
- 목표: Firebase 설정이 있는 모바일 환경은 로그인 사용자 push를 end-to-end로 연결하고, 설정이 없는 환경은 push만 안전하게 비활성화한다.

## 변경 요약

- `POST/DELETE /api/users/me/push-tokens` 계약과 인증 controller를 추가했다.
- V21 migration으로 사용자별 FCM token, platform, 갱신 시각과 사용자 삭제 cascade를 추가했다.
- 같은 token의 idempotent 등록, refresh 시 이전 token 교체, stale token 정리, 로그아웃 삭제를 구현했다.
- Firebase Admin SDK를 조건부 초기화하고 사용자 전체 기기 발송과 FCM 무효 token 정리를 구현했다.
- Flutter는 Firebase 설정이 모두 있는 Android/iOS에서만 초기화한다.
- 알림 권한이 허용된 동안에만 FCM 자동 초기화를 활성화하며, 권한 철회/로그아웃/회원 탈퇴 때 서버 token, Firebase token, 로컬 token을 정리한다.
- foreground 알림과 background/terminated 탭을 동일한 whitelist resolver로 처리한다.
- Android/iOS push capability와 background mode를 연결하고 실제 기기 QA 절차를 `agents_docs/FCM_SETUP_GUIDE.md`에 기록했다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: `frontend/android/app/src/main/AndroidManifest.xml`, `frontend/ios/Runner.xcodeproj/project.pbxproj`, `frontend/ios/Runner/Info.plist`
- API 계약: `agents_docs/07_api_specification.md` 2.4~2.6
- DB migration: `V21__create_user_push_tokens.sql`
- Frontend 환경 변수: `FIREBASE_API_KEY`, `FIREBASE_ANDROID_APP_ID`, `FIREBASE_IOS_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`
- Backend 환경 변수: `FIREBASE_ADMIN_ENABLED`, `FIREBASE_PROJECT_ID`, `GOOGLE_APPLICATION_CREDENTIALS`, `PUSH_TOKEN_STALE_DAYS`
- 외부 API: Firebase Cloud Messaging HTTP v1 via Firebase Admin SDK

## PAAR 기록

### 1. 사용자 동의 전 token 자동 생성

- Problem: Firebase 설정만으로 FCM token이 자동 생성되면 알림 권한 결정 전에 식별자와 설정 데이터가 업로드될 수 있다.
- Analysis: Firebase 공식 지침은 Android에서 FCM auto-init과 Analytics 수집을 함께 끄고, iOS에서 `FirebaseMessagingAutoInitEnabled`를 끈 뒤 런타임에 명시적으로 다시 켜도록 안내한다.
- Action: 네이티브 auto-init을 기본 비활성화하고, 권한 허용 뒤 `setAutoInitEnabled(true)`, 권한 철회와 인증 종료 때 `setAutoInitEnabled(false)`를 호출하도록 했다.
- Result: 동의하지 않은 사용자는 token 등록 흐름을 타지 않으며 허용 상태에서만 token 발급과 refresh 구독이 시작된다.

### 2. 로그아웃과 token refresh 경합

- Problem: 앱 시작 때 refresh stream을 먼저 구독하면 로그아웃 또는 권한 철회와 동시에 새 token이 다시 등록될 수 있다.
- Analysis: 구독은 권한과 로그인 상태가 확인된 동기화 시점에 시작하고, unregister가 구독을 먼저 취소해야 한다.
- Action: 권한 허용 후 구독을 시작하고 unregister 순서를 구독 취소, backend 삭제, Firebase 삭제, auto-init 해제, local 삭제로 고정했다.
- Result: 인증 종료 후 refresh event가 token을 재등록하는 경로를 닫았다.

### 3. 전체 Flutter test의 기존 root harness 실패

- Problem: 첫 `flutter test`에서 `test/widget_test.dart`만 `No ProviderScope found`로 실패했다.
- Analysis: 앱 루트가 push provider를 읽는 `ConsumerStatefulWidget`으로 변경됐지만 기존 smoke test는 앱을 `ProviderScope` 없이 직접 생성했다.
- Action: smoke test를 실제 `main.dart`와 같은 `ProviderScope` 구조로 수정했다.
- Result: 재실행한 전체 178개 Flutter test가 통과했다.

### 4. 공개 테스트 발송 endpoint의 권한 부재

- Problem: 실제 발송을 위한 공개 endpoint를 추가하면 현재 없는 ADMIN 권한 모델을 우회하게 된다.
- Analysis: #175가 관리자 권한과 감사 정책을 별도 결정하도록 열려 있으며, 일반 사용자 API로 테스트 발송을 노출하면 오용 위험이 있다.
- Action: 인증된 사용자 token 등록 API와 내부 `PushNotificationService.sendToUser`까지만 구현하고 공개 발송 endpoint는 추가하지 않았다.
- Result: 서버 도메인은 Firebase Admin 발송과 invalid token 정리를 지원하며, 운영 endpoint는 ADMIN 권한 결정 뒤 연결할 수 있다.

### 5. Token refresh와 로그아웃 경합

- Problem: refresh callback에서 시작한 등록 요청은 stream 구독을 취소해도 이미 실행 중일 수 있어, 로그아웃 삭제 뒤 새 token이 다시 저장될 수 있다.
- Analysis: 등록, 권한 동기화, 해제 작업이 같은 사용자 기기에서 동시에 실행되지 않게 순서를 보장해야 한다.
- Action: push token lifecycle 작업을 단일 queue로 직렬화하고, 설정 누락 상태에서도 이전 build가 저장한 token의 backend/local 삭제는 계속하도록 했다.
- Result: 진행 중 refresh 등록 완료 뒤 unregister가 마지막에 실행되는 순서를 테스트로 검증했다.

## 실행한 검증

```powershell
cd frontend
flutter test
```

- 첫 실행: root smoke test 1개 실패, 177개 통과
- 최종 재실행: 181개 통과

```powershell
cd frontend
flutter analyze
```

- 결과: 성공, `No issues found`

```powershell
cd frontend
flutter build web --profile
```

- 결과: 성공
- 확인 내용: Firebase 설정과 Web push service worker가 없어도 push 비활성 상태로 Web build 가능
- 기존 경고: secure storage와 geolocator Web package는 Wasm과 호환되지 않음

```powershell
cd frontend
flutter build apk --debug
```

- 결과: 성공
- 산출물: `frontend/build/app/outputs/flutter-apk/app-debug.apk`
- 기존 경고: Built-in Kotlin 전환 필요. 별도 담당 PR #134와 겹치므로 이 이슈에서 수정하지 않음

```powershell
cd backend
.\gradlew.bat clean test
```

- 결과: 성공
- 테스트: 346개 통과, 실패/오류/skip 0
- 확인 내용: V21 migration, push service/controller, 전체 backend 회귀

```powershell
git diff --check
```

- 결과: 성공

## 실행하지 못한 검증

- Android/iOS 실제 기기 FCM 수신: Firebase App ID, APNs key, service account와 실제 기기가 제공되지 않음
- iOS build: 현재 실행 환경이 Windows이므로 Xcode build 불가
- Firebase Admin 실제 외부 발송: service account와 등록된 실제 device token이 없음

## 남은 리스크

- #176의 실제 기기 수신 완료 조건은 `agents_docs/FCM_SETUP_GUIDE.md` 절차에 따라 외부 Firebase 설정 후 확인해야 한다.
- iOS `aps-environment`의 실제 배포 값은 Apple provisioning profile과 배포 signing에서 최종 확인해야 한다.
- 현재 Firebase Admin SDK의 registration-token targeting API는 upstream에서 deprecated 표시가 있으므로 향후 Firebase Installations ID 기반 발송 정책을 검토해야 한다.
- 공개 운영 발송 API는 #175 ADMIN 권한 모델과 감사 로그 정책이 확정될 때까지 제공하지 않는다.

## 다음 작업

- Firebase 프로젝트에 Android/iOS 앱과 APNs key를 등록하고 실제 기기 QA 표를 채운다.
- 실제 수신 결과를 #176에 남긴 뒤 완료 체크리스트를 닫는다.
- #175에서 ADMIN 권한, 발송 endpoint, 감사 로그 정책을 함께 확정한다.
