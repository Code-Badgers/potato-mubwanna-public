# Issue 420 Validation

## Scope

- 지도 크게보기 Bottom Sheet에 장소별 상세 정보를 보강했다.
- 백엔드 장소 상세 응답에 `imageUrls`, `menuItems`를 포함했다.
- 프론트 지도 장소 카드에서 도로명주소, 최대 3장 이미지 갤러리, TourAPI 관광 정보, 대표 메뉴를 표시한다.

## Implementation Notes

- 카카오 지도/로컬 API는 장소 검색, 주소, 전화번호, Kakao place URL 중심이며 공식 장소 사진이나 메뉴판 이미지를 안정적으로 제공하지 않는다.
- 장소 이미지는 기존 서버 `imageUrl`을 1순위로 사용하고, 없거나 상세 갤러리가 필요한 경우 한국관광공사 TourAPI `detailCommon2`, `detailImage2` 이미지를 사용한다.
- 음식점/카페 메뉴는 기존 `tourist_spot_menu_items` 데이터를 사용한다. 메뉴판 이미지 전체 수집은 이번 범위에 포함하지 않았다.
- TourAPI 외부 장애는 장소 상세 조회 실패로 전파하지 않고 이미지/관광 정보 fallback으로 처리한다.
- 상세 갤러리는 내부 이미지와 TourAPI 이미지를 중복 제거해 최대 3장까지 내려준다.
- 첫 TourAPI 대표 이미지는 기존 캐시 작성기를 통해 `imageUrl`에 저장될 수 있다. 추가 갤러리 이미지는 DB migration 없이 resolver 캐시로 보강했다.

## API Shape

- `GET /spots/{id}` 응답 보강:
  - `address`
  - `imageUrl`
  - `imageUrls`
  - `menuItems`
  - `tourInfo`

## Validation

| Command | Result |
| --- | --- |
| `cd backend && ./gradlew test --tests 'com.gamjamubwatna.spot.application.SpotServiceTest' --tests 'com.gamjamubwatna.spot.application.SpotImageResolverTest' --tests 'com.gamjamubwatna.spot.infrastructure.TourApiClientTest'` | PASS |
| `cd backend && ./gradlew test` | PASS |
| `cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze` | PASS |
| `cd frontend && /Users/mac/Documents/flutter/bin/flutter test test/features/map/spot_recommendation_repository_test.dart test/features/map/map_screen_test.dart` | PASS |

## Remaining Risks

- TourAPI 이미지 보강은 숫자형 `contentId`가 있는 장소에 한해 동작한다. 자체 curated 장소나 Kakao-only 장소는 별도 imageUrl 또는 TourAPI contentId 매핑이 필요하다.
- 카카오 API에서 메뉴판 이미지나 장소 사진을 직접 가져오는 구조는 제공 API 특성상 적용하지 않았다.
- 실제 Kakao Map WebView에서 Bottom Sheet 확장 시 이미지 로딩과 스크롤 체감은 실기기에서 마지막 확인이 필요하다.
