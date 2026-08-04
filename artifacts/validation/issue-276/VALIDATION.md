# Issue 276 검증 기록

## 작업 목표

- 지도 카드의 대표 메뉴와 가격을 사업자 공식 홈페이지, 공식 SNS, 공식 채널 또는 사업자가 연결한 예약 페이지의 정보로 교정한다.
- 공식 가격을 확인할 수 없는 메뉴는 임의 가격 대신 `매장 가격 확인`으로 제공한다.

## 진행 과정

- 기존 V26 migration이 Kakao 장소 페이지의 메뉴를 수기로 저장하고 있음을 확인했다.
- 카페감자밭 공식몰, 감자적1번지 Catchtable 매장 페이지, 강릉길감자 공식 Instagram, 감자아일랜드 공식 Kakao 채널을 대조했다.
- 이미 반영된 V26은 수정하지 않고 V28 migration에서 대상 네 장소의 기존 메뉴만 교체했다.

## 발생한 문제점과 해결

- 감자밭 공식몰 가격은 매장 단품 가격이 아니라 10개입 온라인 상품 가격이었다. 메뉴명에 `10개입 (공식몰)`을 명시해 단품 가격으로 오해하지 않게 했다.
- 감자아일랜드 공식 채널은 대표 메뉴를 제공하지만 가격을 공개하지 않았다. 임의 가격을 넣지 않고 `매장 가격 확인`으로 저장했다.
- 강릉길감자는 공식 Instagram 게시물에 오프라인 매장 가격이 명시된 두 메뉴만 저장했다.
- 저장소 루트에서 `./gradlew.bat`를 호출한 한 번의 검증은 실행 파일 경로가 없어 실패했다. `backend` 디렉터리에서 같은 테스트를 다시 실행해 통과했다.

## 변경 파일

- `backend/src/main/resources/db/migration/V28__replace_tourist_spot_menus_with_official_sources.sql`
- `backend/src/test/java/com/gamjamubwatna/spot/domain/TouristSpotMigrationTest.java`
- `artifacts/validation/issue-276/VALIDATION.md`

## 검증

- `backend\\gradlew.bat test --tests com.gamjamubwatna.spot.domain.TouristSpotMigrationTest`
  - 결과: 성공 (`BUILD SUCCESSFUL`)
  - 확인: V1~V28 migration 적용, 활성 공식 메뉴 9개, 비공식 이전 메뉴 미노출
- `backend\\gradlew.bat build`
  - 결과: 성공 (`BUILD SUCCESSFUL`)
  - 확인: 전체 백엔드 테스트, JAR 및 bootJar 생성

## 남은 리스크

- 메뉴와 가격은 사업자가 변경할 수 있으므로 `verified_on` 이후에는 재검증이 필요하다.
- 감자아일랜드 가격은 공식 채널에 공개되지 않아 앱에서 `매장 가격 확인`으로 표시된다.
