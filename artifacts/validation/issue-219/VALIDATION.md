# Issue #219 Validation

## 작업 목표

미션 페이지가 기능은 많지만 한 화면에서 너무 복잡하게 느껴지는 문제를 줄이고, 사용자가 “오늘 할 수 있는 미션”을 빠르게 고를 수 있도록 UX를 단순화한다.

## 진행 내용

- 첫 화면에서 별도 상단 `오늘의 미션` 헤더와 `0 / 4` 완료 수를 제거하고, 특별 미션 1개와 일일 미션 3개만 보여주도록 정리했다.
- 미션 필터와 긴 전체 목록은 첫 화면에서 제거했다.
- 목록 카드에서는 제목, 장소, 상태만 남기고 보상/쿠폰 번호/코인 같은 정보는 상세 화면 이후에만 보이도록 숨겼다.
- 미션 상세 화면의 대사/조건/보상 카드 3개를 하나의 “미션 카드”로 통합했다.
- 상세 화면 통합 이후 사용하지 않는 이전 카드 위젯을 제거했다.
- 첫 진입 화면에서 긴 미션 목록을 바로 노출하지 않고, 가볍게 시작할 추천 미션 3개만 보여주도록 축약했다.
- `오늘의 부탁` 같은 표현은 제거하고, 특별 미션 카드 내부에서만 `점순이의 미션`을 보여주도록 바꿨다.
- 특별 미션 카드의 `특별` 라벨은 리본 북마크 형태로 되돌리고, 점순이의 대사는 말풍선으로 분리했다.
- 특별 미션 카드에서 장소/인증 방식 정보 카드를 제거해 메인 화면의 정보 밀도를 더 낮췄다.
- 특별 미션 카드의 리본은 카드 상단에 붙어 보이도록 올리고, CTA는 텍스트 버튼 대신 우측 상단 화살표 액션으로 낮췄다.
- 메인 하단의 `매일 가볍게 여행 미션을 이어가보세요!` 안내 카드는 반복 정보라 제거했다.
- 각 일일 미션 카드는 Animal Crossing처럼 부담 없는 일상 목표 문장으로 바꿨다.
- 사용자 제공 점순이 캐릭터 이미지의 초록 크로마키 배경을 제거하고, 미션에서 사용할 수 있도록 캐릭터 에셋 폴더를 추가했다.
- 추가로 제공받은 점순이 상반신 시트를 8개 포즈로 분리하고, 특별 미션 카드에서 미션 id에 따라 포즈가 번갈아 보이도록 적용했다.
- 미션 상세 화면 우측 상단 북마크 아이콘을 제거했다.
- 상세 화면 상단 점순이 이미지와 아래 요약 카드가 겹치며 잘려 보이던 구조를 제거하고, 점순이를 박스 안에 가두지 않도록 장면 카드 테두리를 제거했다.
- 퀴즈 상세는 문제와 선택지를 바로 보여주고, 사용자가 `정답 제출하기`를 눌렀을 때 정답/오답 피드백을 표시하도록 정리했다.
- 미션 카드와 상세 카드의 모서리 반경을 스탬프 투어 카드 톤에 맞춰 `20px` 기준으로 통일했다.
- 점순이 말풍선은 사각형 카드처럼 보이지 않도록 꼬리가 있는 흰색 말풍선으로 바꿨다.
- 상세 화면의 점순이 배경 장면을 제거하고, 점순이가 일일 미션 요약 카드 바로 위에 붙어 있는 구조로 정리했다.

## PAAR

### Problem

기존 미션 페이지는 상단 설명, 필터, 카드 안의 배지/보상/진행률/조건이 한꺼번에 보여서 게임형 미션이라기보다 관리 화면처럼 느껴질 수 있었다. 특히 앱에 들어오자마자 미션이 주르륵 보이면 사용자가 “놀러 가는 앱”이 아니라 “해야 할 일이 많은 앱”으로 받아들일 위험이 있었다.

### Action

