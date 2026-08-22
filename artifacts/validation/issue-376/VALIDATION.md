# Issue 376 Validation

## 작업 목표

- FlutterFire CLI가 생성하는 `DefaultFirebaseOptions.currentPlatform` 구조로 FCM 초기화 코드를 정리한다.
- Android/iOS에서만 FCM을 활성화하고 Web에서는 임의로 활성화하지 않는다.
- 실제 Firebase API key와 플랫폼 credential 파일은 Git에 남기지 않는다.

## 진행 과정

1. 기존 `FirebasePushInitializer`가 `AppEnvironment`의 `FIREBASE_*` 값을 직접 읽어 `FirebaseOptions`를 만들던 구조를 확인했다.
2. `frontend/lib/firebase_options.dart`를 도입해 `DefaultFirebaseOptions.currentPlatform`을 사용하도록 초기화 흐름을 변경했다.
3. PR Static Review에서 `firebase_options.dart`의 실제 Android API key가 Semgrep에 걸려 실패했다.
4. 실제 API key는 Git에 두지 않도록 `firebase_options.dart`를 `String.fromEnvironment(...)` 기반의 안전한 형태로 정리했다.
5. `google-services.json`, `GoogleService-Info.plist`는 실제 플랫폼 설정 파일이므로 Git 추적에서 제외하고 로컬/배포 환경 전용으로 유지했다.
6. `firebase.json`은 API key나 private key가 아니라 FlutterFire 프로젝트/app 매핑 메타데이터이므로 팀 재현성을 위해 Git에 유지했다.

## 문제와 해결

### Semgrep API key 감지

- 문제: FlutterFire가 생성한 `firebase_options.dart`에 실제 Firebase API key가 들어가 PR Static Review가 실패했다.
- 판단: Firebase Web/API key는 엄밀한 서버 비밀키는 아니지만, 현재 저장소 정책은 API key 형태 문자열을 error로 차단한다.
- 해결: Semgrep rule을 완화하지 않고, 저장소에는 실제 값이 없는 `firebase_options.dart`만 남기도록 변경했다.

### `firebase.json` 처리

- 문제: 처음에는 생성 파일이라는 이유로 `firebase.json`도 제외하려 했다.
- 재검토: `firebase.json`은 FlutterFire CLI의 공통 프로젝트/app 매핑 정보이며 private key를 포함하지 않는다.
- 해결: `firebase.json`은 커밋 대상으로 유지하고, 실제 credential 파일만 제외했다.

## 변경 파일 요약

- `frontend/lib/features/push/data/firebase_push_initializer.dart`
  - foreground/background 초기화 모두 `DefaultFirebaseOptions.currentPlatform` 사용.
- `frontend/lib/firebase_options.dart`
  - 실제 Firebase 값을 제거하고 `--dart-define` 기반 주입 구조로 정리.
- `frontend/lib/app/config/app_environment.dart`
  - Firebase 세부 값 검증 대신 Android/iOS 모바일 플랫폼 여부만 판단.
- `frontend/.env.example`
  - FCM 빌드 주입용 Firebase 환경 변수 이름 추가.
- `frontend/firebase.json`
  - FlutterFire 공통 앱 매핑 정보 유지.
- `agents_docs/FCM_SETUP_GUIDE.md`
  - 실제 키/플랫폼 파일은 Git에 커밋하지 않는 운영 절차 반영.

## 검증 결과

- `cd frontend && flutter analyze`
  - 1차 실행은 `ios/Flutter/ephemeral/Packages/.packages` 임시 캐시 정리 실패로 중단됐다.
  - 해당 폴더는 Flutter가 다시 생성하는 빌드 산출물이므로 임시 위치로 옮긴 뒤 재실행했다.
  - 결과: 통과. `No issues found!`
- `cd frontend && flutter test test/features/push/push_notification_service_test.dart test/features/push/push_route_resolver_test.dart test/app/app_push_notification_test.dart`
  - 결과: 통과. `All tests passed!`
- PR Static Review
  - 실제 Firebase API key가 PR diff에 남지 않도록 수정했다.
  - 최종 확인은 GitHub Actions 재실행 결과로 판단한다.

## 남은 리스크

- 실제 FCM 수신은 Android/iOS 실기기와 Firebase Console 또는 운영 발송 경로로 별도 QA가 필요하다.
- 릴리즈 빌드에서는 `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID`, `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_STORAGE_BUCKET`을 CI secret 또는 `.env`로 주입해야 한다.
