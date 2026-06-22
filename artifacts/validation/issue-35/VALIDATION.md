# Issue 35 Validation

## 작업 목표

- 지도에서 선택한 감자 스팟을 로그인 사용자 기준으로 즐겨찾기 저장/삭제한다.
- 저장된 즐겨찾기 수를 지도 하단 카드의 내 동선 표시와 연결한다.
- 추후 나만의 동선 생성 기능으로 확장할 수 있도록 `favorite_spots` 테이블과 API를 먼저 마련한다.

## 진행 과정

1. 최신 `main`에서 `feat/35-favorite-route` 브랜치를 다시 생성했다.
2. API 계약을 `agents_docs/07_api_specification.md`에 먼저 추가했다.
3. 백엔드에 `favorite_spots` Flyway migration, JPA entity/repository, service, controller를 추가했다.
4. 프론트엔드에 즐겨찾기 API 호출과 Riverpod 상태 컨트롤러를 추가했다.
5. `FavoriteSpotServiceTest`로 저장, 중복 저장 방지, 삭제 idempotency를 검증했다.

## 발생한 문제와 해결

- 작업 시작 시 iOS/Xcode 관련 파일 2개가 이미 수정 상태였다. 이번 이슈 범위가 아니므로 스테이징하지 않는다.
- 기존 지도 화면은 `Set<String>`으로 즐겨찾기를 로컬 상태에만 저장했다. 앱 재실행/다른 기기에서 사라지는 구조라서 API 기반 상태로 교체했다.
- 실제 로그인 JWT subject는 `user:1` 형식인데 즐겨찾기 컨트롤러가 숫자 문자열만 가정해 `NumberFormatException`이 발생했다. `user:` prefix를 제거한 뒤 user id를 파싱하도록 수정하고 컨트롤러 테스트를 추가했다.
- iOS 네이티브 카카오맵에서 감자 POI 탭 시 하단 카드가 바뀌지 않는 문제가 있었다. POI id 문자열 가공에 의존하던 방식을 보완해 `poiID -> spotID` 매핑 테이블로 정확한 spot id를 Flutter `MethodChannel`에 전달하도록 수정했다.
- 저장한 감자 스팟이 2곳 이상이면 지도 하단 카드를 위로 끌어올릴 수 있는 추천 동선 패널로 확장했다. 현재 추천 순서는 좌표 간 직선 거리 기준의 MVP 휴리스틱이며, 실제 도로 이동시간 최적화는 후속 API 연동이 필요하다.

## 변경 파일 요약

- `agents_docs/07_api_specification.md`: 내 동선 즐겨찾기 API 계약 추가
- `backend/src/main/resources/db/migration/V3__create_favorite_spots.sql`: 즐겨찾기 테이블 추가
- `backend/src/main/java/com/gamjamubwatna/spot/**`: 즐겨찾기 도메인/API 구현
- `backend/src/test/java/com/gamjamubwatna/spot/application/FavoriteSpotServiceTest.java`: 즐겨찾기 서비스 테스트 추가
- `backend/src/test/java/com/gamjamubwatna/spot/api/FavoriteSpotControllerTest.java`: JWT subject `user:{id}` 파싱 테스트 추가
- `frontend/lib/features/map/**`: 지도 즐겨찾기 API 연동
- `frontend/ios/Runner/NativeKakaoMapView.swift`: iOS 감자 POI 탭 이벤트의 spot id 전달 보강
- `frontend/lib/features/map/presentation/screen/map_screen.dart`: 드래그 가능한 추천 동선 패널과 직선 거리 기반 정렬 추가

## 검증

- `cd backend && ./gradlew test`: 성공
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze`: 성공
- `cd frontend && flutter analyze`: 실패. 현재 셸 PATH에 `flutter`가 없어 절대경로로 재실행했다.
- `cd backend && ./gradlew test`: 성공. JWT subject `user:1` 파싱 수정 후 재검증했다.
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze`: 성공
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter build ios --simulator --debug --dart-define=...`: 성공. iOS 네이티브 Swift 지도 코드 컴파일을 확인했다.
- `cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze`: 성공. 추천 동선 패널 추가 후 재검증했다.

## 후속 작업

- 저장한 스팟을 방문 순서 또는 추천 순서로 정렬하는 내 동선 편집 화면을 만든다.
- 저장된 스팟 좌표를 카카오맵 Polyline으로 연결해 지도 위에 동선을 시각화한다.
- 마이페이지에서 내 동선 목록, 삭제, 공유 진입점을 제공한다.
- 저장한 동선을 기준으로 다음 장소 추천 API와 연결한다.
- Kakao Mobility Directions API 또는 별도 경로 API를 이용해 직선 거리가 아닌 실제 도로 거리/시간 기준 최적 동선을 계산한다.

## 남은 리스크

- 현재 API는 JWT 인증 사용자를 기준으로 동작한다. 로그인하지 않은 상태에서는 즐겨찾기 목록 조회와 토글이 실패한다.
- 나만의 동선을 지도 Polyline으로 보여주는 화면은 후속 작업으로 분리한다.
- iOS/Xcode 메타데이터 파일 2개가 작업 시작 전부터 수정 상태였다. 이번 이슈 범위가 아니므로 커밋 대상에서 제외한다.