첫 진입 화면에는 특별 미션 1개와 일일 미션 3개만 남겼다. 특별 미션은 사진/촬영형 미션을 우선 배치하되, 메인에서는 점순이 말풍선과 방향 액션만 중심이 되도록 장소/인증 방식/보상 정보를 덜어냈다. 보상/쿠폰 번호/코인 같은 정보는 메인 화면의 동기 부여보다 운영 정보처럼 보일 수 있어 상세와 완료 팝업으로 이동했다. 일일 미션은 “천천히 걸어볼까요?”, “가벼운 퀴즈 하나 풀어볼까요?”처럼 작은 일상 목표로 표현했다. 카드 크기와 내부 여백을 줄여 한 화면에서 부담 없이 훑을 수 있게 했다. 또한 제공받은 점순이 캐릭터 시트는 초록 배경을 투명 처리하고 포즈별 PNG로 잘라 `frontend/assets/characters/jumsooni/`에 저장했다.

### Analysis

점순이는 미션을 주는 NPC 역할이므로 특별 미션 카드 안에서는 `점순이의 미션`으로 정체성을 드러내는 것이 맞다고 판단했다. 다만 별도 상단 헤더와 진행률은 화면을 한 번 더 설명하는 느낌이 있어 제거했다. 특별 미션은 처음에 캡슐형 `시작하기` 버튼을 두었지만, 일일 미션 카드와 액션 방식이 달라 화면 위계가 다시 무거워졌다. 최종적으로 카드 전체를 누를 수 있게 유지하고 우측 상단 화살표만 남겼다. 8px 카드 반경은 스탬프 투어 카드와 비교했을 때 딱딱해 보여 20px로 통일했고, 말풍선은 투명도를 줄여 흰색 버블로 되돌렸다. 상세 화면은 배경 장면을 지우고 점순이가 요약 카드에 붙어 있는 구조로 바꿔 카드와 캐릭터가 분리되어 보이는 문제를 줄였다.

### Result

미션 목록은 `특별 미션 → 오늘의 일일 미션 3개` 흐름으로 정리되었다. 사용자는 처음부터 긴 목록을 마주하지 않고, 특별 미션과 세 가지 작은 목표만 바로 고를 수 있다. 메인에서는 보상 정보가 바로 노출되지 않아 더 가벼운 탐색 화면에 가까워졌다. 특별 미션 카드는 흰색 표면과 우측 상단 화살표로 더 단정해졌고, 상세 화면은 점순이와 요약 카드가 더 가까운 하나의 흐름으로 보이게 되었다. 점순이 에셋은 투명 PNG로 등록되어 Flutter asset에서 바로 사용할 수 있다. 기존 퀴즈, 사진, QR, 걸음 인증 테스트는 유지되며 모두 통과했다.

## 검증

- `flutter test --reporter compact test/features/mission/mission_screen_test.dart`
- `flutter analyze`

### 트러블슈팅

- `시작하기` 텍스트 버튼을 제거하면서 기존 위젯 테스트가 해당 문구를 기대해 실패했다. 새 UX에서는 텍스트 버튼이 사라지는 것이 의도이므로 `시작하기`가 노출되지 않고 화살표 아이콘 액션이 존재하는지 확인하도록 테스트를 수정했다.
- `flutter analyze`에서 const 최적화 경고가 발생해 점순이 미션 카드 내부 `Column`을 const로 정리했다.
- 검증 명령을 병렬로 실행할 때 Flutter startup lock 경고가 한 번 발생했다. 이후 테스트를 다시 단독 실행해 통과를 확인했다.

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
- `frontend/assets/characters/jumsooni/jumsooni_expression_sheet.png`
- `frontend/assets/characters/jumsooni/jumsooni_neutral.png`
- `frontend/assets/characters/jumsooni/jumsooni_wave_hand.png`
- `frontend/assets/characters/jumsooni/jumsooni_point.png`
- `frontend/assets/characters/jumsooni/jumsooni_potato_hold.png`
- `frontend/assets/characters/jumsooni/jumsooni_cheer.png`
- `frontend/assets/characters/jumsooni/jumsooni_thinking.png`
- `frontend/assets/characters/jumsooni/jumsooni_surprised.png`
- `frontend/assets/characters/jumsooni/jumsooni_thumb.png`

## 남은 리스크

- 실제 iOS/Android 기기에서 카드 높이와 스크롤 체감은 별도 화면 캡처로 확인할 필요가 있다.
- 점순이 또는 미션 타입별 전용 일러스트가 추가되면 카드 상단 아이콘 영역을 이미지 슬롯으로 확장할 수 있다.
