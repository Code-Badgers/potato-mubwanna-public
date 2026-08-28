# Issue #443 검증 기록

## 작업 목표

Firebase Admin FCM 발송을 production에서 켤 수 있도록 GitHub Production 설정과 EC2
`deploy/.env` 동기화를 연결하고, backend 컨테이너 전달 여부를 값 노출 없이 확인한다.

## 확인한 기존 구조

- Flutter는 `DefaultFirebaseOptions.currentPlatform` 기반으로 Android/iOS FCM을 초기화하고
  backend에 registration token을 등록한다.
- Backend는 `FirebaseAdminConfiguration`에서 Firebase Admin SDK를 조건부로 생성한다.
- 방문 인증, 미션 완료, 대표 감자 레벨업 이벤트는 기존 `AFTER_COMMIT` push 흐름을 재사용한다.
- `deploy/compose.prod.yml`은 Firebase 관련 네 개 환경변수를 backend 컨테이너에 전달한다.
- `deploy/.env.example`은 비어 있는 기본값만 유지한다.

## 변경 내용

- `FIREBASE_SERVICE_ACCOUNT_BASE64`를 기존 RSA/OAEP + SSM Secret 동기화 allowlist에 추가했다.
- Firebase service account Secret 전용 wrapper를 추가했다.
- `FIREBASE_ADMIN_ENABLED=true`, `FIREBASE_PROJECT_ID=potato-mubwanna-prod`만 원격 `.env`에서
  교체하는 비밀값 비사용 설정 동기화 스크립트를 추가했다.
- 배포 스크립트가 Firebase 설정 변수의 존재 조건만 검사하도록 했다.
- Firebase Admin 초기화 실패 시 원인은 남기되 service account 내용이나 arbitrary SDK 오류 메시지는
  로그에 남기지 않도록 했다.
- 기존 Production Environment 등록 방법과 실제 기기 QA 절차를 문서화했다.

## 실행한 검증

| 명령 | 결과 |
| --- | --- |
| `bash -n deploy/*.sh deploy/tests/*.sh` | 통과 |
| `bash deploy/tests/sync-tour-api-secret-test.sh` | 통과: 기존 변수 보존, Firebase Secret 암호화 동기화, Firebase 설정 교체, 평문 유출 검사 |
| `bash deploy/tests/deploy-backend-test.sh` | 통과: Firebase 환경변수 전달 조건과 자동 롤백 시나리오 |
| `cd backend && ./gradlew test --tests com.gamjamubwatna.push.infrastructure.FirebaseAdminConfigurationTest` | 통과: 4 tests |
| `git diff --check` | 통과 |

초기 Firebase 설정 테스트는 Spring의 최심부 `IOException` 메시지를 직접 비교해 1회 실패했다.
실제 startup failure의 안전한 설정 오류 메시지를 검증하도록 수정한 뒤 통과했다. 로컬 macOS에서
배포 shell 테스트를 재현하기 위해 `sed -i.bak` 방식도 함께 적용했다.

## Production 설정 상태

실제 GitHub Production Secret 값이나 운영 서버 값을 조회·출력하지 않았다.

- `FIREBASE_ADMIN_ENABLED`: GitHub Production Variable에 `true` 등록 필요
- `FIREBASE_PROJECT_ID`: GitHub Production Variable에 `potato-mubwanna-prod` 등록 필요
- `FIREBASE_SERVICE_ACCOUNT_BASE64`: GitHub Production Secret에 등록 필요
- `PUSH_TOKEN_STALE_DAYS`: Compose 기본값은 `60`; 운영 `.env`에 별도 값이 있으면 `60`인지 확인 필요

현재 환경에서는 실제 service account와 실기기를 사용한 FCM 발송을 실행하지 않았다.

## 남은 리스크와 후속 확인

- Production Secret/Variables 등록 후 GitHub Actions `Backend Production Deploy`를 실행해야 한다.
- 배포 후 컨테이너 환경변수는 값이 아닌 존재 여부만 확인해야 한다.
- 실제 기기에서 로그인 → 권한 허용 → token 등록 → 방문 인증/미션 완료 → foreground/background/
  terminated 수신 → 알림 클릭 라우팅 → 로그아웃 token 삭제를 확인해야 한다.
- 현재 인증 토큰으로 workflow 파일 push를 시도했을 때 GitHub가 `workflow` scope 부족을 거부했다.
  비workflow 커밋은 원격에 반영했으며, workflow 변경 커밋은 별도 로컬 커밋으로 남길 예정이다.
