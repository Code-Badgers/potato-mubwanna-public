# Issue #125 검증 기록

## 작업 목표

- 팀원 B 담당 범위인 관광지 집중률/혼잡도 예측 데이터를 백엔드에서 수집할 수 있는 기반을 만든다.
- 외부 공공 API 응답을 `spot_congestion_predictions`에 저장하고, 대표 혼잡도는 `tourist_spots.congestion_level`에 반영한다.
- 로컬 서버 시작 시 외부 API 호출이 자동으로 발생하지 않도록 기본값은 비활성화하고, 필요할 때 환경변수로 켤 수 있게 한다.

## PAAR 기록

### 1. 외부 API 클라이언트

- Problem: 관광지 혼잡도 예측 API는 공공데이터 응답 필드명이 문서/서비스 버전에 따라 다르게 내려올 수 있어, 단일 DTO로 강하게 고정하면 수집 실패 가능성이 높았다.
- Action: `TourismCongestionApiClient`를 추가하고 `JsonNode` 기반으로 `predictionDate`, `cnctrRate`, `contentId` 등 후보 필드를 유연하게 읽도록 구성했다.
- Analysis: 인증키는 Encoding/Decoding 값이 섞일 수 있어 이중 인코딩을 피해야 했다. 이미 `%`가 포함된 키는 그대로 쓰고, 그렇지 않은 키는 `+`, `/`까지 안전하게 쿼리 인코딩하도록 처리했다.
- Result: 클라이언트 단위 테스트에서 정상 응답, 빈 응답, API 오류 응답, 인증키 인코딩을 검증했다.

### 2. DB 동기화 서비스

- Problem: 예측 데이터를 매번 새로 삽입하면 같은 관광지/날짜/source 조합이 중복될 수 있고, 지도에서 표시할 대표 혼잡도도 갱신되지 않는다.
- Action: `TourismCongestionSyncService`를 추가해 활성 관광지 중 `contentId`가 있는 스팟만 대상으로 API를 호출하고, 기존 예측이 있으면 update, 없으면 insert하는 upsert 흐름을 구현했다.
- Analysis: API 일부 호출이 실패해도 전체 배치가 멈추면 지도 데이터 품질이 떨어진다. 따라서 개별 스팟 실패는 경고 로그와 실패 카운트로 남기고 다음 스팟을 계속 처리하도록 했다.
- Result: 신규 예측 저장, 기존 예측 갱신, 일부 스팟 실패 시 계속 진행하는 테스트가 통과했다.

### 3. 실행 옵션

- Problem: 로컬 개발 서버를 켤 때마다 외부 API 수집이 자동으로 돌면 키 누락, 쿼터 소진, 네트워크 실패 때문에 개발 경험이 불안정해질 수 있다.
- Action: `TourismCongestionSyncRunner`를 추가하고 `CONGESTION_API_SYNC_ON_STARTUP=false`를 기본값으로 설정했다.
- Analysis: 기존 `TourApiSpotImportRunner`와 같은 패턴을 따라, 운영/검증 환경에서는 환경변수만 켜서 수집을 실행할 수 있게 했다.
- Result: `sync-on-startup=false`일 때 서비스 호출이 없고, `true`일 때 한 번 호출되는 것을 단위 테스트로 확인했다.

## 변경 파일 요약

- `backend/src/main/resources/application.yml`
  - `external.congestion-api.*` 설정과 `CONGESTION_API_SYNC_ON_STARTUP` 옵션 추가
- `backend/src/main/java/com/gamjamubwatna/spot/infrastructure/TourismCongestionApiClient.java`
  - 관광지 혼잡도 예측 API 클라이언트 추가
- `backend/src/main/java/com/gamjamubwatna/spot/application/TourismCongestionSyncService.java`
  - 관광지별 예측 데이터 수집, upsert, 대표 혼잡도 갱신 추가
- `backend/src/main/java/com/gamjamubwatna/spot/infrastructure/TourismCongestionSyncRunner.java`
  - 환경변수 기반 시작 시 동기화 실행 옵션 추가
- `backend/src/test/java/com/gamjamubwatna/spot/**`
  - 클라이언트, 동기화 서비스, 실행 옵션 단위 테스트 추가

## 실행한 검증

```bash
cd backend && ./gradlew test --tests 'com.gamjamubwatna.spot.infrastructure.TourismCongestionApiClientTest'
```

- 결과: 성공

```bash
cd backend && ./gradlew test --tests 'com.gamjamubwatna.spot.application.TourismCongestionSyncServiceTest'
```

- 결과: 성공

```bash
cd backend && ./gradlew test --tests 'com.gamjamubwatna.spot.infrastructure.TourismCongestionSyncRunnerTest'
```

- 결과: 성공

```bash
cd backend && ./gradlew test --tests 'com.gamjamubwatna.spot.*'
```

- 결과: 성공

## 성능 검증

- k6 설치 여부: `/usr/local/bin/k6` 확인 완료
- 이번 이슈에서는 신규 HTTP endpoint가 아니라 외부 API 수집 배치와 저장 로직을 추가했기 때문에 k6 부하 테스트는 실행하지 않았다.
- 후속 성능 테스트 권장 지점:
  - 혼잡도 데이터가 적재된 뒤 `GET /api/spots?congestionLevel=LOW`
  - 지도 화면 초기 진입 시 사용하는 스팟 목록 API
  - 추천 동선 API가 혼잡도 필터를 함께 쓰는 경우
- 이후 HTTP API가 확정되면 k6 html 리포트와 스크린샷을 같은 폴더에 추가한다.

## 남은 리스크

- 실제 공공 API endpoint와 응답 필드는 운영 키로 한 번 더 샘플 호출 검증이 필요하다.
- 현재 동기화는 시작 시 1회 실행 옵션만 제공한다. 주기 실행이 필요하면 Spring Scheduler 또는 운영 배치 잡으로 분리하는 후속 이슈가 필요하다.
- 실제 데이터가 충분히 쌓인 뒤 혼잡도 등급 기준이 공모전 UX에 적절한지 조정해야 한다.

## 환경변수

- `CONGESTION_API_BASE_URL`
- `CONGESTION_API_PREDICTION_PATH`
- `CONGESTION_API_SERVICE_KEY`
- `CONGESTION_API_MOBILE_OS`
- `CONGESTION_API_MOBILE_APP`
- `CONGESTION_API_CONTENT_ID_PARAM`
- `CONGESTION_API_SYNC_ON_STARTUP`
