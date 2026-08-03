## 작업 요약

- 이슈: #251 `feat: 랠리북 공식 관광지 29곳 위치 표시 및 선택`
- 브랜치: `feat/251-rallybook-attraction-markers`
- 담당 영역: 랠리북 관광지 카탈로그 API, 공식 좌표 기반 마커 표시, 같은 시군의 복수 관광지 선택
- 제외 범위: 지도 홈 카드의 메뉴·가격, 스탬프 이미지·애니메이션, 여행기록 이미지, 온보딩
- 목표: 지정 관광지 29곳을 실제 좌표로 랠리북에 표시하고, 마커 또는 같은 시군 장소 칩을 선택하면 카드 내용과 선택 마커가 함께 바뀌게 한다.

## 변경 파일

- `backend/src/main/resources/db/migration/V25__feature_rallybook_tourist_spots.sql`: 공식 관광지 29곳을 랠리북 노출 대상으로 표시한다.
- `backend/src/main/java/com/gamjamubwatna/spot/domain/TouristSpot.java`: 랠리북 노출 여부를 저장한다.
- `backend/src/main/java/com/gamjamubwatna/spot/domain/TouristSpotRepository.java`: 활성 랠리북 관광지를 조회한다.
- `backend/src/main/java/com/gamjamubwatna/stamp/api/RallybookSpotResponse.java`: 랠리북 관광지 응답 계약을 정의한다.
- `backend/src/main/java/com/gamjamubwatna/stamp/api/StampController.java`: `GET /api/stamps/rallybook-spots`를 제공한다.
- `backend/src/main/java/com/gamjamubwatna/stamp/application/StampQueryService.java`: 시군 스탬프 순서와 관광지명으로 정렬한다.
- `frontend/lib/features/stamp/**`: 랠리북 관광지 조회, EPSG:5179 좌표 투영, 마커·카드 선택을 연결한다.
- `backend/src/test/**`, `frontend/test/**`: API 보안·응답·migration·좌표·화면 전환을 검증한다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: `agents_docs/07_api_specification.md`, 새 Flyway migration, 신규 API 응답 DTO
- API 계약 변경: 인증이 필요한 `GET /api/stamps/rallybook-spots` 추가. 응답은 `spotId`, `spotName`, `cityName`, `category`, `latitude`, `longitude`, `address`, `imageUrl`을 포함한다.
- DB migration: V25에서 `tourist_spot.rallybook_featured` 컬럼과 조회 인덱스를 추가하고 V24의 공식 관광지 29곳만 활성화한다.
- 환경 변수: 추가 없음
- 외부 API: 런타임 외부 호출 추가 없음. V24에서 저장한 TourAPI 공식 관광지 데이터를 사용한다.

## 검증

- 실행: `backend\\gradlew.bat test`
- 결과: 성공, 371개 테스트 통과
- 실행: `flutter analyze`
- 결과: 성공, 이슈 없음
- 실행: `flutter test`
- 결과: 성공, 239개 테스트 통과
- 실행: Android ARM64 디버그 APK 빌드·설치 후 `emulator-5554`에서 랠리북 진입 및 장소 전환
- 결과: 관광지 29곳 마커 표시, 남이섬 선택 후 소양강 스카이워크 칩 선택 시 마커·이름·주소가 함께 갱신됨
- 실행: 로컬 PostgreSQL에 V24/V25 적용 후 랠리북 대상 집계 및 API 호출
- 결과: 29개 관광지, 18개 시군, 좌표 누락 0개
- 실패 이력: 첫 전체 `flutter analyze`에서 새 위치 정합성 테스트의 불필요한 import 1건이 발견됐다. 해당 import만 제거한 뒤 전체 정적 검사와 테스트를 다시 통과했다.
- 실패 이력: 위치 정합성 테스트를 처음에는 모든 점이 단순화된 시군 폴리곤 내부여야 한다고 가정했으나, 공식 장호항 좌표가 단순화된 삼척 해안선 밖에 근소하게 위치했다. 임의 좌표 수정 대신 장호항만 정규화 거리 0.015 이내의 해안 경계 예외로 명시하고, 다른 28곳에는 엄격한 내부 판정을 유지했다.
- 실패 이력: 실행 로그를 저장소 밖으로 옮기려던 첫 정리 명령이 관리 셸까지 넓게 식별해 중간 종료됐다. 저장소 변경은 없었고, 8080 리스너와 잠금 해제 상태를 다시 확인한 뒤 로그만 삭제하고 백엔드를 시스템 임시 로그 경로로 재실행했다.

## 산출물

- 검증 기록: `artifacts/validation/issue-251/VALIDATION.md`
- 화면 캡처: `02-rallybook-all-spots.png`, `03-nami-selected.png`, `04-soyang-selected.png`

## 남은 리스크

- 관광지 좌표는 공식 TourAPI 데이터지만 강원도·시군 GeoJSON은 화면용으로 단순화되어 해안 관광지의 시각적 경계와 소폭 차이가 날 수 있다.
- Android 빌드에서 기존 Kotlin Gradle Plugin의 향후 Flutter 호환성 경고가 남아 있으나 이번 빌드와 실행은 성공했다.
- 가까운 관광지는 마커가 겹칠 수 있으므로 선택 카드의 같은 시군 장소 칩으로 개별 선택을 보장한다.

## 다음 작업

- 이어서 실행할 명령: PR 머지 후 최신 `main`에서 지도 홈 카드 메뉴·가격 작업 이슈와 브랜치를 생성한다.
- 확인해야 할 파일: `frontend/lib/features/map/`, `backend/src/main/java/com/gamjamubwatna/spot/`, `agents_docs/07_api_specification.md`
- 조율이 필요한 사람 또는 이슈: 상위 이슈 #244. 지도 홈·관광지 데이터 파일을 수정하는 열린 PR이 생기면 먼저 충돌 여부를 확인한다.
