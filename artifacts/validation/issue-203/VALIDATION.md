# Issue 203 Validation

## 작업 목표

- 앱 시작 시 세션 확인 화면에서도 `onboading.png` 대표 이미지를 보여주도록 수정한다.
- 성능과 정돈된 인상을 우선해 로딩 텍스트와 움직이는 로딩 애니메이션을 제거한다.
- 감자 도감 슬롯이 향후 감자 이미지 파일 또는 백엔드 이미지 URL을 표시할 수 있도록 준비한다.
- 지도 감자 스팟 선택 시 하단 카드가 갱신되지 않는 문제를 줄이기 위해 플랫폼 선택 메시지 파싱을 보강한다.
- 지도 감자 핀 오른쪽 별표 표시를 제거하고 핀을 감자 아이콘 하나로 통일한다.
- iOS에서 footer가 떠 보이지 않도록 하단 safe area 배경 처리를 정리한다.
- 대표 감자 변경 버튼을 통해 나의 감자 도감 선택 화면을 열도록 흐름을 맞춘다.
- 지도 상단에서 카테고리 필터가 먼저 보이고, 내 동선 버튼이 그 아래에 보이도록 배치를 정리한다.
- 마이페이지에서 로그아웃과 회원 탈퇴가 직접 노출되지 않고 설정 안에서만 보이도록 정리한다.
- 프론트 공통 버튼/강조 색상을 `AppColors` 기준으로 통일한다.
- 랠리북 화면의 보상/스탬프/다음 목표 UI가 다른 화면과 같은 톤으로 보이도록 정리한다.
- 지도 감자 스팟 마커가 이모지 스티커처럼 보이지 않도록 Web, Android, iOS 표현을 단정한 위치 핀으로 통일한다.
- 지도 카테고리별 보조색을 줄이고, 앱 브랜드 컬러 중심으로 색상 역할을 단순화한다.

## 진행 내용

- `SessionStartupScreen`의 텍스트 로딩 화면을 대표 온보딩 이미지 기반 화면으로 교체했다.
- 세션 확인 화면의 스피너를 제거하고 정적 이미지만 표시하도록 단순화했다.
- `frontend/assets/potatoes/` 폴더를 Flutter asset으로 등록하고, 이미지 파일명 규칙을 README로 남겼다.
- 감자 도감 슬롯이 `imageUrl`을 우선 사용하고, 없으면 `assets/potatoes/{code}.png`를 시도하도록 변경했다.
- Web, Android, iOS Kakao 지도 마커의 `🥔★` 표시를 `🥔`로 통일했다.
- 지도 선택 이벤트 payload가 `spotId`, `spotID`, `id`, `poiID`, `potato-<id>` 형태여도 같은 스팟 ID로 파싱되도록 보강했다.
- `MainBottomNavigation`이 iOS 하단 inset까지 같은 배경색으로 채워 footer가 바닥에 붙어 보이도록 수정했다.
- 대표 감자 카드의 `대표 감자 변경` 버튼을 누르면 `나의 감자 도감` 선택 화면이 열리도록 조건과 시트 제목을 조정했다.
- 지도 상단 컨트롤 순서를 카테고리 필터 -> 내 동선 버튼 순서로 바꿨다.
- 마이페이지 계정 메뉴에서 로그아웃과 회원 탈퇴를 제거하고, 설정 화면 계정 섹션으로 이동했다.
- 설정 화면 제목을 `설정`으로 바꾸고, 권한 소개 문구를 제거했다.
- `AppColors.primary`, `primaryDark`, `primaryTint`, `line`, `cream`, `brown`을 추가해 마이페이지, 설정, footer 색상 기준을 통일했다.
- 랠리북의 로컬 색상 상수를 제거하고 `AppColors` 기반으로 수집률, 다음 목표, 보상 카드 색상을 맞췄다.
- 랠리북 스탬프 타일의 `감자` 텍스트 표시를 체크/잠금 아이콘으로 바꿔 정보 밀도를 낮췄다.
- Web Kakao 지도 마커를 감자 이모지에서 흰 원형 핀 + 카테고리 컬러 점으로 변경했다.
- Android/iOS Kakao 지도 POI 이미지도 같은 원형 핀 스타일로 맞췄다.
- 지도 카테고리별 마커 색상을 기존보다 낮은 채도로 조정해 전체 화면 팔레트와 충돌하지 않도록 했다.
- 지도 마커 색상 정책을 일반 스팟 `#56C787`, 희귀/추천 스팟 `#F6C23E`로 단순화했다.
- 추천 장소의 보라색 강조를 제거하고, 보상/희귀와 같은 노란 포인트 색으로 통일했다.

## PAAR 기록

### Problem

사용자가 iOS 지도에서 감자 스팟을 눌러도 하단 카드 내용이 바뀌지 않는다고 보고했다. 또한 감자 핀 오른쪽 별표가 의도한 UI가 아니라고 확인했다.

### Action

기존 Flutter 위젯 테스트를 확인한 뒤, 지도 선택 이벤트가 Flutter 상태로 들어오는 경로를 점검했다. Flutter 화면 상태 테스트는 통과했으므로, 네이티브/Web 지도에서 전달되는 선택 payload 형태가 달라질 때 파싱이 실패할 수 있는 부분을 우선 보강했다. 별표는 Web/Android/iOS 마커 렌더링 코드에서 제거했다.

