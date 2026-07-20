# Issue #98 검증 기록

## 작업 목표

감자 도감의 `오늘의 감자걸음` 카드를 하드코딩 값이 아니라 백엔드 성장 요약 API에서 내려오는 값으로 표시한다.

- Backend: `GET /api/potatoes/me/growth-summary` API 추가
- Frontend: 감자 도감 카드에서 성장 요약 API 응답 표시
- 제외 범위: HealthKit/Google Fit/실시간 만보기 연동, 보상 지급 로직, 감자 성장 write API, 실제 디바이스 걸음 수 수집

## 진행 내용

### 1. API 계약 문서화

- `agents_docs/07_api_specification.md`에 `GET /api/potatoes/me/growth-summary` 명세를 먼저 추가했다.
- 응답 필드는 `todaySteps`, `dailyStepGoal`, `weeklyDistanceKm`, `monthlyDistanceKm`, `remainingDistanceKmForRepresentative`로 정의했다.

### 2. Backend 구현

- `PotatoGrowthSummaryResponse` DTO를 추가했다.
- `PotatoQueryService#getGrowthSummary`를 추가했다.
- MVP 단계에서는 실제 걸음 수 수집 전까지 서버 정책 기본값을 내려주고, 대표 감자의 남은 성장 거리만 DB의 `UserPotato` 상태에서 계산한다.
- `PotatoController`에 `/potatoes/me/growth-summary`를 추가했다.
- 서비스 테스트와 WebMvc 테스트를 추가했다.

### 3. Frontend 구현

- `ApiPaths.potatoGrowthSummary`를 추가했다.
- `PotatoGrowthSummary` 도메인 모델을 추가했다.
- `PotatoRepository#fetchGrowthSummary`와 `potatoGrowthSummaryProvider`를 추가했다.
- 감자 도감의 `오늘의 감자걸음` 카드는 provider 상태에 따라 로딩, 오류, 데이터 상태를 표시하도록 변경했다.
- 기존 위젯 테스트에 성장 요약 provider override를 추가해 카드 표시가 API 계약을 따르는지 확인했다.

## PAAR 트러블슈팅

### P: 인증 성장 요약 API를 k6로 어떻게 측정할지 애매했다

성장 요약 API는 로그인 사용자의 JWT가 있어야 정상 데이터를 반환한다. 로컬 H2 테스트 서버에서 실제 카카오 로그인/JWT 발급까지 재현하면 #98 범위가 인증 통합 검증으로 커져 버린다.

### A: 단위/WebMvc 테스트와 k6 smoke의 역할을 분리했다

비즈니스 응답과 남은 거리 계산은 JUnit/MockMvc로 검증했다. k6는 HTTP 서버 경로, 인증 게이트, JSON 응답, 지연 시간을 확인하는 smoke 성능 테스트로 제한했다.

### A: k6의 기본 실패 집계가 401을 실패로 처리했다

첫 실행에서는 401이 기대 동작인데도 `http_req_failed=100%`로 집계되어 threshold가 깨졌다. `http.setResponseCallback(http.expectedStatuses(200, 401, 403))`를 추가해 인증 필요 응답을 기대 상태로 선언했다.

### R: 재실행 결과 smoke 기준 통과

최종 k6 결과는 checks 100%, failed rate 0%, p95 3.09ms로 통과했다. 단, 인증된 실제 사용자 데이터 조회 성능은 JWT/시드 사용자 기반 성능 시나리오가 준비된 후 별도 측정이 필요하다.

## 실행한 검증

```bash
cd backend && ./gradlew test --tests 'com.gamjamubwatna.potato.*'
```

- 결과: 성공
- 목적: 감자 성장 요약 서비스/컨트롤러 회귀 검증

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter test test/features/potato/potato_collection_screen_test.dart
```

- 결과: 성공, 5 tests passed
- 목적: 감자 도감 카드/API provider 연동 후 UI 회귀 검증

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze
```

- 결과: 성공, No issues found
- 참고: 첫 병렬 실행은 Flutter startup lock/ephemeral 파일 삭제 충돌로 실패했으나, 단독 재실행에서 통과했다.

```bash
cd backend && ./gradlew bootTestRun --args='--server.port=18080 --spring.datasource.url=jdbc:h2:mem:issue98;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH --spring.datasource.driver-class-name=org.h2.Driver --spring.datasource.username=sa --spring.datasource.password= --spring.data.redis.host=localhost --external.tour-api.import-on-startup=false'
artifacts/local-runtime/tools/bin/k6 run artifacts/validation/issue-98/k6-backend-growth-smoke.js
```

- 결과: 성공
- checks: 100.00%
- requests: 100
- failed rate: 0.00%
- avg duration: 2.30ms
- p95 duration: 3.09ms
- max duration: 3.73ms

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter build web --profile
```

- 결과: 성공
- 목적: 감자 도감 화면 변경 후 profile web build 가능 여부 확인

## 산출물

- `k6-backend-growth-smoke.js`: k6 smoke 스크립트
- `k6-backend-output.txt`: k6 실행 로그
- `k6-backend-summary.json`: k6 원본 summary
- `k6-backend-report.html`: k6 요약 HTML
- `k6-backend-report.png`: k6 요약 이미지
- `frontend-profile-build-output.txt`: profile web build 로그
- `frontend-profile-build-report.html`: 프론트 빌드 요약 HTML
- `frontend-profile-build-report.png`: 프론트 빌드 요약 이미지

## 남은 리스크

- 현재 걸음 수와 주/월 거리 값은 실제 디바이스 API가 아니라 MVP 정책값이다.
- 인증된 실제 사용자 + 대표 감자 데이터 기반의 k6 성능 테스트는 JWT 생성/시드 계정 준비 후 별도 보강이 필요하다.
- 실제 iOS/Android 디바이스에서 HealthKit/Google Fit 또는 pedometer 연동을 붙이면 권한, 배터리, 백그라운드 수집 정책을 다시 검증해야 한다.

## 다음 작업 제안

1. HealthKit/iOS, Google Fit 또는 Android Health Connect 기반 걸음 수 수집 이슈 분리
2. 걸음 수 집계 저장 테이블과 일/주/월 조회 API 추가
3. 감자 성장 write API와 대표 감자 성장 레벨업 규칙 구현
4. 실제 기기에서 DevTools Performance/Android Studio Profiler로 프레임과 메모리 확인
