# Issue #185 Validation

## 작업 요약

- 이슈: #185 `[FE/BE] test: 랠리북 보상 수령과 쿠폰 사용 통합 검증`
- 브랜치: `test/185-reward-coupon-flow`
- 담당 영역: 랠리북 보상 수령 후 화면 상태 동기화, 쿠폰 사용 중복 입력 방지, 스탬프 보상 쿠폰 동시 사용 통합 검증
- 제외 범위: #176 FCM 실기기 검증, #182 방문 인증 실기기 QA, #133/#134 Android Built-in 전환, 관리자 정책
- 목표: 스탬프 보상 수령부터 보상 내역·쿠폰 발급·QR 사용 완료까지 한 흐름을 자동화 테스트와 실제 앱 실행으로 검증한다.

## 변경 파일

- `frontend/lib/features/stamp/application/stamp_book_controller.dart`: 보상 수령 성공 시 `rewardHistoryProvider`도 무효화한다.
- `frontend/lib/features/coupon/presentation/screen/coupon_screen.dart`: 확인창을 여는 동안 쿠폰 사용 흐름을 잠가 중복 확인창과 중복 요청을 막는다.
- `frontend/test/features/stamp/stamp_book_controller_test.dart`: 랠리북·쿠폰·보상 내역 캐시의 동시 갱신을 검증한다.
- `frontend/test/features/coupon/coupon_screen_test.dart`: 같은 프레임에 사용 콜백이 두 번 들어와도 확인창과 사용 요청이 한 번만 실행되는지 검증한다.
- `backend/src/test/java/com/gamjamubwatna/stamp/application/StampRewardFlowIntegrationTest.java`: 스탬프 보상 쿠폰에 동시 사용 요청을 보내 한 요청만 성공하는지 검증한다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: 없음
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 없음
- 외부 API: 새 연동 없음

## 자동화 검증

- `cd backend && .\gradlew.bat test`
  - 성공
  - 347개 테스트 통과, 실패 0, 오류 0, 건너뜀 0
- `cd frontend && flutter analyze`
  - 성공, `No issues found`
- `cd frontend && flutter test`
  - 성공, 최신 `main` 재배치 후 196개 테스트 통과
- `cd frontend && flutter build web`
  - 성공
  - 기존 `flutter_secure_storage_web`, `geolocator_web` Wasm 비호환 경고만 출력
- `git diff --check`
  - 성공

## 실제 앱 실행 검증

- 로컬 PostgreSQL 16과 Redis 7을 실행하고 Spring Boot 애플리케이션을 운영 설정으로 기동했다.
- Flyway V1~V21 마이그레이션이 빈 PostgreSQL 스키마에 모두 적용되고 `/api/actuator/health`가 `UP`을 반환했다.
- QA 사용자에게 정상 JWT refresh 세션과 스탬프 6개를 준비한 뒤 Flutter 웹 애플리케이션을 실행했다.
- 랠리북의 `6개 보상 받기`를 더블클릭해도 보상 내역 1건과 쿠폰 1장만 생성됐다.
- 보상 내역을 먼저 조회해 캐시한 상태에서 스탬프를 12개로 늘리고 두 번째 보상을 수령했다.
- 보상 내역 화면 재진입 시 3,000원권과 5,000원권 기록 2건이 즉시 표시돼 캐시 무효화를 확인했다.
- 5,000원권 상세에서 QR을 표시하고 사용 완료를 처리했다.
- 사용 후 보상함이 `사용 가능 1 / 사용 완료 1`로 바뀌고 상세 화면에 사용일이 표시됐다.
- 데스크톱 1280x720과 모바일 390x844에서 목록·상세·하단 내비게이션의 겹침이나 오버플로가 없었다.
- 브라우저 warning/error 0건, 백엔드 `ERROR`/예외 로그 0건이었다.

## 회귀 테스트가 잡은 문제

1. 첫 테스트 실행에서 `StampRewardClaimController`에 보상 내역 갱신 콜백이 없어 컴파일 단계에서 실패했다.
2. 쿠폰 사용 콜백을 같은 프레임에 두 번 호출하면 확인창이 2개 열리는 것을 재현했다.
3. 첫 수정은 확인창 뒤 화면에 무한 로딩 애니메이션을 표시해 `pumpAndSettle`이 끝나지 않았다.
4. 확인 중 상태와 서버 사용 처리 상태를 분리한 뒤 관련 테스트와 전체 테스트가 통과했다.

## 산출물

- 검증 기록: `artifacts/validation/issue-185/VALIDATION.md`
- 캐시 갱신 화면: `artifacts/validation/issue-185/reward-history-cache-refresh.png`
- 쿠폰 사용 완료 화면: `artifacts/validation/issue-185/coupon-used-detail.png`
- 모바일 보상함 화면: `artifacts/validation/issue-185/coupon-list-mobile.png`

## 남은 리스크

- 실제 카카오 로그인은 외부 계정과 앱 키 대신 로컬 QA용 JWT refresh 세션으로 대체했다.
- 카카오 지도 키가 없는 로컬 환경이라 지도 SDK 자체는 이번 보상 흐름 검증 범위에 포함하지 않았다.
- 실제 매장 단말이 QR을 스캔하는 흐름은 제공되지 않아, 앱의 `사용 완료 처리`와 백엔드 서명 payload 검증 경로를 사용했다.

## 다음 작업

- 이어서 실행할 명령: `git diff && git status --short`
- 확인해야 할 파일: `frontend/lib/features/stamp/application/stamp_book_controller.dart`, `frontend/lib/features/coupon/presentation/screen/coupon_screen.dart`
- 조율이 필요한 사람 또는 이슈: #182 방문 인증 QA와 파일 범위가 겹치지 않으며 별도 조율 없음
