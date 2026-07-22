# Issue 103 Validation

## 작업 목표

관광지 혼잡도 예측 데이터를 지도와 감자 희귀도 정책에 연결하기 위한 백엔드 기반을 준비했다.

- 관광지별 혼잡도 예측 기록 테이블 추가
- 예측값을 앱 내부 혼잡도 등급(`LOW`, `NORMAL`, `HIGH`)으로 변환하는 정책 추가
- 혼잡도에 따라 희귀 감자 등장 확률을 보정할 수 있는 정책 추가
- 예측 기록 저장 시 `tourist_spots.congestion_level` 대표값을 함께 갱신하는 서비스 추가

## 외부 API 사용 맥락

한국관광공사 `관광지 집중률 방문자 추이 예측 정보`는 KT 이동통신 기반 데이터를 활용해 조회일 기준 향후 30일간 관광지 방문 집중률을 제공한다. 공공데이터포털 설명 기준으로 가장 붐비는 시기를 `100`으로 보았을 때의 상대 수치이므로, 실제 외부 클라이언트 연결 시에는 집중률 점수를 내부 정책 입력값으로 변환해야 한다.

이번 PR에서는 외부 API 호출 클라이언트를 바로 붙이지 않고, 예측 결과를 저장하고 지도 대표 혼잡도를 갱신하는 내부 경로를 먼저 만들었다. 이유는 외부 API의 상세 파라미터와 응답 필드가 활용 신청/Swagger 기준으로 최종 확인되어야 하고, 먼저 내부 정책과 저장 구조를 고정해야 지도/방문 인증/감자 희귀도 로직이 같은 도메인 값을 사용할 수 있기 때문이다.

## PAR 기록

### Problem

기존 `tourist_spots`에는 `congestion_level` 컬럼이 있었지만, 이 값이 어떤 데이터로 갱신되는지와 희귀 감자 등장 확률에 어떻게 연결되는지가 분리되어 있지 않았다. 지도는 혼잡도 뱃지를 표시할 수 있었지만, 방문 인증 시 “사람이 적은 장소일수록 희귀 감자 확률 상승”이라는 정책을 검증 가능한 코드로 사용할 기반이 부족했다.

### Action

`spot_congestion_predictions` 테이블을 추가해 관광지별 예측 기록을 별도로 저장하도록 했다. `CongestionLevelPolicy`는 예측 방문/집중 값과 기준 값을 비교해 `LOW`, `NORMAL`, `HIGH`를 산정한다. `CongestionRarityPolicy`는 혼잡도 등급을 희귀 감자 확률 보정 배율로 변환한다. `SpotCongestionService`는 예측 기록을 생성 또는 갱신하고, 지도 조회가 바로 사용할 수 있도록 `TouristSpot.congestionLevel` 대표값도 함께 갱신한다.

### Result

정책 테스트, 서비스 테스트, migration 테스트가 통과했다. 또한 더 넓은 spot/potato 테스트 범위를 실행해 Spring context와 기존 지도/감자 기능 영향도 확인했다.

## 발생한 문제와 해결

### Spring 생성자 선택 실패

처음 `SpotCongestionService`에 운영용 생성자와 테스트용 생성자를 함께 두었더니, 넓은 Spring context 테스트에서 다음 오류가 발생했다.

```text
Failed to instantiate [com.gamjamubwatna.spot.application.SpotCongestionService]: No default constructor found
Caused by: java.lang.NoSuchMethodException: com.gamjamubwatna.spot.application.SpotCongestionService.<init>()
```

원인은 Spring이 여러 생성자 중 주입 생성자를 명확히 고르지 못한 것이다. 운영 생성자에 `@Autowired`를 명시해 해결했다. 이후 같은 범위 테스트를 재실행해 통과를 확인했다.

## 실행한 검증 명령

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.spot.application.CongestionLevelPolicyTest' --tests 'com.gamjamubwatna.potato.application.CongestionRarityPolicyTest' --tests 'com.gamjamubwatna.spot.domain.SpotCongestionPredictionMigrationTest'
```

결과: 성공

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.spot.application.CongestionLevelPolicyTest' --tests 'com.gamjamubwatna.spot.application.SpotCongestionServiceTest' --tests 'com.gamjamubwatna.potato.application.CongestionRarityPolicyTest'
```

결과: 성공

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.spot.*' --tests 'com.gamjamubwatna.potato.*'
```

1차 결과: 실패. `SpotCongestionService` 생성자 주입 문제 확인.

2차 결과: 성공. `@Autowired` 명시 후 통과.

## k6 성능 테스트

이번 변경은 외부에 새 HTTP endpoint를 열지 않고, 내부 서비스와 DB migration, 정책을 추가한 작업이다. 따라서 k6로 직접 호출할 안정적인 사용자 API가 아직 없다. 다음 단계에서 혼잡도 조회/갱신 endpoint 또는 배치 트리거가 생기면 다음 항목을 측정한다.

- `/api/spots?congestionLevel=LOW` 조회 응답 시간
- 혼잡도 반영 후 지도 스팟 목록 조회 p95
- 방문 인증 시 희귀도 정책 적용 경로의 응답 시간

## 남은 리스크

- 공공데이터포털 Swagger에서 실제 endpoint, 요청 파라미터, 응답 필드명을 최종 확인한 뒤 외부 API 클라이언트를 붙여야 한다.
- 현재 정책은 `예측값 / 기준값` 비율 기반이다. 실제 API가 집중률 점수만 제공한다면 `집중률 점수 -> CongestionLevel` 전용 mapper를 추가하는 편이 더 명확하다.
- 희귀도 배율은 MVP 기준 임시 정책이다. 실제 획득률과 보상 밸런스를 보고 조정해야 한다.

## 후속 작업

- 관광지 집중률 API 클라이언트 구현
- 외부 응답의 관광지 식별자와 `tourist_spots` 매핑 기준 확정
- 방문 인증 성공 시 `CongestionRarityPolicy`를 감자 획득 로직에 연결
- 지도/상세 화면에서 혼잡도 갱신 시각 또는 안내 문구 노출 여부 결정
