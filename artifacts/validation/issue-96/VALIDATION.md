# Issue #96 감자 상세 시트 대표 감자 설정 연결 검증

## 작업 목표

- 감자 도감 상세 시트의 `대표 감자로 설정` 버튼을 실제 대표 감자 변경 API 흐름과 연결한다.
- 상단 대표 감자 카드의 picker 흐름과 동일하게 성공 시 provider를 refresh하고 사용자에게 스낵바를 보여준다.
- 이미 대표 감자인 감자와 미획득 감자는 버튼을 비활성화한다.

## 변경 요약

- `PotatoCollectionScreen`에서 상세 시트에도 `onSetRepresentative` callback을 전달했다.
- 상세 시트 버튼이 더 이상 단순 닫기만 하지 않고, 시트를 닫은 뒤 `_updateRepresentativePotato(item)`를 호출하도록 변경했다.
- 대표 감자 변경 중, 이미 대표 감자, 미획득 감자 상태에서는 버튼을 비활성화했다.
- 위젯 테스트에 상세 시트에서 대표 감자를 설정하는 흐름을 추가했다.

## PAAR 기록

### 1. 상세 시트 버튼이 API를 호출하지 않는 문제

- Problem: #94에서 대표 감자 picker는 API에 연결되었지만, 상세 시트의 `대표 감자로 설정` 버튼은 `Navigator.pop()`만 실행했다.
- Analysis: 사용자는 도감 타일을 눌러 상세 설명을 확인한 뒤 바로 대표 감자로 지정할 가능성이 높다. 같은 화면에 있는 동일 의미 버튼이 서로 다른 동작을 하면 UX가 어색하다.
- Action: 상세 시트 생성 시 `onSetRepresentative` callback을 주입하고, 버튼 탭 시 시트를 닫은 뒤 기존 `_updateRepresentativePotato(item)`를 재사용하도록 연결했다.
- Result: 상세 시트에서도 picker와 동일한 API 호출, provider refresh, 성공/실패 스낵바 흐름을 사용한다.

### 2. 버튼 상태 중복 처리

- Problem: 이미 대표 감자인 감자에도 `대표 감자로 설정` 액션이 활성화되면 불필요한 요청을 만들 수 있다.
- Analysis: `_updateRepresentativePotato` 내부에도 방어 로직이 있지만, UI에서 먼저 disabled 처리하는 편이 사용자에게 상태를 명확히 보여준다.
- Action: `locked || item.representative || updatingRepresentative` 조건에서는 버튼을 비활성화하고, 대표 감자는 `대표 감자로 설정됨` 문구를 유지했다.
- Result: 미획득/이미 대표/요청 중 상태에서 중복 요청을 줄였다.

### 3. Backend k6 테스트 환경 문제

- Problem: 로컬 Codex 환경에는 `k6`, `brew`, `docker`, `node`, `go`, `psql`이 없었다.
- Analysis: 시스템 설치가 아니라 산출물 영역에 k6 단일 바이너리를 내려받으면 로컬 환경을 크게 오염시키지 않고 테스트를 진행할 수 있다. 백엔드는 PostgreSQL 없이도 `bootTestRun`과 H2 test runtime classpath로 실행 가능했다.
- Action: `artifacts/local-runtime/tools/bin/k6`에 k6 v0.54.0을 내려받고, `./gradlew bootTestRun`을 H2 설정으로 실행했다. 첫 시도에서는 Redis가 없는 환경이라 `/actuator/health`가 503 DOWN을 반환해 실패했고, DB-backed public API인 `/api/spots` 전용 smoke 테스트로 수정했다.
- Result: `/api/spots` 기준 5 VUs, 20초, 100 requests, failed rate 0%, avg 4.55ms, p95 6.18ms, max 7.41ms로 threshold를 통과했다.

### 4. Frontend 성능 검증 범위

- Problem: 이번 변경은 작은 UI callback 연결이지만, 사용자가 프론트 성능 테스트 기록을 요청했다.
- Analysis: 실제 FPS/Frame Rendering은 iOS/Android 시뮬레이터와 Flutter DevTools 또는 Android Studio Profiler가 가장 적합하다. 현재 Codex 로컬 환경에서는 시뮬레이터 제어 없이 재현 가능한 대체 검증으로 `flutter analyze`, 위젯 테스트, `flutter build web --profile`을 실행하는 것이 현실적이다.
- Action: 도감 위젯 테스트, 정적 분석, web profile build를 실행하고 build 시간과 산출물 크기를 기록했다.
- Result: analyze/test/profile build 모두 성공했다. profile web build는 78.38초, `build/web` 51MB, `main.dart.js` 9.2MB였다.

