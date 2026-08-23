# Issue #381 Firebase Admin FCM 운영 발송 연결 검증

## 작업 범위

- Backend Firebase Admin 활성화 구조를 점검했다.
- 운영 Firebase 프로젝트 `potato-mubwanna-prod`를 사용할 수 있도록 환경 설정 이름을 정리했다.
- 서비스 계정 JSON을 Git에 넣지 않고 `FIREBASE_SERVICE_ACCOUNT_BASE64` secret으로 주입할 수 있게 했다.
- 기존 `GOOGLE_APPLICATION_CREDENTIALS` 파일 경로 방식은 로컬/서버 외부 파일 방식으로 유지했다.
- FCM token 등록, refresh, 삭제, 무효 token 정리, 발송 실패 흐름의 기존 구현과 테스트를 확인했다.

## PARR 기록

### Problem

현재 `FIREBASE_ADMIN_ENABLED=false`가 기본값이라 앱은 FCM token을 만들 수 있어도 서버는 실제 Firebase 발송을 하지 않는다. 또한 운영 Docker Compose에는 Firebase project id만 있고 서비스 계정 credential을 안전하게 주입하는 통로가 없었다.

### Action

- `push.firebase.service-account-base64` 설정을 추가했다.
- 운영 compose와 예시 env에 `FIREBASE_SERVICE_ACCOUNT_BASE64`를 추가했다.
- Firebase Admin 설정에서 base64 secret이 있으면 `GoogleCredentials.fromStream`으로 읽고, 없으면 기존처럼 Application Default Credentials를 사용하게 했다.
- project id 누락, 잘못된 base64 secret, gateway 발송 실패에 대한 테스트를 추가했다.

### Result

- 운영에서는 `FIREBASE_ADMIN_ENABLED=true`, `FIREBASE_PROJECT_ID=potato-mubwanna-prod`, `FIREBASE_SERVICE_ACCOUNT_BASE64=<secret>`만 준비하면 실제 Firebase Admin 발송 경로가 열린다.
- local/test는 기본값이 계속 false라 Firebase credential 없이도 테스트와 서버 시작이 가능하다.
- Firebase 발송 실패 시 token을 잘못 삭제하지 않는 것을 테스트로 확인했다.

### Reflection

서비스 계정 JSON은 Firebase client 설정과 달리 private key를 포함하므로 저장소에 둘 수 없다. AWS SSM 배포 구조를 유지하면서 운영 서버의 `deploy/.env` 또는 동등한 secret 주입 방식으로 base64 값을 전달하는 방식이 가장 작은 변경으로 안전하다.

## 현재 FCM Backend 구조

1. Flutter 앱이 FCM token을 발급한다.
2. 로그인 사용자가 `POST /api/users/me/push-tokens`로 token을 등록한다.
3. token refresh 시 `previousToken`을 보내 이전 token을 정리한다.
4. 로그아웃/권한 철회는 `DELETE /api/users/me/push-tokens`를 호출한다.
5. 회원 탈퇴 시 사용자 token은 FK cascade로 삭제된다.
6. 방문 인증, 미션 완료, 대표 감자 레벨업 이벤트가 커밋 이후 push listener로 전달된다.
7. Firebase Admin이 활성화되어 있으면 `FirebaseMessaging.sendEachForMulticast`로 발송한다.
8. FCM이 무효 token으로 판정한 token은 `deleteByTokenIn`으로 삭제한다.

## Flutter token 등록과 auto-init 확인

- 앱 시작 시 Firebase 초기화 후 `FirebaseMessaging.instance.setAutoInitEnabled(false)`로 자동 token 생성을 막는다.
- 사용자가 알림 권한을 허용하면 `PushNotificationService.synchronize()`에서 `setAutoInitEnabled(true)`를 호출한 뒤 token을 읽어 서버에 등록한다.
- `FirebaseMessaging.onTokenRefresh`는 새 token을 서버에 등록하고, 로컬에 저장된 이전 token을 `previousToken`으로 전달한다.
- 로그아웃, 회원 탈퇴, 알림 권한 거부/철회 흐름에서는 서버 token 삭제와 로컬 token 삭제가 호출된다.
- 따라서 `setAutoInitEnabled(false)` 이후 다시 `true`로 바뀌는 흐름은 존재한다.

## 운영 환경 설정

필수:

```txt
FIREBASE_ADMIN_ENABLED=true
FIREBASE_PROJECT_ID=potato-mubwanna-prod
FIREBASE_SERVICE_ACCOUNT_BASE64=<base64-encoded-service-account-json>
```

선택:

```txt
PUSH_TOKEN_STALE_DAYS=60
GOOGLE_APPLICATION_CREDENTIALS=<external-file-path>
```

`FIREBASE_SERVICE_ACCOUNT_BASE64`와 `GOOGLE_APPLICATION_CREDENTIALS`를 동시에 둘 필요는 없다. 운영 Docker 환경에서는 base64 secret 방식을 우선 권장한다.

## 실기기 최종 확인 절차

1. 운영 서버에 Firebase secret을 주입하고 `FIREBASE_ADMIN_ENABLED=true`로 배포한다.
2. Android/iOS 실제 기기에서 앱을 설치한다.
3. 로그인 후 알림 권한을 허용한다.
4. DB `user_push_tokens`에 token이 저장됐는지 확인한다.
5. 방문 인증, 미션 완료, 대표 감자 레벨업 중 하나를 발생시킨다.
6. foreground, background, terminated 상태에서 알림 수신과 탭 이동을 확인한다.
7. 로그아웃 또는 알림 권한 철회 후 token 삭제를 확인한다.

## 실행한 테스트

```txt
./gradlew test --tests '*push*'
./gradlew test
```

결과: 모두 성공
