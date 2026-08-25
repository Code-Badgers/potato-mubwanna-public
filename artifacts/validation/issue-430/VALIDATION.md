# Issue #430 Validation

## Scope

- 지도/여행 코스에서 추천·연관 장소 이미지가 비어 보이는 원인을 확인했다.
- 일반 장소 목록/상세 응답은 기존 이미지 보강 흐름을 사용하고 있었지만, 연관 장소 추천 응답은 DB의 `imageUrl`만 내려서 Google Places 또는 TourAPI fallback 이미지가 누락될 수 있었다.
- 추천 장소 응답에 `imageUrls`를 추가하고, 기존 이미지 보강 우선순위를 재사용하도록 수정했다.

## Image Fallback Order

1. 서버 DB에 저장된 장소 이미지
2. Google Places 보강 이미지
3. TourAPI 이미지
4. 프론트 기본 placeholder

## Verification

- Backend targeted tests
  - `./gradlew test --tests com.gamjamubwatna.spot.application.SpotRecommendationServiceTest --tests com.gamjamubwatna.spot.api.SpotRecommendationControllerTest`
  - Result: PASS
- Flutter analyze
  - `/Users/mac/Documents/flutter/bin/flutter analyze`
  - Result: PASS
- Flutter map tests
  - `/Users/mac/Documents/flutter/bin/flutter test test/features/map`
  - Result: PASS

## Notes

- 실제 운영 이미지 노출은 백엔드 실행 환경에 Google Places / TourAPI 키가 설정되어 있고, 장소명·주소 또는 TourAPI `contentId`가 외부 API와 매칭되어야 한다.
- API key 값은 검증 기록과 로그에 남기지 않았다.
