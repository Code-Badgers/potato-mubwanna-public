# Issue #100 검증 기록

## 작업 목표

HealthKit/Health Connect에서 읽은 오늘 걸음 수를 서버에 저장하고, 저장된 일일 활동 집계가 감자 성장 요약 API에 반영되도록 한다.

## 진행 내용

### 1. API 계약 문서화

- `agents_docs/07_api_specification.md`에 `PUT /api/potatoes/me/activity/daily` 명세를 추가했다.
- 성장 요약 조회는 저장된 일일 활동 집계를 우선 사용하도록 명시했다.

### 2. Backend 구현

- `V14__create_user_daily_activities.sql` migration을 추가했다.
- `UserDailyActivity`, `ActivitySource`, `UserDailyActivityRepository`를 추가했다.
- `PotatoCommandService#syncDailyActivity`를 추가해 같은 사용자/날짜/출처 조합은 upsert 처리한다.
- `PotatoQueryService#getGrowthSummary`가 저장된 활동 집계를 우선 사용하도록 변경했다.
- 저장된 활동이 없으면 #98 MVP 기본값을 유지한다.
- Controller, Service 테스트를 추가했다.

### 3. Frontend 구현

- `ApiPaths.potatoDailyActivity`를 추가했다.
- `StepCountSnapshot`에 날짜, 걸음 수, 추정 거리, 출처를 담도록 확장했다.
- iOS는 `HEALTH_KIT`, Android는 `HEALTH_CONNECT` 출처로 동기화한다.
- Health 플러그인에서 얻는 값이 걸음 수 중심이므로 거리는 `0.7m/step`으로 추정한다.
- 감자 성장 요약 provider는 기기 걸음 수를 읽으면 서버에 먼저 동기화한 뒤 성장 요약을 다시 조회한다.
- 동기화 실패는 화면 진입을 막지 않고 서버의 마지막 집계값을 사용한다.

## PAAR 트러블슈팅

### P: 실제 JWT가 없는 k6 환경에서 인증 API 성능 측정이 애매했다

`PUT /api/potatoes/me/activity/daily`는 로그인 사용자의 JWT가 있어야 정상 저장된다. 로컬 H2 서버에서 카카오 로그인과 JWT 발급까지 재현하면 #100 범위가 인증 통합 검증으로 커진다.

### A: 비즈니스 로직은 JUnit/WebMvc로 검증하고 k6는 인증 게이트 smoke로 분리했다

저장/upsert/검증 실패/성장 요약 집계는 테스트 코드로 확인했다. k6는 HTTP 서버가 뜨고 인증 필요 경로가 JSON 401/403을 안정적으로 반환하는지와 응답 지연을 확인했다.

### R: k6 smoke 통과

최종 k6 결과는 checks 100%, failed rate 0%, p95 13.37ms로 통과했다. 실제 인증 사용자 부하 테스트는 시드 계정과 JWT 발급 자동화가 준비되면 추가해야 한다.

### P: 거리 데이터가 Health reader에서 직접 오지 않는다

현재 `health` 기반 reader는 오늘 걸음 수를 안정적으로 읽는 것이 우선이며, 플랫폼별 거리 데이터까지 함께 집계하려면 추가 권한과 데이터 타입 검증이 필요하다.

### A: MVP 동기화에서는 0.7m/step 추정값을 사용했다

서버가 거리 기반 주/월 집계를 계산해야 하므로, 프론트에서 걸음 수를 `0.7m/step`으로 환산해 `distanceMeters`로 저장한다. 추정값이라는 점은 validation에 명시했다.

### R: 성장 요약은 저장 데이터 기반으로 전환됐다

동기화가 성공하면 다음 성장 요약 조회에서 저장된 `todaySteps`, 주/월 거리가 반영된다. 동기화 실패 시에는 기존 서버 집계 또는 MVP fallback이 유지된다.

## 실행한 검증

```bash
cd backend && ./gradlew test --tests 'com.gamjamubwatna.potato.*'
```

- 결과: 성공

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze
```

- 결과: 성공, No issues found

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter test test/features/potato/potato_collection_screen_test.dart
```

- 결과: 성공, 5 tests passed

```bash
cd backend && ./gradlew bootTestRun --args='--server.port=18080 --spring.datasource.url=jdbc:h2:mem:issue100;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH --spring.datasource.driver-class-name=org.h2.Driver --spring.datasource.username=sa --spring.datasource.password= --spring.data.redis.host=localhost --external.tour-api.import-on-startup=false'
artifacts/local-runtime/tools/bin/k6 run artifacts/validation/issue-100/k6-backend-step-sync-smoke.js
```

- 결과: 성공
- checks: 100.00%
- requests: 100
- failed rate: 0.00%
- avg duration: 11.13ms
- p95 duration: 13.37ms
- max duration: 155.76ms

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter build web --profile
```

- 결과: 성공

## 산출물

- `k6-backend-step-sync-smoke.js`
- `k6-backend-output.txt`
- `k6-backend-summary.json`
- `k6-backend-report.html`
- `k6-backend-report.png`
- `frontend-profile-build-output.txt`
- `frontend-profile-build-report.html`
- `frontend-profile-build-report.png`

## 남은 리스크

- 실제 인증 사용자 기반 k6 테스트는 JWT/시드 계정 준비 후 보강해야 한다.
- iOS/Android 실제 기기에서 HealthKit/Health Connect 권한 허용과 저장 동작을 최종 확인해야 한다.
- 거리 값은 `0.7m/step` 추정이므로, 추후 실제 거리 데이터 타입을 읽도록 고도화하는 것이 좋다.
- 백그라운드 자동 동기화는 아직 제외 범위다.

## 다음 작업 제안

1. 감자 성장 write API와 대표 감자 레벨업 규칙 구현
2. 미션 걸음 인증이 `user_daily_activities`를 사용하도록 연결
3. 실제 기기에서 Health 권한/동기화 화면 검증 캡처 추가
