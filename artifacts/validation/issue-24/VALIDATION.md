# Issue 24 Validation

## 작업 목표

- 한국관광공사 TourAPI Decoding service key를 로컬 백엔드 실행 환경에 저장한다.
- 커밋 대상 파일에는 실제 키 값이 아니라 환경변수 이름만 남긴다.
- 향후 스팟 수집 배치/스케줄러가 `TOUR_API_SERVICE_KEY`를 사용할 수 있게 Spring 설정을 준비한다.

## 변경 요약

- `backend/.env`: 로컬 전용 `TOUR_API_SERVICE_KEY` 값 추가
- `artifacts/local-runtime/backend.local.env`: 로컬 런타임용 `TOUR_API_SERVICE_KEY` 값 추가
- `backend/.env.example`: `TOUR_API_SERVICE_KEY=` 예시 변수 추가
- `backend/src/main/resources/application.yml`: `external.tour-api.service-key` 설정 추가
- `artifacts/local-runtime/RUNBOOK.md`: IntelliJ 실행 환경변수 목록에 TourAPI 변수명 추가

## 보안 확인

- 실제 TourAPI key 값은 `backend/.env`, `artifacts/local-runtime/backend.local.env`에만 저장했다.
- 두 파일은 Git ignore 대상임을 확인했다.
- 커밋 대상 diff에는 실제 key 값이 포함되지 않았다.

## 실행한 검증

```bash
env GRADLE_USER_HOME=/Users/mac/Desktop/lee/project/potato-mubwanna/backend/.gradle ./gradlew test
```

결과: 성공

## 남은 작업

- `Spot`/`Place` 도메인과 DB migration 설계
- TourAPI `searchKeyword4` 또는 `areaBasedList4` 호출 클라이언트 구현
- 강원도 `areaCode=32`와 감자 키워드 기반 수집 로직 구현
- 감자 스팟 카테고리/태그 매핑 정책 구현

---

## 2026-06-20 진행 내용

### 작업 목표

- 한국관광공사 TourAPI `searchKeyword4` 응답을 감자 스팟 후보로 수집할 수 있는 백엔드 기반을 만든다.
- 강원도 `areaCode=32`, 키워드 `감자`를 기준으로 검색한다.
- `contentTypeId`와 장소명/주소 키워드로 감자 스팟 카테고리를 분류한다.
- 프론트 지도 화면이 사용할 수 있는 `GET /api/spots`, `GET /api/spots/{spotId}` 조회 API를 준비한다.

### 설계 결정

- 현재 로컬 런타임 DB는 일반 PostgreSQL 컨테이너다. PostGIS 확장 없이 바로 실행 가능해야 하므로 이번 단계에서는 `latitude`, `longitude` 숫자 컬럼과 일반 인덱스를 사용했다.
- 운영 또는 대량 데이터 단계에서는 `geometry/geography POINT`와 공간 인덱스를 쓰는 PostGIS migration을 별도 이슈로 추가하는 것이 좋다.
- 실제 TourAPI key는 계속 `TOUR_API_SERVICE_KEY` 환경변수로만 주입한다. 커밋 대상 파일에는 placeholder와 변수명만 남긴다.

### 변경 파일 요약

- `backend/src/main/resources/db/migration/V2__create_tourist_spots.sql`
  - `tourist_spots` 테이블과 카테고리/도시명/위경도 인덱스 추가
- `backend/src/main/java/com/gamjamubwatna/spot/domain/*`
  - `TouristSpot`, `SpotCategory`, `CongestionLevel`, repository 추가
- `backend/src/main/java/com/gamjamubwatna/spot/infrastructure/TourApiClient.java`
  - TourAPI `searchKeyword4` 호출 클라이언트 추가
- `backend/src/main/java/com/gamjamubwatna/spot/application/*`
  - 감자 스팟 분류기와 import service 추가
- `backend/src/main/java/com/gamjamubwatna/spot/api/*`
  - 지도 조회 API와 응답 DTO 추가
  - `category`, `cityName`, `congestionLevel` 필터를 API 명세와 맞춤
- `backend/src/main/java/com/gamjamubwatna/global/config/SecurityConfig.java`
  - 지도 조회용 `/spots/**` 공개 허용
- `agents_docs/07_api_specification.md`
  - 감자 스팟 카테고리와 응답 필드 최신화

### 실행한 검증

```bash
git diff --check
```

결과: 성공

```bash
git ls-files -o --exclude-standard | LC_ALL=C grep -E '[:*?"<>|]|[. ]$' || true
```

결과: Windows 체크아웃을 막는 신규 파일명 없음

```bash
git ls-files backend/.env artifacts/local-runtime/backend.local.env
```

결과: 출력 없음. 실제 로컬 secret 파일은 Git 추적 대상이 아님

```bash
cd backend && ./gradlew test
```

