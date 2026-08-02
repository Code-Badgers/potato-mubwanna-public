# Issue #213 Validation

## 작업 개요

- 이슈: #213 `[FE] test: Team B 핵심 루프 실기기 통합 QA`
- 브랜치: `feat/213-team-b-device-qa`
- 작성일: 2026-08-03
- 범위: 지도 감자 핀 시각 개선, 감자 도감 진입 흐름 정리, 탭 화면 상단 제목 정리, footer와 마이페이지 UI 정리

## PAAR 기록

### 1. 지도 감자 핀

- Problem: 지도 스팟 마커가 너무 평범해져 감자 서비스의 정체성이 약해졌고, iOS에서 핀 탭 시 카드 갱신이 체감상 잘 되지 않는다는 피드백이 있었다.
- Approach: 원형 핀을 그대로 쓰기보다 감자 형태는 살리되 크기, 외곽선, leaf 포인트만 절제해 Apple UI 톤에 가깝게 정리하기로 했다. 또한 native marker touch area를 키워 실제 탭 성공률을 높이는 방향으로 접근했다.
- Action: Web/Android/iOS 지도 마커를 공통 톤의 감자 핀으로 변경하고, Web 마커 선택 메시지 테스트를 유지했다.
- Result: Flutter 상태 로직과 Web selection message 테스트는 통과했다. 단, 실제 iOS SDK 마커 탭 이벤트는 시뮬레이터 또는 실기기에서 반복 확인이 필요하다.

### 2. 감자 도감 진입 흐름

- Problem: 감자 탭을 누르면 바로 `나의 감자 도감` 목록이 보이는 구조와, 대표 감자 변경 버튼이 눈에 띄지 않는 구조가 섞여 사용자가 어디서 대표 감자를 바꾸는지 헷갈릴 수 있었다.
- Approach: 감자 탭 메인은 `대표 감자`와 `오늘의 감자걸음`을 보여주는 요약 화면으로 두고, 실제 도감 목록은 `대표 감자 변경` 버튼을 눌렀을 때만 나타나는 흐름으로 단순화했다.
- Action: 감자 메인 화면의 상시 도감 그리드, 희귀도 필터, 도움말 아이콘, 감자 상세 바텀시트 진입 코드를 제거했다. 대표 감자 변경 바텀시트는 `나의 감자 도감`으로 유지했다.
- Result: 감자 도감 테스트가 새 흐름을 검증하도록 갱신되었고 통과했다.

### 3. 공통 탭 화면 제목과 footer

- Problem: `랠리북`, `감자`, `미션`, `마이` 같은 큰 제목이 탭마다 반복되어 화면이 앱보다 데모 페이지처럼 보였고, footer 영역은 높이가 크고 요소가 위로 떠 보였다.
- Approach: 하단 탭 라벨이 이미 현재 위치를 알려주므로 각 탭 상단의 큰 제목은 줄이거나 제거하고, footer는 안전 영역을 지키면서 높이를 낮추기로 했다.
- Action: 랠리북/감자/미션/마이의 큰 타이틀 영역을 제거하거나 여백으로 축소했다. footer 높이를 `72 + safe area`에서 `64 + safe area`로 낮추고 내부 아이콘/라벨 간격을 정리했다.
- Result: 관련 widget test가 통과했다. 실제 iPhone 16e 시뮬레이터에서 하단 안전 영역과 시각적 균형은 추가 캡처 QA가 필요하다.

### 4. 마이페이지

- Problem: 마이페이지가 다른 탭보다 프로필 카드와 장식 배너 중심이라 전체 서비스 톤과 다르게 느껴졌고, 우측 상단 설정 버튼도 중복으로 보였다. `내 미션` 빠른 버튼은 이미 하단 탭에 있어 중복이었다.
- Approach: 마이페이지를 프로필 노출 중심이 아니라 활동 요약, 보상함, 여행 기록, 감자 도감, 설정 메뉴 중심의 조용한 계정 화면으로 재정리했다.
- Action: 프로필 카드, 우측 상단 설정 버튼, 장식 배너, `내 미션` 빠른 버튼을 제거했다. 설정은 하단 계정 메뉴 안에서만 접근하도록 유지했다.
- Result: 마이페이지 테스트가 새 구조에 맞게 갱신되었고 통과했다.

## 검증 결과

### Flutter 테스트

실행 위치: `frontend`

```bash
/Users/mac/Documents/flutter/bin/flutter test \
  test/features/potato/potato_collection_screen_test.dart \
  test/features/mypage/my_page_screen_test.dart \
  test/features/stamp/stamp_book_screen_test.dart \
  test/features/mission/mission_screen_test.dart \
  test/shared/widgets/main_shell_test.dart \
  --reporter compact
```

결과: 통과

### Flutter 분석

실행 위치: `frontend`

```bash
/Users/mac/Documents/flutter/bin/flutter analyze
```

결과: `No issues found`

## 남은 리스크

- 실제 iOS/Android 지도 SDK에서 감자 핀 탭 후 하단 카드가 즉시 갱신되는지 실기기 반복 확인이 필요하다.
- footer는 widget test 기준으로는 안전하지만, iPhone 16e와 Android 실제 기기에서 하단 안전 영역 체감 QA가 필요하다.
- 감자 도감 상세 설명은 현재 대표 감자 변경 시트에서 대표 선택 중심으로 남아 있다. 감자 상세 설명을 다시 제공하려면 별도 CTA 또는 상세 전용 화면을 새 이슈로 분리하는 편이 좋다.

