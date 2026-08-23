# FCM Setup Guide

이 문서는 저장소에 비밀값을 추가하지 않고 Android/iOS 푸시 등록, 발송, 수신을 검증하는 절차를 정의한다.

## 1. Firebase 프로젝트 등록

Firebase Console의 동일 프로젝트에 다음 앱을 등록한다.

| 플랫폼 | package / bundle id | 저장할 값 |
| --- | --- | --- |
| Android | `com.gamjamubwatna.frontend` | Android App ID |
| iOS | `com.gamjamubwatna.frontend` | iOS App ID |

- Cloud Messaging API를 활성화한다.
- iOS 앱은 Apple Developer의 APNs Authentication Key를 Firebase Console에 업로드한다.
- iOS Runner target에 Push Notifications와 Background Modes의 `Background fetch`, `Remote notifications`가 켜져 있는지 확인한다.
- Firebase 설정 파일과 service account key는 Git에 커밋하지 않는다.
- Web push는 service worker와 VAPID 정책이 확정될 때까지 지원하지 않는다.

## 2. Flutter 실행 설정

Flutter 앱은 FlutterFire CLI가 생성한 `frontend/lib/firebase_options.dart`의
`DefaultFirebaseOptions.currentPlatform`을 사용한다.

- Android/iOS에서만 FCM을 초기화한다.
- Web push는 service worker와 VAPID 정책이 확정될 때까지 지원하지 않는다.
- Firebase 초기화에 실패해도 앱 시작은 계속하고 push만 비활성화한다.
- FCM token 자동 생성은 기본적으로 비활성화되어 있다. 사용자가 알림 권한을 허용하면 앱이 자동 초기화를 켜고 token을 등록한다.
- Firebase client 설정값은 일반 앱 식별 설정이지만, 서비스 계정 JSON, private key, APNs key는 절대 Git에 커밋하지 않는다.

## 3. Backend 실행 설정

Firebase Admin은 기본적으로 비활성화한다. 운영에서 실제 발송을 켤 때만
`FIREBASE_ADMIN_ENABLED=true`로 바꾼다.

운영 Firebase 프로젝트:

```txt
potato-mubwanna-prod
```

운영 권장값:

```env
FIREBASE_ADMIN_ENABLED=true
FIREBASE_PROJECT_ID=potato-mubwanna-prod
FIREBASE_SERVICE_ACCOUNT_BASE64=<base64-encoded-service-account-json>
PUSH_TOKEN_STALE_DAYS=60
```

로컬 파일 기반 실행도 가능하다. 이 경우 `FIREBASE_SERVICE_ACCOUNT_BASE64`를 비우고
`GOOGLE_APPLICATION_CREDENTIALS`에 저장소 밖의 절대 경로를 지정한다.

```powershell
$env:FIREBASE_ADMIN_ENABLED = "true"
$env:FIREBASE_PROJECT_ID = "potato-mubwanna-prod"
$env:GOOGLE_APPLICATION_CREDENTIALS = "<absolute-service-account-key-path>"
$env:PUSH_TOKEN_STALE_DAYS = "60"
.\gradlew.bat bootRun
```

- 운영 Docker Compose에는 `FIREBASE_SERVICE_ACCOUNT_BASE64`가 전달된다.
- GitHub Actions는 SSM으로 EC2의 배포 스크립트를 실행한다. 실제 값은 운영 서버의 `deploy/.env` 또는 동일한 서버 secret 관리 방식에만 보관한다.
- service account key 경로와 파일 내용은 로그, 이슈, PR, 저장소에 남기지 않는다.
- Firebase Admin이 필요 없는 환경은 `FIREBASE_ADMIN_ENABLED=false`를 유지한다.
- 활성화했는데 project ID 또는 자격 증명이 없으면 서버는 즉시 시작 실패해 잘못된 운영 설정을 드러낸다.
- 사용자별 테스트 발송은 backend의 `PushNotificationService.sendToUser`를 사용한다. 공개 테스트 endpoint는 ADMIN 권한 모델이 확정되기 전까지 제공하지 않는다.

## 4. Backend 발송 흐름

현재 서버에서 실제 FCM 발송으로 이어지는 이벤트는 다음이다.

| 이벤트 | 발행 위치 | 목적지 |
| --- | --- | --- |
| 방문 인증 완료 | `VisitVerificationService.verifyVisit` | `SPOT` |
| 미션 완료 | `MissionService.publishMissionCompletion` | `MISSIONS` |
| 대표 감자 레벨업 | `PotatoCommandService.publishLevelUp` | `POTATOES` |

흐름:

```txt
Domain service
  -> PushEventPublisher
  -> PushRequestedEventListener(AFTER_COMMIT)
  -> PushNotificationService
  -> PushMessageGateway
  -> FirebaseMessaging.sendEachForMulticast
```

- `FIREBASE_ADMIN_ENABLED=false`이면 `DisabledPushMessageGateway`가 사용되어 발송만 skip된다.
- Firebase가 token을 `UNREGISTERED` 또는 `INVALID_ARGUMENT`로 응답하면 해당 registration token을 삭제한다.
- Firebase 발송 중 예외가 발생해도 이벤트 listener가 경고 로그만 남기므로 미션/방문/성장 트랜잭션은 되돌리지 않는다.

## 5. 실제 기기 QA

Android와 iOS 실제 기기에서 각각 아래 순서로 검증한다.

1. 앱을 신규 설치하고 로그인 전에는 `user_push_tokens`가 생성되지 않는지 확인한다.
2. 로그인하고 알림 권한을 허용한 뒤 해당 사용자의 token 한 건이 등록되는지 확인한다.
3. 앱을 재실행한 뒤 같은 token 등록이 중복 row를 만들지 않는지 확인한다.
4. Firebase token refresh 후 이전 token이 제거되고 새 token만 남는지 확인한다.
5. Firebase Console 또는 `PushNotificationService.sendToUser`로 foreground 메시지를 보내 앱 내 알림이 표시되는지 확인한다.
6. background와 terminated 상태에서 알림을 탭해 아래 data payload 경로로 이동하는지 확인한다.
7. 알림 권한을 철회한 뒤 앱을 foreground로 복귀해 서버와 기기 token이 삭제되는지 확인한다.
8. 다시 권한을 허용한 뒤 token이 재발급·등록되는지 확인한다.
9. 로그아웃과 회원 탈퇴 후 token이 남지 않는지 확인한다.
10. Firebase 설정 없이 로컬 앱과 Web을 실행해 push만 비활성화되고 앱이 정상 시작하는지 확인한다.

라우팅 data payload:

```json
{"destination":"MISSIONS"}
{"destination":"COUPONS"}
{"destination":"STAMPS"}
{"destination":"MAP"}
{"destination":"SPOT","destinationId":"1"}
```

알 수 없는 `destination`, 숫자가 아니거나 양수가 아닌 `destinationId`는 화면 이동 없이 무시되어야 한다.

## 6. 완료 증빙

실제 기기 QA 결과에는 다음 정보만 기록한다.

- 플랫폼과 OS 버전
- 앱 build SHA
- foreground/background/terminated 수신 성공 여부
- 탭 이동 목적지
- 권한 철회와 로그아웃 후 token row 삭제 여부
- 실패 시 Firebase message ID와 시각

registration token 원문, service account key, APNs key는 증빙에 포함하지 않는다.
