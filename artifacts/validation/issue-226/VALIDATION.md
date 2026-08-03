# Issue 226 Validation

## 작업 목표

- 감자 도감, 마이페이지, 스탬프 투어, 하단 내비게이션의 UI 톤을 정리한다.
- 닫힌 PR #221의 스탬프 안내 카드/수집률 배지 동선이 최신 main 기준에서 어떻게 반영되어 있는지 확인하고 보완한다.

## 진행 기록

### 1차: 스탬프/감자 화면 정리

- Problem: #221은 GitHub에서 `MERGED` 상태였지만, 최신 main을 받기 전 로컬 브랜치에서는 적용이 체감되지 않았다.
- Action: 최신 main을 fast-forward로 반영한 뒤 `feat/226-polish-potato-my-stamp-ui` 브랜치를 생성했다.
- Action: 스탬프 투어의 빈 안내 카드를 관광지 선택 카드와 같은 높이로 맞추고, 불필요한 보조 버튼 문구를 제거했다.
- Action: 감자 도감의 대표 감자 없음 문구를 제거하고 시작 상태 이름을 `초보 감자`로 표시했다.
- Action: 오늘의 감자걸음 하단 노란 진행 막대를 제거했다.
- Action: 대표 감자 변경 시트에서 획득한 감자만 보여주던 구조를 전체 감자 카드 그리드로 변경했다.
- Result: 획득 전 감자는 그림자처럼 표시하고, 이름은 `???`로 노출한다. 불필요한 힌트 버튼은 후속 정리에서 제거했다.

## 실행한 검증

- `dart format lib/features/stamp/presentation/screen/stamp_book_screen.dart lib/features/potato/presentation/screen/potato_collection_screen.dart`
- `flutter test test/features/stamp/stamp_book_screen_test.dart`
  - 결과: 통과
- `flutter test test/features/potato/potato_collection_screen_test.dart`
  - 결과: 통과
- `dart format lib/features/mypage/presentation/screen/my_page_screen.dart lib/shared/widgets/navigation/main_bottom_navigation.dart`
- `flutter test test/features/mypage/my_page_screen_test.dart`
  - 결과: 통과
- `flutter test test/shared/widgets/main_shell_test.dart`
  - 결과: 통과
- `flutter analyze`
  - 결과: 통과, `No issues found`
- `flutter test test/features/mission/mission_screen_test.dart`
  - 결과: 통과

## 트러블슈팅

- Problem: 스탬프 테스트가 기존 문구 `지도에서 깃발 선택`을 기대해 실패했다.
- Action: 새 UI에서는 해당 버튼형 문구를 제거하는 것이 요구사항에 맞으므로 테스트 기대값을 `findsNothing`으로 수정했다.
- Result: 스탬프 화면 테스트가 통과했다.

- Problem: 감자 테스트를 스탬프 테스트와 병렬 실행했을 때 iOS ephemeral 파일 삭제 충돌이 발생했다.
- Action: 관련 테스트를 순차 실행했다.
- Result: 감자 화면 테스트가 정상 통과했다.

- Problem: 감자 도감 카드의 잠금/획득 상태에 따라 버튼 텍스트를 바꾸면서 `const Text`에 런타임 조건이 들어가 컴파일 오류가 발생했다.
- Action: 버튼 텍스트 위젯의 `const`를 제거하고 내부 `TextStyle`만 `const`로 유지했다.
- Result: 감자 화면 테스트가 통과했다.

## 남은 확인

- iOS/Android 실기기 화면 캡처는 로컬 시뮬레이터/기기 실행 환경에서 추가 확인이 필요하다.

### 2차: 마이페이지/Footer 톤 정리

- Problem: 마이페이지의 프로필 카드, 활동 요약 카드, 빠른 실행 버튼, 계정 메뉴가 각자 다른 표면감과 모서리로 보여 전체 톤이 분리되어 보였다.
- Action: 마이페이지 카드 장식을 `_myPageCardDecoration`으로 통일하고, 프로필 아바타에 은은한 그라데이션/그림자를 적용했다.
- Action: 빠른 실행 버튼과 메뉴는 흰색 반투명 표면, 20~24px 모서리, 약한 라인으로 정리했다.
- Action: 하단 내비게이션은 blur가 들어간 반투명 표면과 더 낮은 대비의 selected pill로 정리했다.
- Result: 기존 라우팅과 메뉴 동작은 유지하면서 화면 사이의 카드 톤을 더 가볍게 맞췄다.

### 3차: PR 리뷰 후속 UI 조정

- Problem: 나의 감자 도감 시트에서 `힌트` 텍스트 버튼과 안내 문구가 화면을 불필요하게 설명형으로 만들었다.
- Action: 감자 카드 하단 텍스트 버튼과 도감 안내 문구를 제거했다.
- Result: 감자 도감 시트는 이미지와 이름 중심의 카드형 목록으로 더 단순해졌다.

