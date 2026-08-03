# Issue #247 검증 기록

## 작업 요약

- 이슈: #247
- 브랜치: `feat/247-tourist-attraction-catalog`
- 담당 영역: 관광지 seed migration 및 migration/API 테스트
- 제외 범위: 랠리북 다중 명소 UI, 스탬프 이미지, 메뉴·가격
- 목표: 사용자 지정 관광지를 추측 좌표가 아닌 한국관광공사 TourAPI 공식 데이터로 연결

## 변경 파일

- `backend/src/main/resources/db/migration/V24__seed_official_gangwon_attractions.sql`: 18개 시군 29개 고유 명소의 공식 콘텐츠 ID·좌표·주소·대표 이미지 반영
- `backend/src/test/java/com/gamjamubwatna/spot/domain/TouristSpotMigrationTest.java`: 공식 카탈로그와 공개 API 회귀 검증
- `artifacts/validation/issue-247/TOUR_API_AUDIT.md`: 공식 응답 대조표와 이름 해석 기록

## 공유 파일 / 계약 변경

- 공유 위험 파일: Flyway migration 추가
- API 계약 변경: 없음
- DB migration: V24 신규 추가, 기존 migration 수정 없음
- 환경 변수: 실행 시 기존 `TOUR_API_SERVICE_KEY` 사용, 커밋에는 값 미포함
- 외부 API: 한국관광공사 `KorService2`

## 검증

- 실행: `gradlew.bat test --tests "com.gamjamubwatna.spot.domain.TouristSpotMigrationTest"`
- 결과: 통과
- 실행: `gradlew.bat test`
- 결과: 전체 79개 suite, 367개 테스트 통과, 실패/오류/건너뜀 0개
- 실행: 한국관광공사 `searchKeyword2`, `detailCommon2`, `detailImage2` 대조
- 결과: 18개 시군 29개 고유 장소의 공식 데이터 확인
- 실패했던 시도: 첫 전체 테스트 호출 창이 먼저 종료됐지만 자식 Gradle 테스트가 계속 실행되어, 즉시 시작한 두 번째 호출이 결과 파일 잠금으로 실패
- 해결: 먼저 시작된 프로세스 완료 후 XML 결과(367개, 실패 0)를 집계하고 `gradlew.bat test`를 다시 실행해 성공 확인
- 실행하지 못한 명령: 없음

## 산출물

- 검증 기록: 이 파일
- API 대조표: `TOUR_API_AUDIT.md`
- 화면/API 캡처: 후속 로컬 백엔드 API 검증에서 추가 예정

## 남은 리스크

- 정선 5일장과 아리랑시장은 동일한 공식 관광 콘텐츠이므로 한 마커로 취급한다.
- 비발디파크는 계절 중립 이름을 유지하되 공식 스키장 중심 좌표를 사용한다.
- 운영 DB에 같은 TourAPI 콘텐츠가 이미 동기화된 경우 기존 curated PK는 이력 보존을 위해 비활성화한다.

## 다음 작업

- 이어서 실행할 명령: `gradlew.bat test`
- 확인해야 할 파일: 랠리북 시군별 명소 선택/좌표 투영 코드
- 조율이 필요한 사람 또는 이슈: #244
