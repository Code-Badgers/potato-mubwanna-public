# Issue 385 검증 기록

## 작업 목표

- 지도 탭 첫 진입 화면을 기존 전체 Kakao Map 중심 화면에서 강원도 여행 장소를 발견하고 계획하는 Discovery 홈으로 분리한다.
- `지도 크게 보기`를 눌렀을 때 기존 Kakao Map 전체 화면으로 진입하게 하며, 기존 지도 필터, 마커, 내 동선, 상세보기, 길찾기 동작은 유지한다.
- 하단 Navigation의 `감자` 라벨을 `감자밭`으로 변경한다.

## 진행 과정

1. 기존 지도 구조를 먼저 확인했다.
   - 지도 탭 메인 화면: `frontend/lib/features/map/presentation/screen/map_screen.dart`
   - Kakao Map 렌더링: `KakaoMapView`, `_PotatoMapPreview`
   - 카테고리 필터: `_CategoryFilterBar`, `_MapCategoryChip`
   - 장소 선택 카드: `_RouteRecommendationSheet`
   - 내 동선: `favoriteSpotControllerProvider`, `favoriteSpotRouteProvider`
   - 길찾기: `launchExternalMapUri`, `_openSpotNavigation`
   - 관광지 데이터: `mapSpotsProvider`, `MapSpot`
2. 실제 Kakao Map을 첫 진입에서 두 번 만들지 않기 위해 Discovery 홈의 지도 Preview는 가벼운 `CustomPainter` 기반으로 구현했다.
   - 단순 일러스트가 아니라 스탬프 투어에서 쓰는 강원도 시군 경계 데이터와 실제 스팟 좌표 투영 로직을 재사용해 작은 지도처럼 보이도록 개선했다.
3. 기존 전체 지도는 삭제하지 않고 `_showFullMap` 상태로 분기하여 그대로 재사용했다.
4. 추천 코스와 많이 찾는 곳은 새 API 없이 기존 스팟 데이터의 카테고리, 이름, 스탬프 가능 여부를 기준으로 구성했다.
5. 추천 코스의 `내 동선에 담기`는 기존 즐겨찾기/내 동선 저장 컨트롤러를 재사용했다.
6. Discovery 홈에서는 `내 동선 N곳`과 내 위치 표시를 제거하고, 실제 Kakao Map 전체 화면에 `여행 홈` 복귀 버튼과 내 위치 버튼을 추가했다.

## 발생한 문제와 해결

- 문제: Discovery 홈 테스트에서 코스 카드 내부 텍스트가 작은 테스트 뷰포트에서 overflow를 일으켰다.
  - 해결: 코스 섹션 높이를 조정하고 텍스트 줄 수를 제한해 작은 화면에서도 깨지지 않도록 했다.
- 문제: 기존 지도 테스트는 `MapScreen`을 열면 바로 전체 지도가 나온다고 가정했다.
  - 해결: 기존 기능 회귀 테스트에는 `showFullMapInitially: true` 테스트 전용 진입 옵션을 사용하게 하고, Discovery 홈 신규 테스트를 별도로 추가했다.
- 문제: `내 동선 0곳` 문구가 Discovery 홈에서 여러 위치에 등장해 테스트가 모호했다.
  - 해결: 주요 진입점에 `ValueKey`를 부여해 의도한 버튼을 명확하게 검증했다.

## 변경 파일 요약

- `frontend/lib/features/map/presentation/screen/map_screen.dart`
  - 지도 Discovery 홈 추가
  - 기존 전체 Kakao Map 화면을 `지도 크게 보기` 이후 표시하도록 분리
  - 전체 지도에서 Discovery 홈으로 돌아가는 버튼과 내 위치 버튼 추가
  - 코스 카드와 인기 장소 카드 추가
  - 기존 내 동선 저장 로직 재사용
- `frontend/lib/shared/widgets/navigation/main_bottom_navigation.dart`
  - 하단 탭 라벨 `감자`를 `감자밭`으로 변경
- `frontend/test/features/map/map_screen_test.dart`
  - Discovery 홈 렌더링과 전체 지도 진입 테스트 추가
  - 기존 전체 지도 기능 테스트가 전체 지도 모드에서 시작되도록 보정
- `frontend/test/shared/widgets/main_shell_test.dart`
  - 하단 탭 라벨 기대값 수정

## 실행한 검증

```bash
cd frontend
flutter test test/features/map/map_screen_test.dart test/shared/widgets/main_shell_test.dart
```

결과: 통과

```bash
cd frontend
flutter analyze
```

결과: 통과

## 남은 리스크

- Discovery 홈의 지도 Preview는 실제 Kakao Map이 아니라 강원도 경계 데이터 기반의 가벼운 Preview이다. 실제 지도 이동, 마커 클릭, 길찾기, 상세보기는 `지도 크게 보기` 이후 기존 전체 지도에서 확인해야 한다.
- 추천 코스는 현재 별도 추천 API가 아니라 기존 스팟 데이터 기반의 최소 구성이다. 운영 추천 품질을 높이려면 연관 관광지/혼잡도/사용자 취향 API와 연결하는 후속 작업이 필요하다.
- 실기기에서 위치 권한 허용/거부 팝업과 Kakao Map SDK 초기화는 추가 확인이 필요하다.