- Problem: 스탬프 투어의 빈 안내 카드가 같은 높이 안에서 위쪽으로 몰려 보였다.
- Action: 빈 안내 카드와 선택 카드 높이를 186px로 맞추고, 빈 안내 카드 내용은 세로 중앙 정렬했다.
- Result: 카드 위아래 여백 균형이 더 자연스러워졌다.

- Problem: 미션 메인에서 점순이 이미지가 카드 하단에서 잘린 느낌이 강했고, 말풍선 꼬리가 어색한 방향에 있었다.
- Action: 점순이 이미지를 말풍선보다 위 레이어로 올리고, 말풍선 꼬리를 우측 상단으로 옮겼다. featured 카드 높이와 이미지 위치를 조정해 하단 잘림이 덜 드러나도록 했다.
- Result: 점순이가 말풍선에 가려지지 않고, 카드 하단의 불필요한 세로 여백이 줄었다.

### 4차: 점순이 보이스와 스탬프 지도 맥락 정리

- Problem: 점순이 대사가 화면별 하드코딩 문자열에 흩어져 있으면 말투 기준이 흔들리고, 원작 캐릭터를 현대적으로 재해석한 서비스 톤을 일관되게 유지하기 어렵다.
- Action: `MissionJumsooniDialogue`를 추가해 점순이 말풍선, 미션 소개, 완료 메시지 후보를 상황별로 중앙 관리하도록 분리했다.
- Action: `agents_docs/12_jumsooni_voice_guide.md`에 점순이의 성격, 말투 원칙, 피해야 할 표현, UI 적용 기준을 기록했다. `agents_docs/`는 로컬 exclude 대상이라 해당 파일은 커밋 시 강제로 포함해야 한다.
- Result: 기능성 문구와 캐릭터 대사를 분리했고, 미션 완료/퀴즈/사진/위치/QR/걸음 로직은 그대로 유지했다.

- Problem: 말풍선 꼬리와 마침표가 붙은 대사가 사각형 안내문처럼 보여 점순이 캐릭터 말투가 딱딱하게 느껴졌다.
- Action: 말풍선 화살표를 제거하고, 점순이 대사 후보와 홈 카드 대사의 마침표를 제거했다.
- Result: 짧고 구어적인 해요체 중심의 대사로 정리했다.

- Problem: 스탬프 투어에서 강원도 지도만 단독으로 놓이면서 섬처럼 보였고, 손으로 만든 대한민국 배경 윤곽은 실제 경계와 이어지는 느낌이 약했다.
- Action: 사용자가 제공한 `TL_SCCO_CTPRVN.json` 시도 GeoJSON에서 강원도 외 본토 시도 경계를 단순화해 `korea_context_map.dart`로 분리했다. 강원도 path는 기존 데이터를 그대로 사용하고, 배경 시도만 옅은 회색 레이어로 먼저 그린다.
- Result: 강원도 스탬프 지도는 유지하면서 경기도, 충북, 경북 등 주변 지역과 이어지는 지리적 맥락이 생겼고, 강원도 영역이 여전히 가장 선명하게 보인다.

- Problem: 스탬프 찍기 실패 안내가 `장소 데이터를 연결한 뒤`처럼 내부 구현 사정이 드러나는 문장이라 사용자 입장에서 어색했다.
- Action: 준비 중인 스탬프는 `스탬프는 아직 준비 중이에요`처럼 사용자 친화적인 안내로 바꿨다.
- Result: 데이터 연결 상태가 부족한 경우에도 화면 문구가 덜 개발자스럽게 보인다.

## 4차 실행한 검증

- `dart format lib/features/mission/presentation/mission_jumsooni_dialogue.dart lib/features/mission/presentation/screen/mission_screen.dart lib/features/potato/presentation/screen/potato_collection_screen.dart lib/features/stamp/presentation/screen/stamp_book_screen.dart test/features/mission/mission_screen_test.dart test/features/potato/potato_collection_screen_test.dart test/features/stamp/stamp_book_screen_test.dart`
  - 결과: 통과
- `flutter test test/features/mission/mission_screen_test.dart`
  - 결과: 통과
- `flutter test test/features/stamp/stamp_book_screen_test.dart`
  - 결과: 통과
- `flutter test test/features/potato/potato_collection_screen_test.dart`
  - 결과: 통과
- `flutter test test/features/stamp/stamp_book_screen_test.dart`
  - 결과: GeoJSON 기반 대한민국 배경 교체 후 재실행, 통과
- `flutter analyze`
  - 결과: 통과, `No issues found`

## 후속 UX 메모

- 스탬프 투어는 현재 18개 시군 방문 인증의 뼈대는 있으나, 수집 목적과 보상 피드백이 화면에서 충분히 설명되지 않는다.
- 감자 도감의 `0 / 15`는 전체 감자 중 수집한 감자 수를 의미하지만, 왜 모아야 하는지와 다 모았을 때 무엇을 얻는지가 화면에 약하다.
- 후속 이슈에서는 스탬프 완주 보상, 감자 성장/진화 목적, 도감 세트 완성 보상, 방문 인증 후 획득 연출을 함께 설계하는 것이 좋다.