### Analysis

카드 갱신 로직 자체는 `onSpotSelected`를 통해 `_selectedSpotId`를 바꾸는 구조이며, 테스트에서는 정상 동작했다. 따라서 실제 기기에서 문제가 반복되면 다음 원인은 네이티브 Kakao Maps SDK의 POI tap 이벤트 미전달, 오래된 앱 빌드 실행, 또는 SDK별 payload 차이일 가능성이 높다. 이번 변경은 payload 차이에 대한 방어력을 높이는 조치다.

### Result

지도 카드 갱신 테스트를 포함한 관련 프론트 테스트가 통과했다. 별표 마커는 모든 플랫폼 코드에서 제거했다. 실제 iOS 지도 SDK 터치 이벤트는 시뮬레이터에서 재확인이 필요하다.

### Problem

랠리북은 기능은 동작하지만 진행률, 다음 목표, 시군 스탬프, 보상 카드가 각각 다른 색상 규칙을 사용해 화면이 다소 산만하게 보였다. 지도 마커도 감자 이모지가 지도 위에 붙은 느낌이라 실제 장소 핀보다 장식 요소처럼 보였다.

### Action

랠리북의 초록/노랑/라인 색을 `AppColors`로 모으고, 스탬프 획득 상태는 텍스트 대신 체크/잠금 아이콘으로 정리했다. 지도는 Web/Android/iOS에서 모두 이모지 마커를 제거하고, 흰 원형 핀 안에 카테고리 색 점을 넣는 방식으로 바꿨다.

### Analysis

앱 전체의 기본 인상은 `#56C787` 초록과 `#F6C23E` 노랑이 중심인데, 화면마다 비슷한 색을 각자 정의하면 미묘하게 다른 온도가 생긴다. 특히 지도는 데이터가 많아질수록 마커가 화면을 많이 차지하므로, 마커 자체는 작고 단정해야 카테고리와 위치 정보가 살아난다.

### Result

랠리북은 카드 반경, 라인, 보상 색을 다른 페이지와 맞췄고, 지도 마커는 장소 좌표를 표시하는 UI로 더 읽히도록 정리했다. Flutter analyze와 지도/랠리북 관련 테스트가 통과했다.

### Problem

지도 카테고리마다 별도 색을 부여하면서 맛집, 카페, 바, 쇼핑, 체험 색상이 많아졌고, 추천 장소에는 보라색까지 추가되어 브랜드 팔레트가 흐려졌다.

### Action

카테고리 색상은 제거하고, 지도 마커 색상은 일반 스팟 초록과 희귀/추천 스팟 노랑으로 제한했다. 카테고리 구분은 색 대신 필터의 아이콘과 라벨이 담당하도록 정리했다.

### Analysis

서비스 화면 전체는 초록과 노랑을 중심으로 설계되어 있으므로, 지도에서만 여러 보조색이 강하게 등장하면 앱이 서로 다른 화면을 붙인 것처럼 보인다. 카테고리 정보는 텍스트와 아이콘으로 충분히 구분되며, 색은 사용자의 행동과 중요도만 표현하는 편이 더 안정적이다.

### Result

지도 색상 체계가 `일반=초록`, `희귀/추천=노랑`, `선택/행동=초록 계열`로 정리되었다. 기존 테스트는 추천 문구가 `보라색 핀`을 기대해 한 번 실패했고, 새 정책에 맞춰 `노란 핀`으로 수정한 뒤 통과했다.

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
- UI 톤 정리 검증:
  - `/Users/mac/Documents/flutter/bin/flutter analyze --no-pub`
  - 결과: 통과
  - `/Users/mac/Documents/flutter/bin/flutter test --no-pub test/features/stamp/stamp_book_screen_test.dart test/features/map/map_screen_test.dart test/features/map/map_spot_selection_message_test.dart`
  - 결과: 통과
- 색상 단순화 검증:
  - `/Users/mac/Documents/flutter/bin/flutter test --no-pub test/features/map/map_screen_test.dart test/features/map/map_spot_selection_message_test.dart`
  - 1차 결과: 실패. 추천 상태 문구가 기존 `보라색 핀`을 기대하고 있었음.
  - 조치: 새 색상 정책에 맞춰 테스트 기대값을 `노란 핀`으로 수정.
  - 최종 결과: 통과
  - `/Users/mac/Documents/flutter/bin/flutter analyze --no-pub`
  - 결과: 통과

## 남은 리스크

- 실제 iOS 시뮬레이터에서 Kakao Maps SDK POI tap 이벤트가 Flutter로 전달되는지는 별도 수동 확인이 필요하다.
- 감자 실제 이미지는 아직 제공되지 않았으므로, 현재는 파일명 규칙과 fallback 슬롯까지만 준비했다.
- Android/iOS 네이티브 지도 마커 이미지는 정적 분석 대상이 아니므로 실제 기기 또는 시뮬레이터에서 한 번 더 시각 확인이 필요하다.