결과: 실패. 코드 컴파일 실패가 아니라 샌드박스가 `/Users/mac/.gradle` 잠금 파일 생성을 막았다.

```bash
cd backend && GRADLE_USER_HOME=$PWD/.gradle ./gradlew --no-daemon test
```

결과: 실패. Gradle 내부 `FileLockContentionHandler`가 소켓을 만들 때 현재 Codex 샌드박스에서 `Operation not permitted`가 발생해 테스트 실행 자체가 시작되지 못했다.

### 남은 리스크

- 현재 환경에서는 Gradle 테스트 실행이 샌드박스 소켓 제한으로 막혀 실제 컴파일 검증을 완료하지 못했다.
- TourAPI 응답에서 `item`이 단일 객체로 내려오는 케이스가 있으면 현재 DTO는 리스트 형태만 처리한다. 실제 API 샘플 확인 후 보강이 필요하다.
- PostGIS 기반 반경 검색은 아직 구현하지 않았다. 대량 스팟 조회나 주변 검색을 시작할 때 별도 migration으로 확장해야 한다.

### 다음 작업

- 로컬 터미널에서 `cd backend && ./gradlew test`를 실행해 컴파일과 테스트를 확인한다.
- 검증이 통과하면 스케줄러 또는 관리자용 수동 import endpoint를 작은 단위로 추가한다.
- 프론트 지도는 `GET /api/spots` 응답을 받아 감자 마커 데이터를 mock에서 API 기반으로 교체한다.

---

## 2026-06-20 프론트 지도 API 연결 진행

### 작업 목표

- 프론트 지도 화면의 고정 mock 스팟 4건을 제거한다.
- `GET /api/spots` 응답을 받아 지도 하단 카드와 Kakao Web CustomOverlay 감자 핀에 함께 사용한다.
- 저장된 스팟 수를 지도 상단 배지에 표시한다.

### 변경 요약

- `frontend/lib/features/map/domain/map_spot.dart`
  - 백엔드 `SpotListResponse`를 프론트 지도 모델로 변환한다.
- `frontend/lib/features/map/data/map_spot_repository.dart`
  - `GET /api/spots` 호출 repository를 추가한다.
- `frontend/lib/features/map/application/map_spot_controller.dart`
  - Riverpod `FutureProvider`로 지도 스팟 목록을 로드한다.
- `frontend/lib/features/map/presentation/screen/map_screen.dart`
  - mock 4건 제거
  - API 데이터 기반 카테고리 필터, 상태 배지, 하단 시트 연결
  - 로딩/에러/빈 상태 표시
- `frontend/lib/features/map/presentation/widget/kakao_map_view_web.dart`
  - 화면에서 받은 스팟 목록으로 감자 모양 CustomOverlay 마커를 생성한다.
- `frontend/lib/features/map/presentation/widget/kakao_map_view_native.dart`
  - Android/iOS platform view에 스팟 목록 creationParams를 전달한다.
- `backend/src/main/java/com/gamjamubwatna/global/config/SecurityConfig.java`
  - Flutter Web 로컬 실행 포트에서 백엔드 API를 호출할 수 있도록 `localhost`, `127.0.0.1` CORS를 허용한다.

### 실행한 검증

```bash
curl -sS http://localhost:8080/api/spots
```

결과: 실패. 현재 Codex 세션에서 `localhost:8080` 백엔드 서버가 실행 중이지 않다.

```bash
docker compose -f artifacts/local-runtime/docker-compose.yml ps
```

결과: 실패. 현재 Codex 세션에는 `docker` 명령이 없다.

```bash
/Users/mac/Documents/flutter/bin/dart format ...
```

결과: 실패. Flutter SDK가 `/Users/mac/Documents/flutter/bin/cache`에 engine stamp를 쓰려고 했지만 현재 샌드박스에서 해당 경로 쓰기가 허용되지 않았다.

```bash
git diff --check
```

결과: 성공

### 현재 저장 스팟 수

- 이 Codex 세션에서는 DB/백엔드에 접근할 수 없어 실제 count를 직접 확인하지 못했다.
- 현재 코드 기준으로는 TourAPI import service만 있고 아직 자동 스케줄러 또는 수동 import endpoint가 없으므로, 사용자가 별도로 데이터를 넣지 않았다면 `tourist_spots`는 0건일 가능성이 높다.

### 사용자가 로컬에서 확인할 명령

```bash
docker exec -it potato-mubwanna-postgres psql -U potato -d potato_mubwanna
```

```sql
SELECT COUNT(*) FROM tourist_spots;
SELECT tourist_spot_id, name, category, city_name, latitude, longitude
FROM tourist_spots
ORDER BY tourist_spot_id DESC;
```

### 남은 리스크