## 실행한 검증

### Frontend

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter test test/features/potato/potato_collection_screen_test.dart
```

- 결과: 성공
- 확인 내용:
  - 도감 화면 렌더링
  - 감자 상세 시트 표시
  - 비로그인 상태
  - 대표 감자 picker 설정 흐름
  - 상세 시트 대표 감자 설정 흐름

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter analyze
```

- 결과: 성공
- 참고: `flutter_secure_storage`의 iOS Swift Package Manager 미지원 경고가 출력되었으나 기존 플러그인 경고다.

```bash
cd frontend
/usr/bin/time -p /Users/mac/Documents/flutter/bin/flutter build web --profile \
  --dart-define=KAKAO_JAVASCRIPT_KEY=dummy \
  --dart-define=KAKAO_NATIVE_APP_KEY=dummy \
  --dart-define=API_BASE_URL=http://localhost:18080/api
```

- 결과: 성공
- build time: 78.38초
- `build/web`: 51MB
- `main.dart.js`: 9.2MB
- 참고: Wasm dry-run에서 `flutter_secure_storage_web`, `geolocator_web`의 `dart:html` 의존성 경고가 출력되었다. 이번 변경으로 새로 생긴 오류는 아니다.

### Backend k6

백엔드 실행:

```bash
cd backend
./gradlew bootTestRun --args='--server.port=18080 --spring.datasource.url=jdbc:h2:mem:k6_backend;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH --spring.datasource.driver-class-name=org.h2.Driver --spring.datasource.username=sa --spring.datasource.password= --spring.jpa.hibernate.ddl-auto=validate --spring.data.redis.host=localhost --external.tour-api.import-on-startup=false'
```

k6 실행:

```bash
BASE_URL=http://localhost:18080/api artifacts/local-runtime/tools/bin/k6 run artifacts/validation/issue-96/k6-backend-smoke.js
```

- 결과: 성공
- 대상: `GET /api/spots`
- VUs: 5
- duration: 20초
- requests: 100
- failed rate: 0.00%
- avg duration: 4.55ms
- p95 duration: 6.18ms
- max duration: 7.41ms

## 산출물

- `artifacts/validation/issue-96/k6-backend-smoke.js`
- `artifacts/validation/issue-96/k6-backend-output.txt`
- `artifacts/validation/issue-96/k6-backend-summary.json`
- `artifacts/validation/issue-96/k6-backend-report.html`
- `artifacts/validation/issue-96/k6-backend-report.png`
- `artifacts/validation/issue-96/frontend-profile-build-output.txt`
- `artifacts/validation/issue-96/frontend-profile-build-report.html`
- `artifacts/validation/issue-96/frontend-profile-build-report.png`

## 셀프리파인

- 상세 시트 버튼은 시트를 닫은 뒤 기존 대표 감자 변경 메서드를 재사용하므로 API 호출 로직이 중복되지 않는다.
- `mounted` 체크와 `finally` 로딩 해제가 기존 `_updateRepresentativePotato` 안에 있어 async 이후 화면 dispose 위험을 방어한다.
- 상세 시트 내부에서 `updatingRepresentative` spinner를 지원하지만 현재 동작은 시트를 먼저 닫고 요청하므로 실제 spinner 노출은 제한적이다. 향후 시트를 유지한 채 요청하는 UX로 바꾸면 이 상태값을 바로 활용할 수 있다.
- #96은 프론트 callback 연결 이슈이므로 백엔드 코드 변경은 하지 않았다. k6는 변경 API가 아니라 public DB-backed endpoint `/api/spots`를 대상으로 smoke 성능을 확인했다.

## 남은 리스크

- 실제 iOS/Android 디바이스에서 Flutter DevTools Performance 또는 Android Studio Profiler로 frame rendering을 측정하지는 못했다.
- 대표 감자 변경 PATCH endpoint 자체의 k6 테스트는 인증 토큰과 사용자 보유 감자 seed 준비가 필요해 이번 로컬 smoke 범위에서는 제외했다.
- actuator health는 Redis가 없는 H2 bootTestRun 환경에서 503 DOWN을 반환한다. 운영 성능 테스트는 PostgreSQL/Redis를 모두 띄운 Docker 또는 실제 dev 환경에서 재실행하는 것이 좋다.
