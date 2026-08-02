# Issue 203 Validation

## 작업 목표

- 앱 시작 시 세션 확인 화면에서도 `onboading.png` 대표 이미지를 보여주도록 수정한다.
- 성능과 정돈된 인상을 우선해 로딩 텍스트와 움직이는 로딩 애니메이션을 제거한다.
- 감자 도감 슬롯이 향후 감자 이미지 파일 또는 백엔드 이미지 URL을 표시할 수 있도록 준비한다.
- 지도 감자 스팟 선택 시 하단 카드가 갱신되지 않는 문제를 줄이기 위해 플랫폼 선택 메시지 파싱을 보강한다.
- 지도 감자 핀 오른쪽 별표 표시를 제거하고 핀을 감자 아이콘 하나로 통일한다.
- iOS에서 footer가 떠 보이지 않도록 하단 safe area 배경 처리를 정리한다.
- 대표 감자 변경 버튼을 통해 나의 감자 도감 선택 화면을 열도록 흐름을 맞춘다.

## 진행 내용

- `SessionStartupScreen`의 텍스트 로딩 화면을 대표 온보딩 이미지 기반 화면으로 교체했다.
- 세션 확인 화면의 스피너를 제거하고 정적 이미지만 표시하도록 단순화했다.
- `frontend/assets/potatoes/` 폴더를 Flutter asset으로 등록하고, 이미지 파일명 규칙을 README로 남겼다.
- 감자 도감 슬롯이 `imageUrl`을 우선 사용하고, 없으면 `assets/potatoes/{code}.png`를 시도하도록 변경했다.
- Web, Android, iOS Kakao 지도 마커의 `🥔★` 표시를 `🥔`로 통일했다.
- 지도 선택 이벤트 payload가 `spotId`, `spotID`, `id`, `poiID`, `potato-<id>` 형태여도 같은 스팟 ID로 파싱되도록 보강했다.
- `MainBottomNavigation`이 iOS 하단 inset까지 같은 배경색으로 채워 footer가 바닥에 붙어 보이도록 수정했다.
- 대표 감자 카드의 `대표 감자 변경` 버튼을 누르면 `나의 감자 도감` 선택 화면이 열리도록 조건과 시트 제목을 조정했다.

## PAAR 기록

### Problem

사용자가 iOS 지도에서 감자 스팟을 눌러도 하단 카드 내용이 바뀌지 않는다고 보고했다. 또한 감자 핀 오른쪽 별표가 의도한 UI가 아니라고 확인했다.

### Action

기존 Flutter 위젯 테스트를 확인한 뒤, 지도 선택 이벤트가 Flutter 상태로 들어오는 경로를 점검했다. Flutter 화면 상태 테스트는 통과했으므로, 네이티브/Web 지도에서 전달되는 선택 payload 형태가 달라질 때 파싱이 실패할 수 있는 부분을 우선 보강했다. 별표는 Web/Android/iOS 마커 렌더링 코드에서 제거했다.

### Analysis

카드 갱신 로직 자체는 `onSpotSelected`를 통해 `_selectedSpotId`를 바꾸는 구조이며, 테스트에서는 정상 동작했다. 따라서 실제 기기에서 문제가 반복되면 다음 원인은 네이티브 Kakao Maps SDK의 POI tap 이벤트 미전달, 오래된 앱 빌드 실행, 또는 SDK별 payload 차이일 가능성이 높다. 이번 변경은 payload 차이에 대한 방어력을 높이는 조치다.

### Result

지도 카드 갱신 테스트를 포함한 관련 프론트 테스트가 통과했다. 별표 마커는 모든 플랫폼 코드에서 제거했다. 실제 iOS 지도 SDK 터치 이벤트는 시뮬레이터에서 재확인이 필요하다.

## 검증

- `/Users/mac/Documents/flutter/bin/flutter test --no-pub test/features/auth/session_startup_screen_test.dart test/features/map/map_spot_selection_message_test.dart test/features/map/map_screen_test.dart test/features/potato/potato_collection_screen_test.dart`
  - 결과: 통과
- `/Users/mac/Documents/flutter/bin/flutter analyze --no-pub`
  - 결과: 통과
- 추가 검증:
  - `/Users/mac/Documents/flutter/bin/flutter test --no-pub test/features/potato/potato_collection_screen_test.dart test/features/map/map_screen_test.dart test/features/map/map_spot_selection_message_test.dart`
  - 결과: 통과
  - `/Users/mac/Documents/flutter/bin/flutter analyze --no-pub`
  - 결과: 통과

## 남은 리스크

- 실제 iOS 시뮬레이터에서 Kakao Maps SDK POI tap 이벤트가 Flutter로 전달되는지는 별도 수동 확인이 필요하다.
- 감자 실제 이미지는 아직 제공되지 않았으므로, 현재는 파일명 규칙과 fallback 슬롯까지만 준비했다.