- 프론트가 API 기반으로 바뀌었기 때문에 백엔드 서버가 꺼져 있으면 지도 화면은 에러 상태를 보여준다.
- 실제 TourAPI 데이터를 DB에 넣으려면 다음 작은 단위로 수동 import endpoint 또는 scheduler를 추가해야 한다.

---

## 2026-06-20 TourAPI 시작 시 적재 트리거 추가

### 작업 목표

- `tourist_spots` 테이블만 있고 값이 없는 상태를 해결하기 위해 TourAPI import 실행 트리거를 추가한다.
- 공개 API로 import endpoint를 열지 않고, 로컬/운영 환경변수로 명시적으로 켰을 때만 서버 시작 시 적재한다.

### 변경 요약

- `backend/src/main/java/com/gamjamubwatna/spot/infrastructure/TourApiSpotImportRunner.java`
  - `TOUR_API_IMPORT_ON_STARTUP=true`일 때 서버 시작 시 TourAPI import 실행
- `backend/src/main/java/com/gamjamubwatna/spot/application/TourApiSpotImportService.java`
  - 여러 페이지를 순회하는 `importPotatoSpotPages` 추가
- `backend/src/main/resources/application.yml`
  - `external.tour-api.import-on-startup`
  - `external.tour-api.import-page-size`
  - `external.tour-api.import-max-pages`
- `backend/.env.example`
  - 위 환경변수 예시 추가
- `backend/src/test/java/com/gamjamubwatna/spot/application/TourApiSpotImportServiceTest.java`
  - page range import 테스트 추가

### 로컬에서 값 넣는 방법

`backend/.env`에 아래 값만 추가한다. 실제 TourAPI key는 기존 `TOUR_API_SERVICE_KEY`를 그대로 사용한다.

```properties
TOUR_API_IMPORT_ON_STARTUP=true
TOUR_API_IMPORT_PAGE_SIZE=50
TOUR_API_IMPORT_MAX_PAGES=1
```

그 다음 백엔드를 재시작한다.

```bash
cd backend
./gradlew bootRun
```

서버 로그에 아래 형식의 로그가 보이면 import가 실행된 것이다.

```text
TourAPI potato spot import completed. savedCount=...
```

### DB 확인

```sql
SELECT COUNT(*) FROM tourist_spots;

SELECT tourist_spot_id, content_id, name, category, city_name, latitude, longitude
FROM tourist_spots
ORDER BY tourist_spot_id DESC;
```

### 참고

- 기본값은 `TOUR_API_IMPORT_ON_STARTUP=false`다. 외부 API가 서버 시작마다 호출되는 일을 막기 위해 명시적으로 켠 경우에만 동작한다.
- 기존 데이터는 `content_id` 기준으로 새로 만들거나 업데이트한다.

### 검증

```bash
git diff --check
```

결과: 성공

```bash
GRADLE_USER_HOME=$PWD/.gradle ./gradlew --no-daemon test
```

결과: 실패. 기존과 동일하게 현재 Codex 샌드박스에서 Gradle `FileLockContentionHandler`가 소켓을 생성하지 못해 테스트 실행이 시작되지 않았다.

---

## 2026-06-20 감자 스팟 카테고리 확장 및 핀 표시 보강

### 작업 목표

- TourAPI 수집 결과가 `POTATO_RESTAURANT` 음식점 위주로만 쌓이는 문제를 줄인다.
- 감자 베이커리, 카페, 관광지, 시장/직판장, 휴게소 간식, 감자 맥주/브루어리까지 분류할 수 있게 한다.
- 지도 화면에서 감자 핀이 안 찍히는 원인을 확인하고 1차 보강한다.

### 확인한 문제

- 웹 지도는 `KakaoMapView`에서 API 스팟 목록을 `CustomOverlay`로 찍고 있으므로, `tourist_spots` 테이블이 비어 있으면 핀이 0개인 것이 맞다.
- Android/iOS 네이티브 지도 구현은 `spots` creationParams를 넘겨받지만, 네이티브 SDK 마커를 실제로 추가하는 코드는 아직 없었다.
- 그래서 DB에 값이 있어도 모바일 네이티브 지도에서는 감자 핀이 보이지 않을 수 있다.

### 변경 요약

- `backend/src/main/java/com/gamjamubwatna/spot/domain/SpotCategory.java`
  - `POTATO_MARKET`, `POTATO_BREWERY` 추가
- `backend/src/main/java/com/gamjamubwatna/spot/infrastructure/TourApiClient.java`
  - `TOUR_API_SPOT_KEYWORDS` 기반 다중 키워드 검색 추가
  - 여러 키워드에 중복으로 걸린 장소를 `contentId` 기준으로 제거
- `backend/src/main/java/com/gamjamubwatna/spot/application/PotatoSpotClassifier.java`
  - 감자 카페/디저트, 간식, 시장/직판장, 브루어리 분류 로직 추가
