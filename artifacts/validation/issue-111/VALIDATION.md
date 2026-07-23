# Issue #111 감자 스팟 데이터 품질 보정 검증

## 작업 목표

TourAPI와 Kakao Local API로 수집한 감자 스팟이 음식점 한쪽으로만 몰리지 않도록 백엔드 분류 로직과 외부 카테고리 매핑을 보강했다.

- 감자 체험, 관광, 기념품숍, 바&페어링 키워드 분류 추가
- `감자 빵`, `로컬 푸드`처럼 공백이 섞인 키워드 정규화
- Kakao Local 카테고리명을 TourAPI contentTypeId 성격에 맞게 매핑
- 스팟 분류와 import service 테스트 추가

## PAAR 기록

### 1. 음식점 중심으로 데이터가 쏠리는 문제

- Problem: 기존 수집 결과가 `POTATO_RESTAURANT` 중심으로 분류되어 카페, 체험, 관광, 기념품/판매장, 바&페어링 같은 지도 필터가 충분히 살아나지 않았다.
- Analysis: TourAPI와 Kakao Local은 같은 장소라도 제목, 주소, 카테고리명에 들어오는 힌트가 다르다. 음식점 contentTypeId만 믿으면 카페/디저트/브루어리/시장류가 세분화되지 않고, 제목 키워드만 보면 관광/체험성 장소가 누락될 수 있다.
- Action: `PotatoSpotClassifier`에 체험, 관광, 기념품, 바&페어링 키워드 우선순위를 추가했다. `감자빵 기념품숍`처럼 상품 키워드가 더 강한 경우는 스낵으로 유지되도록 우선순위를 조정했다.
- Result: 신규 테스트에서 체험, 관광, 기념품숍, 바&페어링 분류가 기대 카테고리와 태그로 저장되는 것을 확인했다.

### 2. 공백이 섞인 키워드 누락 문제

- Problem: 실제 검색 결과에는 `감자빵`뿐 아니라 `감자 빵`, `로컬푸드`뿐 아니라 `로컬 푸드`처럼 띄어쓰기가 흔들린 표현이 섞일 수 있다.
- Analysis: 단순 `String.contains`는 사람이 보기에는 같은 표현인 키워드도 공백이 달라지면 놓친다. 수집 품질을 올리려면 키워드 비교 직전에 최소한의 문자열 정규화가 필요하다.
- Action: `containsAny`에서 원문 비교와 함께 공백 제거 문자열 비교를 같이 수행하도록 변경했다.
- Result: `강릉 감자 빵 베이커리`, `평창 로컬 푸드 감자 판매장` 테스트가 통과했다.

### 3. Kakao Local 카테고리 매핑 보강

- Problem: Kakao Local 응답의 `category_name`은 `가정,생활 > 식품판매 > 농수축산물`, `여행 > 관광,명소`처럼 세분화되어 오지만 기존 매핑은 시장/쇼핑/마트/관광/명소/체험 정도만 처리했다.
- Analysis: Kakao Local은 TourAPI contentTypeId를 직접 주지 않는다. 저장 시 내부 contentTypeId가 모두 39로 떨어지면 이후 데이터 운영과 필터 분석이 흐려진다.
- Action: 상점, 기념품, 특산품, 농수축산물은 38, 문화시설/박물관/미술관/전시관은 14, 레저/스포츠는 28로 매핑하도록 보강했다.
- Result: Kakao Local 쇼핑성 장소와 관광성 장소가 저장될 때 contentTypeId, `SpotCategory`, 태그가 의도대로 생성되는 것을 테스트로 확인했다.

## 실행한 검증

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.spot.application.PotatoSpotClassifierTest'
```

- 결과: 성공
- 확인 내용: 감자 체험, 관광, 기념품숍, 바&페어링, 공백 정규화 분류

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.spot.application.TourApiSpotImportServiceTest'
```

- 결과: 성공
- 확인 내용: TourAPI import, Kakao Local import, Kakao Local 카테고리 매핑

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.spot.application.*' --tests 'com.gamjamubwatna.spot.api.*' --tests 'com.gamjamubwatna.spot.domain.*'
```

- 결과: 성공
- 확인 내용: 스팟 application/api/domain 테스트 묶음 회귀 확인

## k6 성능 테스트

이번 변경은 외부 API 수집 결과를 저장하기 전 분류하는 문자열 기반 전처리 로직이다. 신규 public endpoint 또는 사용자 트래픽이 직접 증가하는 API 변경은 없어서 k6 smoke는 실행하지 않았다.

후속으로 실제 데이터 수집 실행 API 또는 scheduler-triggered import 관측 지표가 준비되면 아래 시나리오로 k6를 분리해 측정한다.

- `GET /api/spots` 카테고리별 필터 응답 p95 확인
- import 이후 `POTATO_CAFE`, `POTATO_SNACK`, `POTATO_TOUR`, `POTATO_SHOP` 필터 결과 개수 확인
- 대량 스팟 데이터 적재 후 지도 목록 조회 응답 시간 비교

## 셀프리파인

- 분류 키워드는 우선순위가 중요하다. `감자빵 기념품숍`은 기념품숍 단어가 있어도 사용자가 기대하는 필터는 감자빵/간식일 수 있어 스낵 우선순위를 유지했다.
- `바`는 단어가 짧아서 과매칭 위험이 있다. 현재는 감자 키워드 신뢰 검색 흐름 안에서만 사용되므로 영향이 제한적이지만, 향후 일반 텍스트 import로 확장하면 `바&페어링`, `펍`, `브루어리` 중심으로 조정하는 것이 좋다.
- Kakao Local categoryName은 서비스 운영 중 실제 응답을 보며 계속 보정해야 한다. 이번 작업은 code-level seed가 아니라 분류 정책의 첫 품질 보정이다.

## 남은 리스크

- 외부 API 실제 응답 데이터의 품질은 지역, 키워드, Kakao/TourAPI 검색 색인 상태에 따라 달라진다.
- 중복 제거는 아직 `contentId`와 정확한 `name + address` 중심이다. 상호명 공백, 괄호, 지점명 차이까지 흡수하려면 후속으로 정규화 키 또는 유사도 기반 upsert가 필요하다.
- 프론트 지도 필터별 표시 품질은 실제 import 후 DB 분포를 보고 추가 보정해야 한다.

## 후속 작업

- 실제 import 실행 후 카테고리별 저장 개수 기록
- Kakao Local과 TourAPI 중복 장소 정규화 upsert 고도화
- 카테고리별 지도 마커/필터 문구 최종 정리
- 한국관광공사 연관 관광지 API 기반 추천 동선과 연결
