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
- Result: 획득 전 감자는 그림자처럼 표시하고, 이름은 `???`, 버튼은 `힌트`로 노출한다. 클릭하면 획득 방법과 설명을 확인할 수 있다.

## 실행한 검증

- `dart format lib/features/stamp/presentation/screen/stamp_book_screen.dart lib/features/potato/presentation/screen/potato_collection_screen.dart`
- `flutter test test/features/stamp/stamp_book_screen_test.dart`
  - 결과: 통과
- `flutter test test/features/potato/potato_collection_screen_test.dart`
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

- 마이페이지와 하단 내비게이션 UI 정리 후 `flutter analyze`와 관련 widget test를 추가로 실행한다.
- 화면 캡처는 전체 UI 정리 완료 후 남긴다.