- `frontend/lib/features/map/domain/map_spot.dart`
  - 새 카테고리 라벨과 감자 캐릭터명 매핑 추가
- `frontend/lib/features/map/presentation/screen/map_screen.dart`
  - 지도 필터에 `시장`, `술` 추가
  - Android/iOS 네이티브 지도에서 1차 감자 핀 오버레이 표시
- `agents_docs/07_api_specification.md`
  - `GET /api/spots` category enum 문서 최신화

### 환경변수

```properties
TOUR_API_SPOT_KEYWORDS=감자,감자빵,감자전,옹심이,감자옹심이,감자떡,알감자,회오리감자,감자체험,감자축제,감자꽃,감자밭,전통시장 감자,로컬푸드 감자,감자 맥주
```

### 실행한 검증

```bash
git diff --check
```

결과: 성공

```bash
cd backend && ./gradlew test --tests '*PotatoSpotClassifierTest' --tests '*TourApiSpotImportServiceTest'
```

결과: 실패. 현재 Codex 세션에서 `/Users/mac/.gradle/...gradle-8.14.3-bin.zip.lck` lock 파일 생성이 `Operation not permitted`로 막혔다.

```bash
/Users/mac/Documents/flutter/bin/dart format frontend/lib/features/map/domain/map_spot.dart frontend/lib/features/map/presentation/screen/map_screen.dart
```

결과: 실패. Flutter SDK가 `/Users/mac/Documents/flutter/bin/cache`에 engine stamp를 쓰려고 했지만 현재 Codex 샌드박스에서 허용되지 않았다.

### 로컬에서 이어서 확인할 명령

```bash
cd /Users/mac/Desktop/lee/project/potato-mubwanna/backend
./gradlew test --tests '*PotatoSpotClassifierTest' --tests '*TourApiSpotImportServiceTest'
```

```bash
cd /Users/mac/Desktop/lee/project/potato-mubwanna
/Users/mac/Documents/flutter/bin/dart format frontend/lib/features/map/domain/map_spot.dart frontend/lib/features/map/presentation/screen/map_screen.dart
```

### 남은 리스크

- 모바일 지도 위 핀은 현재 Flutter 오버레이 방식의 1차 보강이다. 실제 확대/축소/드래그와 완전히 연동되는 SDK 네이티브 마커는 Android/iOS별 후속 구현이 필요하다.
- TourAPI만으로 트렌디한 카페/브루어리 전체를 찾는 데는 한계가 있다. 카카오 Local API 기반 보강 수집은 별도 작은 커밋으로 추가하는 것이 좋다.

---

## 2026-06-20 Kakao Local API 스팟 수집 추가

### 작업 목표

- 한국관광공사 TourAPI만으로 누락되는 감자빵, 카페, 체험, 알감자, 로컬푸드, 감자 맥주, 직판장 후보를 Kakao Local API로 보강한다.
- 기존 `tourist_spots` 테이블에 `KAKAO_LOCAL` 출처로 함께 upsert한다.
- 지도 상단의 `저장된 감자 스팟 N곳` 배지를 제거하고, 카테고리 필터를 화면 위쪽에 바로 노출한다.
- 감자 핀은 카테고리별 색상을 사용하고 희귀/강조 핀은 노란색 계열로 표시한다.

### 변경 요약

- `KakaoLocalClient` 추가
  - `KAKAO_REST_API_KEY`를 이용해 Kakao Local keyword search API 호출
  - 기본 키워드: `강원 감자빵`, `강릉 감자빵`, `춘천 감자 카페`, `평창 감자 체험`, `강원 감자전`, `강원 옹심이`, `강원 알감자`, `강원 로컬푸드 감자`, `강원 감자 맥주`, `강원 감자 직판장`
- `TourApiSpotImportService`
  - TourAPI import 후 Kakao Local import도 함께 수행
  - `KAKAO_LOCAL:{placeId}` content id로 저장
  - 같은 이름/주소로 이미 존재하면 기존 row를 업데이트
- `TouristSpot`
  - `source`를 `TOUR_API` 외 값으로도 저장/업데이트 가능하게 확장
- Frontend map
  - 상단 개수 배지 제거
  - 필터를 더 위쪽으로 이동
  - 카테고리별 marker color 추가
  - Web Kakao CustomOverlay marker border 색상에 category color 반영
- Web bootstrap
  - `FlutterLoader.load requires _flutter.buildConfig to be set` 오류 대응을 위해 `flutter_bootstrap.js` 초기화 방식으로 변경

### 환경변수

```properties
KAKAO_REST_API_KEY=...
KAKAO_LOCAL_KEYWORD_SEARCH_URL=https://dapi.kakao.com/v2/local/search/keyword.json
KAKAO_LOCAL_SPOT_KEYWORDS=강원 감자빵,강릉 감자빵,춘천 감자 카페,평창 감자 체험,강원 감자전,강원 옹심이,강원 알감자,강원 로컬푸드 감자,강원 감자 맥주,강원 감자 직판장
```

