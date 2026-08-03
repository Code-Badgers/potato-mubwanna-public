# Issue #219 Validation

## 작업 목표

미션 페이지가 기능은 많지만 한 화면에서 너무 복잡하게 느껴지는 문제를 줄이고, 사용자가 “오늘 할 수 있는 미션”을 빠르게 고를 수 있도록 UX를 단순화한다.

## 진행 내용

- 상단의 큰 요약/안내 카드를 제거하고 `점순이의 미션` 헤더와 `0 / 3` 완료 수만 남겼다.
- 첫 화면에서 도전 가능한 미션 3개만 보여주도록 정리했다.
- 미션 필터와 긴 전체 목록은 첫 화면에서 제거했다.
- 목록 카드를 티켓형 카드처럼 정리해 제목, 장소, 상태, 조건, 보상을 한 흐름으로 읽히게 했다.
- 미션 상세 화면의 대사/조건/보상 카드 3개를 하나의 “미션 카드”로 통합했다.
- 상세 화면 통합 이후 사용하지 않는 이전 카드 위젯을 제거했다.
- 첫 진입 화면에서 긴 미션 목록을 바로 노출하지 않고, 가볍게 시작할 추천 미션 3개만 보여주도록 축약했다.
- `오늘의 부탁` 같은 큰 대화형 카드는 촌스럽고 화면을 무겁게 만든다고 판단해 제거했다.
- 화면 정체성은 `점순이의 미션`으로 명확히 하되, 각 카드 문장은 Animal Crossing처럼 부담 없는 일상 목표 문장으로 바꿨다.
- 사용자 제공 점순이 캐릭터 이미지의 초록 크로마키 배경을 제거하고, 미션에서 사용할 수 있도록 캐릭터 에셋 폴더를 추가했다.
- 점순이 캐릭터 에셋은 준비해두되, 이번 첫 화면에서는 큰 캐릭터 카드를 사용하지 않았다. 미션 상세나 완료 연출에서 필요한 경우 자연스럽게 활용할 수 있다.

## PAAR

### Problem

기존 미션 페이지는 상단 설명, 필터, 카드 안의 배지/보상/진행률/조건이 한꺼번에 보여서 게임형 미션이라기보다 관리 화면처럼 느껴질 수 있었다. 특히 앱에 들어오자마자 미션이 주르륵 보이면 사용자가 “놀러 가는 앱”이 아니라 “해야 할 일이 많은 앱”으로 받아들일 위험이 있었다.

### Action

목록에서는 `점순이의 미션` 제목과 3개 중 완료 수만 먼저 보여주고, 첫 진입 화면에는 추천 미션 3개만 남겼다. 각 추천 항목은 “사진 한 장 남겨볼까요?”, “가벼운 퀴즈 하나 풀어볼까요?”처럼 작은 일상 목표로 표현했다. 카드 크기와 내부 여백을 줄여 한 화면에서 부담 없이 훑을 수 있게 했다. 또한 제공받은 점순이 캐릭터 시트는 초록 배경을 투명 처리하고 포즈별 PNG로 잘라 `frontend/assets/characters/jumsooni/`에 저장했다.

### Analysis

점순이는 미션을 주는 NPC 역할이므로 화면 제목은 `점순이의 미션`으로 두는 것이 서비스 정체성에 더 맞다고 판단했다. 다만 큰 말풍선 카드나 캐릭터 카드가 상단을 차지하면 오히려 촌스럽고 무거워 보여, 메인 화면에서는 제거했다. 상세 문구는 `마을 안내`처럼 부드러운 안내형 표현으로 유지했다. 기존 검증 로직과 API 호출 흐름은 안정적으로 유지하고, 이번 이슈에서는 화면 구조와 정보 밀도만 줄이는 쪽으로 범위를 제한했다.

### Result

미션 목록은 `점순이의 미션 → 오늘 할 3개 카드` 흐름으로 정리되었다. 사용자는 처음부터 긴 목록을 마주하지 않고, 세 가지 목표만 바로 고를 수 있다. 점순이 에셋은 투명 PNG로 등록되어 Flutter asset에서 바로 사용할 수 있다. 기존 퀴즈, 사진, QR, 걸음 인증 테스트는 유지되며 모두 통과했다.

## 검증

- `flutter test --reporter compact test/features/mission/mission_screen_test.dart`
- `flutter analyze`

## 생성 에셋

- `frontend/assets/characters/jumsooni/jumsooni_sprite_sheet.png`
- `frontend/assets/characters/jumsooni/jumsooni_front.png`
- `frontend/assets/characters/jumsooni/jumsooni_three_quarter.png`
- `frontend/assets/characters/jumsooni/jumsooni_side_back.png`
- `frontend/assets/characters/jumsooni/jumsooni_back.png`
- `frontend/assets/characters/jumsooni/jumsooni_side.png`
- `frontend/assets/characters/jumsooni/jumsooni_idle.png`
- `frontend/assets/characters/jumsooni/jumsooni_walk.png`
- `frontend/assets/characters/jumsooni/jumsooni_wave.png`
- `frontend/assets/characters/jumsooni/jumsooni_back_side.png`

## 남은 리스크

- 실제 iOS/Android 기기에서 카드 높이와 스크롤 체감은 별도 화면 캡처로 확인할 필요가 있다.
- 점순이 또는 미션 타입별 전용 일러스트가 추가되면 카드 상단 아이콘 영역을 이미지 슬롯으로 확장할 수 있다.
