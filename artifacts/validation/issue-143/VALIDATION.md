# Issue #143 Validation

## 작업 목표

- 방문 인증 성공 응답의 `missionAvailable` 값을 프론트 UI에 반영한다.
- 미션이 있는 방문 인증 성공 결과에서 사용자가 한 번의 액션으로 미션 탭에 진입할 수 있게 한다.
- 미션 탭은 방문 인증 직후 진입했음을 안내하는 배너를 보여준다.

## PAAR 기록

### P: Problem

방문 인증 성공 바텀시트는 스탬프와 감자 획득, 도감 보기, 다음 장소 추천만 제공하고 있었다. 백엔드 응답에는 `missionAvailable`이 있었지만 UI에서 사용하지 않아 `방문 인증 -> 점순이 미션 도전 -> 보상 획득` 루프가 끊겨 있었다.

### A: Action

- 방문 인증 성공 결과에서 `missionAvailable=true`일 때 `점순이 미션 등장` 결과 라인을 추가했다.
- 같은 조건에서 `점순이 미션 보기` CTA를 표시하고 `/main/missions?entry=visit&spotName=<스팟명>`으로 이동하게 했다.
- `MissionScreen`이 방문 인증 진입 스팟명을 받아 상단에 `방문 인증 미션이 열렸어요` 배너를 표시하도록 했다.
- 기존 미션 필터에서는 점순이 탭을 노출하지 않는 UX를 유지했다. 점순이는 미션 카테고리라기보다 미션을 안내하는 NPC로 보는 기존 방향과 맞췄다.
- 방문 인증 결과 라우팅 테스트와 미션 배너 위젯 테스트를 추가했다.

### A: Analysis

백엔드 계약을 바꾸지 않는 것이 이번 이슈의 제외 범위였기 때문에, 미션을 정확히 `spotId`로 필터링하지는 않았다. 현재 프론트 미션 모델에는 `spotName`과 `cityName`은 있지만 `spotId`가 없으므로, 방문 인증 직후에는 진입 맥락을 배너로 안내하고 기존 우선순위 정렬된 미션 목록을 보여주는 방식이 가장 작은 변경이었다. 추후 미션 API 응답에 `spotId`가 추가되면 해당 스팟 미션만 강조하는 구조로 확장할 수 있다.

### R: Result

- 미션이 없는 방문 인증 성공 결과는 기존 도감/추천 장소 CTA 흐름을 유지한다.
- 미션이 있는 방문 인증 성공 결과는 `점순이 미션 등장`과 `점순이 미션 보기`를 추가로 보여준다.
- `점순이 미션 보기`를 누르면 미션 탭으로 이동하고 방문 인증 스팟명 기반 안내 배너가 표시된다.

## 실행한 검증

```bash
cd /Users/mac/Desktop/lee/project/potato-mubwanna/frontend
/Users/mac/Documents/flutter/bin/flutter test test/features/spot/spot_detail_screen_test.dart test/features/mission/mission_screen_test.dart
```

결과: 통과

```bash
cd /Users/mac/Desktop/lee/project/potato-mubwanna/frontend
/Users/mac/Documents/flutter/bin/flutter analyze
```

결과: 통과

## 참고 로그

- 현재 쉘 PATH에는 `flutter`가 없어 `/Users/mac/Documents/flutter/bin/flutter` 절대 경로로 검증했다.
- Flutter가 `health`, `flutter_secure_storage`의 iOS Swift Package Manager 미지원 경고를 출력했다. 이번 변경 범위와 직접 관련은 없고, 테스트와 분석은 통과했다.

## 남은 리스크

- 현재 미션 화면 진입은 `spotName` 기반 안내 배너 수준이다. 실제 특정 스팟 미션 자동 필터링은 미션 API 응답에 `spotId`가 포함되어야 더 정확하게 구현할 수 있다.
- 실제 기기에서 방문 인증 성공 후 바텀시트 높이와 CTA 노출은 수동 UI 확인이 필요하다.

## 후속 작업

- 미션 API 응답에 `spotId` 또는 `sourceSpotId`를 추가해 방문 인증 스팟의 미션만 상단 강조한다.
- 방문 인증 성공 응답에 대표 미션 ID가 내려오면 미션 상세로 바로 진입시키는 흐름을 검토한다.