### 실행한 검증

```bash
git diff --check
git diff --cached --check
```

결과: 성공

```bash
cd backend
GRADLE_USER_HOME=$PWD/.gradle ./gradlew --no-daemon test --tests '*PotatoSpotClassifierTest' --tests '*TourApiSpotImportServiceTest'
```

결과: 실패. 현재 Codex 샌드박스가 Gradle `FileLockContentionHandler`의 소켓 생성을 막아 테스트가 시작되지 못했다.

```bash
/Users/mac/Documents/flutter/bin/dart format frontend/lib/features/map/domain/map_spot.dart frontend/lib/features/map/presentation/screen/map_screen.dart frontend/lib/features/map/presentation/widget/kakao_map_view_web.dart
```

결과: 실패. Flutter SDK cache 경로 쓰기 권한이 없어 format 실행 전 단계에서 실패했다.

### 남은 리스크

- 실제 Kakao Local API 호출은 사용자의 로컬 백엔드에서 `KAKAO_REST_API_KEY`가 설정된 상태로 재시작해야 확인할 수 있다.
- 네이버 검색 API는 아직 붙이지 않았다. 붙일 경우 `NAVER_CLIENT_ID`, `NAVER_CLIENT_SECRET`을 별도로 발급받아 서버 환경변수로 관리해야 한다.

---

## 2026-06-21 iOS 감자 핀 좌표 고정 보강

### 작업 목표

- iOS 지도에서 감자 핀이 보이지 않거나 화면 스티커처럼 동작하지 않도록, 스팟 좌표를 KakaoMapsSDK POI에 안정적으로 전달한다.
- Flutter 지도 뷰가 스팟 목록 변경 후에도 기존 빈 platform view를 재사용하지 않도록 한다.
- 지도 필터와 바텀시트에서 `술` 표현을 `바 & 페어링`으로 바꾼다.

### 원인

- Flutter `StandardMessageCodec`가 iOS 네이티브로 넘기는 숫자는 Swift에서 `Double`이 아니라 `NSNumber`로 들어올 수 있다.
- 기존 iOS 네이티브 코드는 `as? Double`만 허용했기 때문에 좌표 파싱이 실패하면 모든 스팟을 건너뛰었다.
- 지도 platform view는 스팟 목록이 빈 상태로 처음 생성된 뒤 같은 key로 재사용될 수 있어, API 데이터가 뒤늦게 들어와도 마커가 갱신되지 않을 수 있었다.

### 변경 요약

- `frontend/ios/Runner/NativeKakaoMapView.swift`
  - `NSNumber`, `String`, `Double`을 모두 좌표 숫자로 처리하는 파서 추가
  - `NSDictionary`, `[String: Any]`, `[AnyHashable: Any]` 형태의 스팟 map을 모두 처리
  - 실제 KakaoMapsSDK `LabelLayer`/`PoiOptions`에 `MapPoint(longitude, latitude)`로 마커 추가
- `frontend/lib/features/map/presentation/screen/map_screen.dart`
  - 스팟 id 목록 hash를 `KakaoMapView` key로 사용해 스팟 목록 변경 시 platform view 재생성
  - 필터 라벨 `술`을 `바 & 페어링`으로 변경
- `frontend/lib/features/map/domain/map_spot.dart`
  - `POTATO_BREWERY` 표시 라벨을 `바 & 페어링`으로 변경
  - 감자 이름을 `페어링감자`로 변경

### 로컬 API 카테고리 확인

```bash
curl -sS http://localhost:8080/api/spots | jq -r '.data[].category' | sort | uniq -c
```

결과:

```text
2 POTATO_BREWERY
25 POTATO_CAFE
1 POTATO_MARKET
29 POTATO_RESTAURANT
2 POTATO_SNACK
```

현재 로컬 DB 응답에는 `POTATO_TOUR`, `POTATO_EXPERIENCE`가 없으므로 관광/체험 필터는 빈 상태가 정상이다. 관광/체험 스팟을 보려면 TourAPI/Kakao Local 수집 키워드 또는 수동 seed에서 해당 카테고리 데이터를 추가해야 한다.

### 실행한 검증

```bash
/Users/mac/Documents/flutter/bin/dart format lib/features/map/presentation/screen/map_screen.dart lib/features/map/domain/map_spot.dart
```

결과: 성공

```bash
/Users/mac/Documents/flutter/bin/flutter analyze
```

결과: 성공. `flutter_secure_storage`의 Swift Package Manager 미지원 경고만 표시되었고 분석 오류는 없음.

