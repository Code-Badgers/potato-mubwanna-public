# Issue #542 Validation

## 작업 요약

- 이슈: #542 `[FE/BE] fix: 강원도 성향별 장소 추천 복구`
- 브랜치: `fix/542-gangwon-personality-recommendations`
- 담당 영역: 지도 홈 성향별 장소 추천, 강원도 장소 경계 검증
- 제외 범위: 장소 데이터 전면 재수집, 혼잡도 외부 API 운영 배치 재설계, 위치 기반 주변 추천
- 목표: 오늘자 혼잡도 예측이 없어도 내향형·외향형 추천을 표시하고 강원도 밖 장소를 노출하지 않는다.

## 변경 파일

- `frontend/lib/features/map/domain/map_spot.dart`: 주소의 광역자치단체가 강원도인지 판별하는 속성을 추가했다.
- `frontend/lib/features/map/data/map_spot_repository.dart`: 지도 목록과 관련 장소 추천에서 강원도 밖 장소를 제거한다.
- `frontend/lib/features/map/presentation/screen/map_screen.dart`: 실제 LOW/HIGH 예측을 우선 사용하고, 없으면 강원도 전체 카탈로그의 성향별 카테고리에서 보완한다.
- `frontend/test/features/map/map_screen_test.dart`: 예측 없음과 타 시도 장소 혼입 조건에서 두 추천 그룹을 검증한다.
- `frontend/test/features/map/spot_recommendation_repository_test.dart`: 지도 목록과 관련 장소 추천의 강원도 경계를 검증한다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: 없음
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 새 변수 없음. 모의 기기 빌드에는 기존 `API_BASE_URL`, `KAKAO_NATIVE_APP_KEY`를 사용했다.
- 외부 API: 운영 `GET /api/spots`를 읽기 전용으로 확인했다.

## 검증

- 실행: `flutter analyze`
- 결과: 성공, 문제 없음
- 실행: `flutter test --reporter compact test/features/map/map_screen_test.dart test/features/map/spot_recommendation_repository_test.dart`
- 결과: 성공, 43개 테스트 통과
- 실행: Android ARM64 디버그 APK 빌드 및 `potato_pixel_7_api36` 모의 기기 설치
- 결과: 성공. 운영 API에서 내향형 2곳과 외향형 2곳이 표시되고 보이는 주소가 모두 강원특별자치도임을 확인했다.
- 실행하지 못한 명령: `flutter format ...`
- 이유: Flutter CLI에 `format` 명령이 없어 실패했다. 이후 Dart formatter를 사용했고 불필요한 정렬 변경을 제거했다.
- 실패했던 설치 시도: 기존 QA APK와 새 디버그 APK의 서명이 달라 덮어쓰기가 거절됐다. 모의 기기의 기존 앱만 제거한 뒤 새 빌드를 설치해 검증했다.

## 산출물

- 검증 기록: 이 문서
- 화면/API 캡처: `production-api-summary.json`, `01-personality-calm.png`, `01-personality-groups-top.png`, `01-personality-calm-two.png`
- 기타: 2026-09-15 확인 결과 운영 장소 97곳은 모두 강원도 주소였고, 오늘자 혼잡도 단계와 예측 날짜는 97곳 모두 비어 있었다.

## 남은 리스크

- 성향별 보완 추천은 장소 카테고리를 기준으로 하는 결정적 규칙이다. 운영 혼잡도 예측이 복구되면 LOW/HIGH 값을 우선 사용한다.
- 백엔드 혼잡도 동기화는 서버 시작 시 1회 옵션만 있고 기본값이 꺼져 있다. 오늘자 예측을 지속 제공하려면 별도 운영 배치 작업이 필요하다.
- 모의 기기에서 네이티브 카카오 지도 인증 또는 로딩은 실패했지만, 이번 이슈 대상인 지도 홈 장소 API와 추천 카드 검증에는 영향이 없었다.

## 다음 작업

- 이어서 실행할 명령: `gh pr checks --watch`
- 확인해야 할 파일: 위 5개 변경 파일과 이 검증 문서
- 조율이 필요한 사람 또는 이슈: 혼잡도 외부 API의 정기 수집은 후속 백엔드 운영 이슈로 분리한다.
