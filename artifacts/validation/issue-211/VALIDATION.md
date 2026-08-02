# Issue 211 검증 기록

## 작업 범위

- 이슈: #211 `[FE] feat: 신규 감자 보상 이미지 매핑 및 도감 표시 QA`
- 브랜치: `feat/211-potato-image-mapping`
- 목적: #206에서 추가된 신규 감자 보상 코드가 프론트 도감 화면에서 이미지 누락으로 깨지지 않도록 로컬 asset 매핑과 QA 테스트를 보강한다.

## PAAR

### Problem

백엔드 감자 카탈로그에는 `POTATO_COMMON_SEED`, `POTATO_GOLDEN_HONGCHEON`, `POTATO_HOBAN_CHUNCHEON`, `POTATO_RARE_SEED`가 추가되었지만 프론트에는 해당 코드의 전용 PNG가 아직 없다. 기존 구조는 코드명을 소문자 파일명으로 바꿔 바로 asset을 찾기 때문에, 전용 이미지가 없는 감자는 화면에서 fallback 아이콘으로 떨어질 수 있었다.

### Approach

이번 이슈는 새 캐릭터 이미지를 만드는 작업이 아니라 도감 표시 안정화 작업이다. 따라서 전용 이미지가 생기기 전까지 가장 가까운 기존 감자 이미지를 명시적으로 재사용하도록 alias 매핑을 만들었다. 매핑 로직을 화면 private 함수로 두지 않고 별도 helper로 분리해 단위 테스트가 가능하게 했다.

### Action

- `potato_asset.dart`를 추가해 감자 코드별 로컬 asset 경로 계산을 분리했다.
- 전용 이미지가 없는 신규 보상 코드 4종을 기존 감자 이미지로 임시 매핑했다.
- 감자 도감 화면의 이미지 슬롯이 새 helper를 사용하도록 수정했다.
- `potato_asset_test.dart`로 직접 코드와 alias 코드의 경로 계산을 검증했다.
- `potato_collection_screen_test.dart`에 신규 보상 코드가 실제 도감 화면에서 매핑된 asset으로 렌더링되는 테스트를 추가했다.
- `artifacts/progress/team_work_progress_overview.md`에 이미지 fallback 완료와 남은 전용 이미지 제작 항목을 분리해 기록했다.

### Result

- `/Users/mac/Documents/flutter/bin/flutter test test/features/potato/potato_asset_test.dart` 통과
- `/Users/mac/Documents/flutter/bin/flutter test test/features/potato/potato_collection_screen_test.dart test/features/potato/potato_asset_test.dart` 통과
- `/Users/mac/Documents/flutter/bin/flutter analyze` 통과

## 트러블슈팅

### Flutter 명령어 경로 문제

처음 `flutter test`를 실행했을 때 로컬 PATH에서 `flutter`를 찾지 못했다. 기존 프로젝트 작업에서 사용하던 `/Users/mac/Documents/flutter/bin/flutter` 경로로 다시 실행해 테스트와 analyze를 완료했다.

### 전용 이미지 없이 도감 QA를 하는 방식

전용 PNG를 새로 만들면 이미지 생성/디자인 검수까지 범위가 커진다. 이번 이슈는 백엔드 코드 확장 후 프론트 화면이 깨지지 않도록 막는 목적이므로, 전용 이미지 제작은 남겨두고 기존 이미지 alias로 레이아웃 안정성을 확보했다.

## 남은 보완

- `POTATO_COMMON_SEED`, `POTATO_GOLDEN_HONGCHEON`, `POTATO_HOBAN_CHUNCHEON`, `POTATO_RARE_SEED` 전용 캐릭터 PNG 제작
- 전용 이미지 추가 후 `potato_asset.dart` alias 제거 또는 실제 파일명 기준 매핑 정리
- 실제 iOS/Android 기기에서 감자 도감 대표 감자 변경, 상세 시트, 잠금 슬롯 이미지 QA