```bash
/Users/mac/Documents/flutter/bin/flutter build ios --simulator --debug --dart-define=KAKAO_NATIVE_APP_KEY=dummy --dart-define=KAKAO_JAVASCRIPT_KEY=dummy --dart-define=API_BASE_URL=http://localhost:8080
```

결과: 성공. `build/ios/iphonesimulator/Runner.app` 생성.

### 남은 리스크

- 실제 지도 핀 표시 여부는 사용자의 iOS Simulator에서 `KAKAO_NATIVE_APP_KEY`, `API_BASE_URL`을 실제 값으로 넣어 `flutter run` 후 확인해야 한다.
- 관광/체험 카테고리는 현재 DB에 데이터가 없으므로, 별도 데이터 수집 키워드 보강이나 seed 추가가 필요하다.

---

## 2026-06-21 iOS POI 표시 호출 누락 수정

### 작업 목표

- iOS에서 KakaoMapsSDK POI가 좌표에는 추가되지만 화면에 표시되지 않는 문제를 수정한다.

### 원인

- KakaoMapsSDK 헤더 주석에 따르면 `LabelLayer.visible`이 true여도 layer 내부 객체는 `show()`를 호출해야 화면에 표시된다.
- 기존 구현은 `layer.addPoi(...)`까지만 호출하고 반환된 `Poi`에 `show()`를 호출하지 않았다.

### 변경 요약

- `frontend/ios/Runner/NativeKakaoMapView.swift`
  - 스팟 layer `visible = true` 설정
  - `addPoi(...)?.show()` 호출
  - 모든 POI 추가 후 `layer.showAllPois()` 호출
  - 지도 갱신을 위해 `mapView.refresh()` 호출

### 실행한 검증

```bash
git diff --check
```

결과: 성공

```bash
/Users/mac/Documents/flutter/bin/flutter build ios --simulator --debug --dart-define=KAKAO_NATIVE_APP_KEY=dummy --dart-define=KAKAO_JAVASCRIPT_KEY=dummy --dart-define=API_BASE_URL=http://localhost:8080
```

결과: 성공. `build/ios/iphonesimulator/Runner.app` 생성.

```bash
/Users/mac/Documents/flutter/bin/flutter analyze
```

결과: 성공. `flutter_secure_storage` Swift Package Manager 미지원 경고만 표시되었고 분석 오류는 없음.

### 남은 리스크

- 실제 핀 표시 확인은 사용자 iOS Simulator에서 실제 `KAKAO_NATIVE_APP_KEY`, `API_BASE_URL`을 넣어 앱을 재실행해 확인해야 한다.

---

## 2026-06-21 지도 핀 선택, 줌 크기, 내 동선 저장 UI

### 작업 목표

- 지도 핀이 너무 크게 보이는 문제를 줄인다.
- 지도 확대/축소 단계에 따라 핀 크기가 달라지도록 한다.
- 핀을 탭하면 하단 장소 카드가 해당 핀의 장소 정보로 바뀌도록 한다.
- 즐겨찾기 버튼으로 사용자가 나만의 동선 후보를 저장할 수 있는 UI를 추가한다.

### 변경 요약

- `frontend/lib/features/map/presentation/screen/map_screen.dart`
  - 선택된 스팟 ID를 받아 하단 카드 상태를 갱신하도록 연결.
  - 하단 장소 카드에 북마크 버튼과 `내 동선 N곳 저장됨` 상태 표시 추가.
- `frontend/lib/features/map/presentation/widget/kakao_map_view_web.dart`
  - CustomOverlay 마커 크기를 축소.
  - Kakao Web 지도 `zoom_changed` 이벤트에 맞춰 마커 scale 적용.
  - 마커 클릭 시 Flutter 쪽으로 `spot.id` 전달.
- `frontend/lib/features/map/presentation/widget/kakao_map_view_native.dart`
  - Android/iOS PlatformView 생성 후 MethodChannel로 `spotSelected` 이벤트 수신.
- `frontend/ios/Runner/NativeKakaoMapView.swift`
  - POI 탭 이벤트를 MethodChannel로 전달.
  - 지도 카메라 정지 시 zoom level에 따라 POI style을 small/medium/large로 변경.
- `frontend/android/app/src/main/kotlin/com/gamjamubwatna/frontend/NativeKakaoMapView.kt`
  - Label 클릭 이벤트를 MethodChannel로 전달.
  - 카메라 이동 종료 시 label scale 조정.
- `frontend/ios/Flutter/AppFrameworkInfo.plist`
  - Firebase iOS Swift Package 요구사항에 맞춰 `MinimumOSVersion`을 15.0으로 명시.

### 실행한 검증

```bash
/Users/mac/Documents/flutter/bin/dart format lib/features/map/presentation/screen/map_screen.dart lib/features/map/presentation/widget/kakao_map_view_native.dart lib/features/map/presentation/widget/kakao_map_view_stub.dart lib/features/map/presentation/widget/kakao_map_view_web.dart
```

