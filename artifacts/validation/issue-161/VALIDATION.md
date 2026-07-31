# #161 감자 스팟 데이터 품질 보정 배치 Validation

## 1. 작업 범위

- Issue: #161 `[BE] chore: 감자 스팟 데이터 품질 보정 배치`
- Branch: `feat/161-spot-data-quality`
- 목표: TourAPI/Kakao Local 수집 데이터에서 강원 외 좌표, 중복 저장, 감자 관련성이 낮은 일반 장소를 줄인다.

## 2. PAAR 기록

### Problem

감자 지도는 TourAPI와 Kakao Local 수집 흐름이 연결되어 있지만, 외부 검색 API 결과는 항상 앱 의도와 정확히 일치하지 않는다. 특히 다음 문제가 지도 품질을 떨어뜨릴 수 있다.

- 좌표가 `0,0`이거나 강원 외 지역인 장소가 들어올 수 있다.
- TourAPI와 Kakao Local이 같은 장소를 서로 다른 contentId로 내려주면 중복 마커가 생길 수 있다.
- `감자탕`처럼 이름에는 감자가 있지만 강원 감자 여행 스팟과 관련성이 낮은 일반 음식점이 섞일 수 있다.
- 관광/명소 타입에서 감자 단서가 없는 일반 관광지가 keyword search 결과라는 이유만으로 저장될 수 있다.

### Analysis

데이터 품질을 한 번에 완벽하게 해결하려면 관리자 큐레이션 화면, 수동 blacklist/whitelist, 외부 API별 신뢰도 점수, Naver API 보강까지 필요하다. 이번 이슈에서는 MVP 안정성에 바로 도움이 되는 자동 방어 규칙만 좁게 적용했다.

- 좌표는 강원특별자치도 주변 bounding box로 먼저 방어한다.
- 중복은 이미 존재하는 `findByNameAndAddress`를 TourAPI에도 적용한다.
- 감자탕은 일반 감자 키워드보다 오탐 가능성이 높아 단독 등장 시 제외한다.
- 단, `감자탕 감자전`처럼 강원 감자 음식 단서가 함께 있으면 저장을 유지한다.
- 관광 타입 keyword search 결과는 감자 관련 단서가 없으면 제외한다.

### Action

- `TourApiSpotImportService`에 강원 좌표 범위 검증을 추가했다.
- TourAPI upsert도 `contentId` 다음에 `name + address`로 기존 스팟을 찾아 중복 저장을 막도록 수정했다.
- `PotatoSpotClassifier`에 일반 관광지/일반 감자탕 저관련성 제외 규칙을 추가했다.
- `TourApiSpotImportServiceTest`에 강원 외 좌표, 0좌표, TourAPI/Kakao 중복 업데이트 케이스를 추가했다.
- `PotatoSpotClassifierTest`에 감자 단서 없는 일반 관광지, 일반 감자탕 제외, 감자전 단서 유지 케이스를 추가했다.
- `artifacts/progress/team_work_progress_overview.md`에 #161 진행 상태와 Team B 남은 작업을 반영했다.

### Result

수집 시 다음 데이터가 자동으로 제외되거나 중복 방어된다.

- 서울 좌표 또는 `0,0` 좌표 데이터
- TourAPI와 Kakao Local에서 같은 이름/주소로 들어오는 중복 스팟
- 감자 단서 없는 일반 관광/명소
- 일반 감자탕 음식점

## 3. 검증 명령

### 실패 후 수정

```bash
cd backend
./gradlew test --tests com.gamjamubwatna.spot.application.TourApiSpotImportServiceTest
```

- 최초 결과: 실패
- 원인: `TourApiSpotImportService`에 `BigDecimal` import가 누락되어 컴파일 실패
- 해결: `java.math.BigDecimal` import 추가 후 동일 테스트 재실행

### 통과

```bash
cd backend
./gradlew test --tests com.gamjamubwatna.spot.application.TourApiSpotImportServiceTest
```

- 결과: `BUILD SUCCESSFUL`
- 확인 내용:
  - TourAPI/Kakao Local 강원 외 좌표 제외
  - `0,0` 좌표 제외
  - TourAPI contentId가 달라도 같은 이름/주소면 기존 스팟 업데이트

```bash
cd backend
./gradlew test --tests com.gamjamubwatna.spot.application.PotatoSpotClassifierTest
```

- 결과: `BUILD SUCCESSFUL`
- 확인 내용:
  - 감자 단서 없는 일반 관광지 제외
  - 일반 감자탕 제외
  - 감자전 등 강원 감자 음식 단서가 있으면 유지

```bash
cd backend
./gradlew test \
  --tests com.gamjamubwatna.spot.application.TourApiSpotImportServiceTest \
  --tests com.gamjamubwatna.spot.application.PotatoSpotClassifierTest
```

- 결과: `BUILD SUCCESSFUL`

## 4. 성능 테스트

k6 성능 테스트는 실행하지 않았다. 이번 변경은 외부 API 수집 후 저장 전 필터링/분류 로직이며, 사용자 요청 API의 런타임 응답 성능을 직접 바꾸는 작업이 아니다. 다만 데이터 품질이 좋아지면 지도 응답의 마커 수와 중복 마커가 줄어 프론트 렌더링 품질에 간접적으로 도움이 된다.

## 5. 남은 리스크와 후속 작업

- 강원 bounding box는 실무적으로 충분한 1차 방어지만 행정구역 polygon 검증은 아니다.
- 감자탕 제외는 MVP 의도에 맞춘 휴리스틱이다. 실제 제휴 감자탕집이 생기면 whitelist 정책이 필요하다.
- Kakao Local/TourAPI에서 누락되는 감자빵, 감자 맥주, 직판장 등은 수동 큐레이션 seed가 필요할 수 있다.
- Naver API 추가 여부는 쿼터, 비용, 데이터 품질을 보고 별도 이슈에서 결정하는 것이 좋다.
