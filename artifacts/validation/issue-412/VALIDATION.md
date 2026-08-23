# Issue #412 Validation

## 작업 요약

- 장소 목록/상세 API의 `imageUrl`을 서버에서 최종 대표 이미지로 정규화하도록 수정했다.
- 우선순위는 `tourist_spots.image_url` -> TourAPI `detailImage2` -> `null`이다.
- 프론트 지도 홈, 여행 코스 카드, 코스 상세, 지금 가기 좋은 곳은 서버에서 내려온 `imageUrl`을 먼저 사용하고 실패 시 기존 앱 asset/placeholder를 사용한다.

## PAR

### Problem

지도와 여행 코스 UI가 장소 이미지가 없을 때 로컬 asset에 의존하고 있었다. 이 구조는 실제 장소 데이터가 늘어날수록 이미지 품질이 흔들리고, 프론트가 외부 API를 직접 호출하면 API 키 관리와 호출량 문제가 생길 수 있었다.

### Action

- 백엔드에 `SpotImageResolver`를 추가해 저장된 이미지가 없고 TourAPI `contentId`가 있는 경우에만 `detailImage2`를 조회하도록 했다.
- `TourApiClient`에 `detailImage2` 호출과 `originimgurl/imgurl/smallimageurl` 후보 선택 로직을 추가했다.
- 외부 API 실패는 장소 조회 실패로 전파하지 않고 로그만 남긴 뒤 `imageUrl=null`로 처리했다.
- 프론트 `MapSpot`에 `imageUrl`을 추가하고 여행 코스/장소 카드의 이미지 렌더링 우선순위를 `network image -> local asset -> app placeholder`로 정리했다.
- 혼잡도 배지는 라벨에 이미 `혼잡도`가 포함된 경우 중복 prefix를 붙이지 않도록 정리했다.
- API 문서에 `/spots` 목록과 상세의 `imageUrl` fallback 규칙을 추가했다.

### Result

장소/코스 화면은 프론트에서 TourAPI를 직접 호출하지 않고도 서버 응답의 대표 이미지를 사용할 수 있게 되었다. TourAPI 키는 백엔드 환경변수로만 관리하며, 외부 API가 실패해도 장소 데이터는 정상 표시된다.

## 테스트

| 항목 | 결과 |
| --- | --- |
| `./gradlew test --tests "com.gamjamubwatna.spot.application.SpotImageResolverTest" --tests "com.gamjamubwatna.spot.infrastructure.TourApiClientTest" --tests "com.gamjamubwatna.spot.application.SpotServiceTest" --tests "com.gamjamubwatna.spot.api.SpotControllerTest"` | PASS |
| `./gradlew test` | PASS |
| `flutter analyze` | PASS |
| `flutter test test/features/map/map_spot_test.dart test/features/map/spot_recommendation_repository_test.dart test/features/map/travel_course_catalog_test.dart` | PASS |
| `flutter test` | PASS |
| `flutter test test/features/map/travel_course_catalog_test.dart test/features/map/map_spot_test.dart test/features/map/spot_recommendation_repository_test.dart` | PASS |

## 남은 확인

- 운영 환경에 `TOUR_API_SERVICE_KEY`가 설정되어 있어야 `detailImage2` fallback이 동작한다.
- 지도 메인/코스 카드 이미지가 실제 TourAPI 이미지로 바뀌려면 해당 장소가 숫자형 TourAPI `contentId`를 가지고 있거나 DB `image_url`이 채워져 있어야 한다.
- 실제 TourAPI 응답의 이미지 라이선스/출처 메타데이터를 별도 표기해야 하는 정책이 생기면 스키마 확장을 검토해야 한다.