결과: 성공

```bash
/Users/mac/Documents/flutter/bin/flutter analyze
```

결과: 성공. `flutter_secure_storage` Swift Package Manager 미지원 경고만 표시되었고 분석 오류는 없음.

```bash
cd frontend/android && ./gradlew :app:compileDebugKotlin --no-daemon
```

결과: 성공. Kotlin deprecation 및 unchecked cast 경고만 표시됨.

```bash
PATH="/usr/local/lib/ruby/gems/4.0.0/bin:/usr/local/opt/ruby/bin:$PATH" /Users/mac/Documents/flutter/bin/flutter build ios --simulator --debug --dart-define=KAKAO_NATIVE_APP_KEY=dummy --dart-define=KAKAO_JAVASCRIPT_KEY=dummy --dart-define=API_BASE_URL=http://localhost:8080
```

결과: 성공. `build/ios/iphonesimulator/Runner.app` 생성.

### 발생한 문제와 해결

- iOS 빌드에서 Firebase Swift Package가 iOS 15 이상을 요구했지만 Flutter 프레임워크 정보에 최소 OS 버전이 명시되지 않아 빌드가 실패했다.
- `frontend/ios/Flutter/AppFrameworkInfo.plist`에 `MinimumOSVersion=15.0`을 추가해 프로젝트의 Podfile/Xcode target 설정과 맞췄다.
- `flutter clean`은 Xcode workspace 정리 단계에서 멈춰 `frontend/build/ios` 산출물만 삭제한 뒤 `flutter pub get`과 iOS 빌드를 재실행했다.

### 남은 리스크

- 즐겨찾기 상태는 현재 화면 상태 메모리에만 저장된다. 앱 재시작 후 유지하려면 로컬 저장소나 백엔드 저장 API가 필요하다.
- 실제 핀 선택과 줌별 크기 변화는 사용자의 iOS Simulator 또는 Android 기기에서 실제 Kakao 키와 백엔드 URL을 넣어 `flutter run`으로 확인해야 한다.

---

## 2026-06-21 iOS 핀 선택 이벤트와 Web 카카오 로그인 안정화

### 작업 목표

- iOS Kakao 지도에서 핀을 탭해도 하단 장소 카드가 바뀌지 않는 문제를 수정한다.
- Chrome Web에서 카카오 로그인 팝업이 안정적으로 열리도록 Kakao JavaScript SDK 준비 타이밍을 개선한다.

### 원인

- iOS KakaoMapsSDK의 optional delegate 메서드만으로 POI 탭 이벤트를 받는 방식이 실제 시뮬레이터 동작에서 안정적이지 않았다.
- Web 카카오 로그인은 버튼 클릭 후 SDK를 비동기로 로드하면 브라우저가 로그인 팝업을 사용자 직접 동작이 아닌 팝업으로 판단해 막을 수 있다.

### 변경 요약

- `frontend/ios/Runner/NativeKakaoMapView.swift`
  - `KakaoMap.addPoisTappedEventHandler`를 추가해 POI 탭 이벤트를 직접 수신한다.
  - 수신한 `poiID`를 기존 MethodChannel `spotSelected` 이벤트로 Flutter에 전달한다.
  - 네이티브 이벤트 핸들러는 view 해제 시 dispose한다.
- `frontend/lib/features/auth/data/kakao_login_service_web.dart`
  - `preload()`를 추가해 Kakao JavaScript SDK를 미리 로드하고 초기화한다.
- `frontend/lib/features/auth/data/kakao_login_service_native.dart`
  - 플랫폼 공통 호출을 맞추기 위해 no-op `preload()`를 추가한다.
- `frontend/lib/features/auth/data/kakao_login_service_stub.dart`
  - 플랫폼 공통 호출을 맞추기 위해 no-op `preload()`를 추가한다.
- `frontend/lib/features/auth/presentation/screen/login_screen.dart`
  - 로그인 화면 진입 시 SDK preload를 시작한다.

### 실행한 검증

```bash
/Users/mac/Documents/flutter/bin/dart format lib/features/auth/data/kakao_login_service_web.dart lib/features/auth/data/kakao_login_service_native.dart lib/features/auth/data/kakao_login_service_stub.dart lib/features/auth/presentation/screen/login_screen.dart
```

결과: 성공

```bash
/Users/mac/Documents/flutter/bin/flutter analyze
```

결과: 성공. `flutter_secure_storage` Swift Package Manager 미지원 경고만 표시되었고 분석 오류는 없음.

```bash
/Users/mac/Documents/flutter/bin/flutter build web --dart-define=KAKAO_JAVASCRIPT_KEY=dummy --dart-define=KAKAO_NATIVE_APP_KEY=dummy --dart-define=API_BASE_URL=http://localhost:8080
```

