# Issue #117 검증 기록 - 추천 동선 API와 지도 Polyline 연결

## 작업 목표

- 사용자가 저장한 감자 스팟을 기반으로 추천 동선을 계산하는 백엔드 API를 추가한다.
- 프론트 지도 화면에서 추천 동선 API 응답을 사용해 바텀시트의 동선 순서와 거리를 표시한다.
- 웹 Kakao 지도 위에 추천 동선 Polyline을 표시할 수 있도록 지도 위젯에 좌표 데이터를 전달한다.

## PAAR 기록

### Problem

- 기존 지도 화면은 사용자가 즐겨찾기한 장소를 프론트 로컬 로직으로만 정렬했다.
- 백엔드에 저장된 즐겨찾기 데이터를 기준으로 일관된 추천 동선을 제공하는 API가 없었다.
- 지도 바텀시트에는 추천 동선 목록이 있었지만, 지도 위에 실제 연결선은 표시되지 않았다.
- 추천 동선은 인증이 필요한 사용자 데이터라 단순 공개 API처럼 k6로 바로 호출하기 어렵다.

### Action

- `agents_docs/07_api_specification.md`에 `GET /api/me/favorite-spots/route` 계약을 먼저 추가했다.
- 백엔드에 `FavoriteSpotRouteResponse`, `FavoriteSpotRouteWaypointResponse`, `FavoriteSpotRoutePointResponse`를 추가했다.
- `FavoriteSpotService#getFavoriteSpotRoute`에서 저장된 즐겨찾기 스팟을 기반으로 MVP 추천 동선을 계산했다.
  - 2곳 이하는 저장 순서를 유지한다.
  - 3곳 이상은 최근 저장한 장소에서 시작해 가장 가까운 다음 장소를 이어 간다.
  - 거리 계산은 Haversine 기반 직선 거리로 처리했다.
- 프론트에 `FavoriteSpotRoute` 도메인 모델과 repository/provider를 추가했다.
- 지도 화면은 백엔드 추천 동선이 2곳 이상 매핑되면 해당 순서와 총 거리를 우선 사용하도록 했다.
- 웹 Kakao 지도는 `FavoriteSpotRoutePoint` 목록을 받아 `kakao.maps.Polyline`으로 노란색 동선을 표시하도록 했다.
- iOS/Android 네이티브 지도 위젯은 동일한 `routePolyline` 파라미터를 받을 수 있도록 인터페이스를 맞췄다.

### Analysis

- 이번 추천 동선은 실제 도로 길찾기 API가 아니라 직선 거리 MVP이다. 그래서 결과는 “대략적인 방문 순서 추천”에는 충분하지만, 실제 이동 시간/도로 경로와는 차이가 날 수 있다.
- 프론트는 백엔드 route 응답의 waypoint `spotId`를 현재 지도 스팟 목록과 매칭한다. 매칭 가능한 스팟이 2개 미만이면 기존 프론트 로컬 경로 계산으로 fallback한다.
- 웹 Polyline은 Kakao JavaScript SDK에서 바로 처리 가능하지만, iOS/Android 네이티브 SDK Polyline은 플랫폼별 추가 구현이 필요하다. 이번 단위에서는 네이티브 위젯 생성자 호환성까지만 맞추고, 실제 네이티브 Polyline 렌더링은 후속 작업으로 분리하는 편이 안전하다고 판단했다.
- k6 성능 테스트는 인증 토큰, 즐겨찾기 시드 데이터, 실행 중인 로컬 DB/백엔드 서버가 함께 필요하다. 이번 검증에서는 단위/컨트롤러 테스트로 API 계산과 응답 계약을 확인했고, k6는 후속 성능 검증 이슈에서 인증 시나리오와 함께 구성해야 한다.

### Result

- 백엔드 추천 동선 API와 테스트가 추가되었다.
- 프론트 지도 화면이 백엔드 추천 동선 응답을 사용한다.
- 웹 Kakao 지도는 추천 동선 좌표를 Polyline으로 그릴 수 있게 되었다.
- 작은 단위 커밋으로 문서, 백엔드, 프론트 API 연결, Polyline UI 연결을 분리했다.

## 변경 파일 요약

- `agents_docs/07_api_specification.md`: 추천 동선 API 계약 추가
- `backend/src/main/java/com/gamjamubwatna/spot/api/*Route*.java`: 추천 동선 응답 DTO 추가
- `backend/src/main/java/com/gamjamubwatna/spot/api/FavoriteSpotController.java`: 추천 동선 endpoint 추가
- `backend/src/main/java/com/gamjamubwatna/spot/application/FavoriteSpotService.java`: 추천 동선 계산 로직 추가
- `frontend/lib/features/map/domain/favorite_spot_route.dart`: 추천 동선 모델 추가
- `frontend/lib/features/map/data/map_spot_repository.dart`: 추천 동선 API 호출 추가
- `frontend/lib/features/map/application/map_spot_controller.dart`: 추천 동선 provider 추가
- `frontend/lib/features/map/presentation/screen/map_screen.dart`: 추천 동선 응답을 바텀시트와 지도 위젯에 반영
- `frontend/lib/features/map/presentation/widget/kakao_map_view_web.dart`: 웹 Kakao 지도 Polyline 표시 추가
- `frontend/lib/features/map/presentation/widget/kakao_map_view_native.dart`: 네이티브 지도 위젯 파라미터 호환
- `frontend/lib/features/map/presentation/widget/kakao_map_view_stub.dart`: 테스트/비지원 환경 위젯 파라미터 호환

## 실행한 검증

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.spot.application.FavoriteSpotServiceTest' --tests 'com.gamjamubwatna.spot.api.FavoriteSpotControllerTest'
```

- 결과: 통과

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter test test/features/map/map_screen_test.dart test/features/map/favorite_spot_route_test.dart
```

- 결과: 통과
- 참고: dependency outdated 경고와 iOS Swift Package Manager 미지원 플러그인 경고가 표시되었지만 테스트 실패로 이어지지는 않았다.

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter analyze
```

- 결과: `No issues found`

## 남은 리스크

- iOS/Android 네이티브 Kakao 지도 SDK의 실제 Polyline 렌더링은 아직 구현하지 않았다.
- 현재 동선 최적화는 직선 거리 기반 MVP라 실제 도로, 대중교통, 도보 소요시간을 반영하지 않는다.
- k6 부하 테스트는 인증 토큰과 즐겨찾기 시드 데이터가 필요한 별도 시나리오로 구성해야 한다.
- 실행 중인 백엔드/프론트와 Kakao 키가 준비된 상태에서 실제 화면 캡처를 추가로 남기면 포트폴리오 검증 자료가 더 좋아진다.

## 후속 작업

- Kakao Mobility 또는 별도 경로 최적화 API 검토
- iOS/Android 네이티브 지도 Polyline 렌더링 구현
- 추천 동선 따라가기 버튼 동작 연결
- 사용자별 동선 저장/이름 변경/삭제 기능 확장
- 인증 포함 k6 시나리오 작성 및 HTML 리포트/스크린샷 저장
