# Issue 217 Validation

## 작업 목표

- 랠리북을 강원도 지도 중심의 스탬프 투어 화면으로 정리한다.
- 감자 도감의 대표 감자/잠금 감자 배치와 오늘 걸음 카드의 노출 정보를 단순화한다.
- 지도 하단 장소 카드와 북마크 상태 표현을 정리하고, 북마크 후에도 모든 감자 스팟 핀이 유지되도록 한다.
- 마이페이지의 보상함, 여행 기록, 감자 도감, 스탬프 투어 버튼을 가로 4개 균등 버튼으로 표현한다.

## 진행 내용

- 랠리북 지도 위의 진행률 배지를 제거하고, 지역 선택 설명 카드를 지도 아래로 내려 지도와 카드가 겹치지 않게 수정했다.
- 랠리북의 별도 투어 진행률/보상 카드는 이번 UI 흐름에서 제거했다. 스탬프 투어 화면은 지도에서 지역을 고르고 `스탬프 찍기`로 이동하는 흐름에 집중한다.
- 감자 도감의 오늘 걸음 카드에서 이번 주/이번 달 이동거리 정보를 제거했다.
- 잠금 감자 이미지는 원본 이미지 안의 투명 여백 때문에 시각적으로 왼쪽 위로 치우쳐 보여, 렌더링 시 약간 오른쪽 아래로 보정했다.
- 지도 카드에서 혼잡도는 장소 설명 하단으로 내리고, 북마크 버튼은 카드 우측 상단에 유지했다.
- 지도에서 북마크 상태는 필터가 아니라 마커 색상 상태로만 쓰도록 변경했다. 북마크한 핀만 노란 배경으로 바뀌고, 다른 감자 핀은 계속 표시된다.
- iOS, Android, Web Kakao 지도 뷰에 현재 위치 표시 데이터를 전달하고, 네이티브/웹 지도 위에 현재 위치 점을 표시할 수 있게 했다.
- 마이페이지 빠른 이동 버튼 4개를 가로 4등분 형태로 변경했다.

## 문제와 해결

- 문제: 지도에서 북마크를 누르면 “내 동선만 보기” 필터처럼 동작해 다른 감자 핀이 사라졌다.
- 원인: 즐겨찾기 상태가 지도 렌더링 상태뿐 아니라 화면 필터 조건에도 사용되고 있었다.
- 해결: 지도 스팟 필터는 카테고리만 보도록 단순화하고, 즐겨찾기 ID는 Kakao 지도 마커 색상 표시용으로만 전달했다. 이를 `keeps all category spots visible when a spot is bookmarked` 테스트로 고정했다.

- 문제: 랠리북의 선택 카드가 지도 위를 덮어 강원도 지도와 지역 정보가 답답하게 보였다.
- 원인: 선택 설명 카드가 지도 컨테이너 하단에 오버레이로 올라가 있었다.
- 해결: 지도 컨테이너와 선택 설명 카드를 세로 배치로 분리했다. 지역 선택 시 지도 아래에 Apple 스타일의 둥근 카드가 나타나도록 했다.

- 문제: 지도 하단 카드 높이 조정 후 테스트에서 `길찾기`, `상세보기` 버튼이 화면 밖에 있어 탭이 실패했다.
- 원인: 테스트 뷰포트가 작은 상태에서 하단 시트의 버튼이 바로 보이지 않았다.
- 해결: 테스트가 실제 사용자처럼 버튼을 보이게 한 뒤 탭하도록 `ensureVisible`을 추가했다.

- 문제: 기존 랠리북 보상 카드 테스트가 새 화면 구조와 맞지 않았다.
- 원인: UI 방향이 지도 중심 스탬프 투어로 바뀌며 별도 진행률/보상 카드가 제거되었다.
- 해결: 랠리북 테스트를 지도, 지역 선택 카드, 스탬프 찍기 흐름 중심으로 갱신했다.

## 변경 파일 요약

- `frontend/lib/features/map/presentation/screen/map_screen.dart`: 북마크 필터 제거, 현재 위치 로드, 장소 카드 배치 정리.
- `frontend/lib/features/map/presentation/widget/kakao_map_view_native.dart`: 현재 위치 데이터를 네이티브 지도에 전달.
- `frontend/lib/features/map/presentation/widget/kakao_map_view_web.dart`: 현재 위치 오버레이 표시.
- `frontend/lib/features/map/presentation/widget/kakao_map_view_stub.dart`: 테스트/비지원 환경 시그니처 정리.
- `frontend/ios/Runner/NativeKakaoMapView.swift`: iOS Kakao 지도 현재 위치 점 표시.
- `frontend/android/app/src/main/kotlin/com/gamjamubwatna/frontend/NativeKakaoMapView.kt`: Android Kakao 지도 현재 위치 점 표시.
- `frontend/lib/features/stamp/presentation/screen/stamp_book_screen.dart`: 랠리북 지도/선택 카드 구조 정리.
- `frontend/lib/features/potato/presentation/screen/potato_collection_screen.dart`: 오늘 걸음 카드 단순화, 잠금 감자 이미지 시각 중심 보정.
- `frontend/lib/features/mypage/presentation/screen/my_page_screen.dart`: 마이페이지 빠른 이동 버튼 4개 가로 균등 배치.
- `frontend/test/features/map/map_screen_test.dart`: 북마크 후 전체 핀 유지 테스트 추가.
- `frontend/test/features/stamp/stamp_book_screen_test.dart`: 새 랠리북 UI 흐름에 맞게 테스트 갱신.

## 검증 명령과 결과

- `dart format ...`: 통과.
- `flutter test --reporter compact test/features/map/map_screen_test.dart test/features/stamp/stamp_book_screen_test.dart test/features/potato/potato_collection_screen_test.dart test/features/settings/settings_screen_test.dart test/features/mypage/my_page_screen_test.dart`: 통과.
- `flutter analyze`: 통과, `No issues found`.

## 남은 리스크

- iOS/Android 실제 Kakao 지도 SDK에서 현재 위치 점과 핀 선택 이벤트는 시뮬레이터/실기기에서 추가 확인이 필요하다.
- 위치 권한이 이미 차단된 사용자는 OS 설정에서 권한을 다시 켜야 하므로, 권한 안내 UX는 별도 이슈에서 더 다듬는 것이 좋다.
- 랠리북 보상 수령 흐름은 지도 중심 화면에서 제거되어, 보상함 또는 별도 보상 화면과의 연결 정책을 후속으로 정리해야 한다.