결과: 성공. Wasm dry run 및 Cupertino icon 경고만 표시되었고 `build/web` 생성.

```bash
PATH="/usr/local/lib/ruby/gems/4.0.0/bin:/usr/local/opt/ruby/bin:$PATH" /Users/mac/Documents/flutter/bin/flutter build ios --simulator --debug --dart-define=KAKAO_NATIVE_APP_KEY=dummy --dart-define=KAKAO_JAVASCRIPT_KEY=dummy --dart-define=API_BASE_URL=http://localhost:8080
```

결과: 성공. `build/ios/iphonesimulator/Runner.app` 생성.

### 남은 리스크

- iOS 핀 탭 동작은 실제 Kakao 키와 백엔드 URL을 넣어 앱을 완전히 재실행한 뒤 확인해야 한다.
- Chrome 카카오 로그인은 Kakao Developers Web 플랫폼에 실행 origin이 등록되어 있어야 한다. 예: `http://127.0.0.1:54631`.

---

## 지도 작업 후속 보완 정리

### 나중에 보완하면 좋은 작업

- 즐겨찾기 영속화
  - 현재 `내 동선 N곳 저장됨`은 화면 메모리에만 저장된다.
  - 앱 재실행 후에도 유지하려면 `shared_preferences` 기반 로컬 저장 또는 백엔드 즐겨찾기 API가 필요하다.
  - 추천 API 예시: `POST /me/favorite-spots`, `DELETE /me/favorite-spots/{spotId}`, `GET /me/favorite-spots`.
- 내 동선 생성 기능
  - 즐겨찾기한 스팟을 지도 위 Polyline으로 연결하는 기능이 필요하다.
  - 카카오 지도 Web/Native 양쪽에 경로선 렌더링 구현이 필요하다.
  - 이후 방문 순서 추천, 거리/예상 이동 시간 표시로 확장할 수 있다.
- 지도 데이터 품질 보강
  - 현재 카테고리별 데이터가 음식점/카페 중심이다.
  - 관광, 체험, 직판장, 바 & 페어링, 간식 카테고리는 키워드 보강 또는 수동 seed 데이터가 더 필요하다.
  - TourAPI/Kakao Local 결과를 그대로 쓰기보다 운영 검수 상태(`PENDING`, `APPROVED`, `HIDDEN`)를 두는 것이 좋다.
- 지도 클러스터링
  - 스팟 수가 늘어나면 마커가 겹친다.
  - zoom level에 따라 cluster marker를 보여주고 확대 시 개별 핀으로 풀리는 UX가 필요하다.
- 위치 기반 현재 주변 스팟
  - 현재는 수집된 전체 스팟을 지도에 표시한다.
  - 사용자 현재 위치 기준 반경 검색 API와 연동하면 MVP 완성도가 올라간다.
- 실제 기기 검증
  - Android는 Kakao Maps SDK 네이티브 라이브러리 아키텍처 이슈가 있을 수 있으므로 실제 기기 검증이 필요하다.
  - iOS는 실제 Kakao Native key, bundle id 등록 상태에서 핀 탭/지도 이동/로그인 딥링크를 확인해야 한다.
- Web 로그인 고도화
  - 현재 Web은 Kakao JavaScript SDK popup 로그인 기반이다.
  - 팝업 차단, 도메인 등록, 브라우저 보안 정책에 민감하므로 장기적으로는 백엔드 OAuth redirect flow를 분리하는 편이 더 안정적이다.

### 사용자에게 남은 확인 작업

- Kakao Developers 설정 확인
  - Web 플랫폼: 실제 실행 origin 등록. 예: `http://127.0.0.1:54631`.
  - iOS 플랫폼: bundle id `com.gamjamubwatna.frontend` 등록.
  - Android 플랫폼: package name `com.gamjamubwatna.frontend`와 key hash 등록.
- 로컬 실행 환경 변수 확인
  - `KAKAO_JAVASCRIPT_KEY`
  - `KAKAO_NATIVE_APP_KEY`
  - `API_BASE_URL`
  - Web 실행 시 랜덤 포트 대신 `--web-hostname 127.0.0.1 --web-port 54631`로 고정한다.
- 백엔드 실행 확인
  - DB Docker/PostgreSQL이 켜져 있어야 한다.
  - 스팟 수집 후 `tourist_spots` 테이블에 데이터가 들어와야 지도 핀이 보인다.
  - Web/앱 로그인까지 확인하려면 백엔드 `/api/auth/kakao`가 접근 가능해야 한다.
- 앱 재설치 또는 완전 재실행
  - iOS/Android 네이티브 코드 변경 후에는 hot reload만으로 반영되지 않을 수 있다.
  - 앱을 완전히 종료하고 다시 `flutter run`을 실행한다.
