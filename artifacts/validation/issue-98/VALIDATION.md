# Issue #98 검증 기록

## 작업 목표

감자 도감의 `오늘의 감자걸음` 카드를 하드코딩 값이 아니라 백엔드 성장 요약 API에서 내려오는 값으로 표시한다.

- Backend: `GET /api/potatoes/me/growth-summary` API 추가
- Frontend: 감자 도감 카드에서 성장 요약 API 응답 표시
- Frontend: iOS HealthKit 또는 Android Health Connect에서 오늘 걸음 수를 읽어 카드에 반영
- 제외 범위: 백그라운드 걸음 수 동기화, Health 데이터 서버 저장, 보상 지급 로직, 감자 성장 write API

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

### 4. HealthKit/Health Connect 걸음 수 연결

- `health` 패키지를 추가했다.
- iOS `Info.plist`에 HealthKit 권한 문구를 추가하고 `Runner.entitlements`에 HealthKit capability를 연결했다.
- Android `AndroidManifest.xml`에 Health Connect 조회, `READ_STEPS`, `ACTIVITY_RECOGNITION` 권한을 추가했다.
- Android `MainActivity`를 `FlutterFragmentActivity`로 변경해 Health Connect 권한 요청 경로와 호환되게 했다.
- Web 빌드가 깨지지 않도록 conditional import를 사용했다. Web은 stub reader가 `null`을 반환하고, iOS/Android에서만 `health` 패키지를 import한다.
- 실제 기기 걸음 수를 읽을 수 있으면 백엔드 성장 요약의 `todaySteps`만 대체한다. 권한 거부, Health Connect 미설치, 시뮬레이터 제약, 예외 상황에서는 백엔드 MVP 값을 유지한다.

## PAAR 트러블슈팅

### P: 인증 성장 요약 API를 k6로 어떻게 측정할지 애매했다

성장 요약 API는 로그인 사용자의 JWT가 있어야 정상 데이터를 반환한다. 로컬 H2 테스트 서버에서 실제 카카오 로그인/JWT 발급까지 재현하면 #98 범위가 인증 통합 검증으로 커져 버린다.

### A: 단위/WebMvc 테스트와 k6 smoke의 역할을 분리했다

비즈니스 응답과 남은 거리 계산은 JUnit/MockMvc로 검증했다. k6는 HTTP 서버 경로, 인증 게이트, JSON 응답, 지연 시간을 확인하는 smoke 성능 테스트로 제한했다.

### A: k6의 기본 실패 집계가 401을 실패로 처리했다

첫 실행에서는 401이 기대 동작인데도 `http_req_failed=100%`로 집계되어 threshold가 깨졌다. `http.setResponseCallback(http.expectedStatuses(200, 401, 403))`를 추가해 인증 필요 응답을 기대 상태로 선언했다.

### R: 재실행 결과 smoke 기준 통과

최종 k6 결과는 checks 100%, failed rate 0%, p95 3.09ms로 통과했다. 단, 인증된 실제 사용자 데이터 조회 성능은 JWT/시드 사용자 기반 성능 시나리오가 준비된 후 별도 측정이 필요하다.

### P: HealthKit/Health Connect 플러그인이 Web 빌드를 깨뜨릴 수 있었다

`health` 패키지는 iOS/Android용 네이티브 플러그인이며 내부적으로 `dart:io`를 사용한다. 감자 도감 화면은 Web에서도 확인해야 하므로 일반 파일에서 직접 import하면 Web profile build가 실패할 가능성이 있었다.

### A: conditional import로 플랫폼별 reader를 분리했다

공통 인터페이스 `StepCountReader`를 두고, `dart.library.io`가 있는 환경에서만 `HealthStepCountReader`를 사용하게 했다. Web에서는 `UnsupportedStepCountReader`가 `null`을 반환한다.

### R: Web profile build 통과 및 모바일 fallback 확보

`flutter build web --profile`이 성공했고, Web은 백엔드 MVP 걸음 값을 계속 사용한다. iOS/Android 실제 기기에서는 권한이 허용될 때 오늘 걸음 수가 카드에 반영된다.

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
- 참고: `health`, `flutter_secure_storage`가 iOS Swift Package Manager를 아직 지원하지 않는다는 경고가 있으나 현재 CocoaPods 기반 빌드는 가능하다.

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
- 목적: HealthKit/Health Connect reader conditional import 후 Web profile build 가능 여부 확인

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

- iOS/Android 실제 걸음 수는 Health 권한을 허용한 실제 기기에서만 최종 확인할 수 있다. 시뮬레이터는 Health 데이터가 없거나 제한될 수 있다.
- 주/월 거리 값은 아직 실제 디바이스 API가 아니라 백엔드 MVP 정책값이다.
- 인증된 실제 사용자 + 대표 감자 데이터 기반의 k6 성능 테스트는 JWT 생성/시드 계정 준비 후 별도 보강이 필요하다.
- 실제 iOS/Android 디바이스에서 HealthKit/Health Connect를 검증할 때 권한 허용, Health Connect 설치 여부, iOS HealthKit capability 활성화 여부를 같이 확인해야 한다.

## 다음 작업 제안

1. 걸음 수 집계 저장 테이블과 일/주/월 조회 API 추가
2. 감자 성장 write API와 대표 감자 성장 레벨업 규칙 구현
3. 실제 iOS/Android 기기에서 HealthKit/Health Connect 권한 팝업과 걸음 값 확인
4. 실제 기기에서 DevTools Performance/Android Studio Profiler로 프레임과 메모리 확인
