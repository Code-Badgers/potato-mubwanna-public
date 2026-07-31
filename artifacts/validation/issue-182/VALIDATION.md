# #182 iOS/Android 방문 인증 전체 루프 실기기 검증

## 작업 목표

지도에서 감자 스팟을 선택하고 상세 화면으로 이동한 뒤, 방문 인증 성공 결과와 점순이 미션 진입까지 이어지는 Team B 핵심 루프를 검증한다. 실제 기기 QA 전에 자동 테스트로 잡을 수 있는 회귀를 먼저 보강하고, 실기기에서 확인해야 할 항목을 분리해 남긴다.

## PAAR 기록

### 1. Problem

지도, 상세, 방문 인증, 미션 화면은 각각 구현되어 있었지만 `지도 마커 선택 -> 상세보기 -> 선택한 스팟 상세 진입` 흐름을 직접 검증하는 테스트가 부족했다. 실기기에서 카드가 갱신되지 않거나 상세 진입 spotId가 틀어지면 방문 인증 루프 전체가 시작되지 않는다.

### 2. Analysis

기존 테스트를 확인한 결과 다음 흐름은 이미 검증되어 있었다.

- 지도 마커 선택 시 하단 장소 카드 갱신
- 방문 인증 성공 바텀시트 표시
- 방문 인증 성공 후 다음 장소 추천 이동
- 방문 인증 성공 후 점순이 미션 탭 진입
- 미션 화면이 `visitEntryMissionId`로 상세를 바로 여는 흐름
- 위치 권한 영구 거부와 위치 서비스 꺼짐 안내

하지만 지도 화면의 `상세보기` 버튼이 현재 선택된 마커의 `spotId`로 이동하는지는 별도 검증이 없었다. 이 부분은 실기기 QA에서 발견되면 원인 추적 비용이 커서 widget test로 먼저 고정하는 것이 적절하다고 판단했다.

### 3. Action

- `frontend/test/features/map/map_screen_test.dart`에 `opens detail for the currently selected map marker` 테스트를 추가했다.
- 테스트용 지도 마커 2번을 선택한 뒤 `상세보기`를 눌렀을 때 `/spots/2` 라우트로 이동하는지 검증했다.
- `artifacts/validation/issue-182/DEVICE_QA_CHECKLIST.md`에 iOS/Android 실기기 QA 시나리오, 권한 상태별 기대 결과, 캡처해야 할 화면을 정리했다.
- `artifacts/progress/team_work_progress_overview.md`에 #182 진행 내역을 반영했다.

### 4. Result

지도/상세/미션 관련 프론트 자동 테스트와 정적 검사는 통과했다. 현재 Codex 셸에는 앱 실행에 필요한 `KAKAO_NATIVE_APP_KEY`, `KAKAO_JAVASCRIPT_KEY`, `API_BASE_URL`이 설정되어 있지 않았고 Android 기기가 감지되지 않아 실제 iOS/Android 화면 캡처는 진행하지 못했다.

## 실행한 검증

### 통과

```bash
/Users/mac/Documents/flutter/bin/flutter test test/features/map/map_screen_test.dart
```

- 결과: 9개 테스트 통과
- 확인한 흐름: 지도 UI, 마커 선택 카드 갱신, 선택 마커 상세 진입, 추천 장소 강조, 지도 설정 누락/스팟 API 실패 상태

```bash
/Users/mac/Documents/flutter/bin/flutter test test/features/spot/spot_detail_screen_test.dart
```

- 결과: 11개 테스트 통과
- 확인한 흐름: 스팟 상세, 오디오 상태, 방문 인증 성공, 추천 지도 이동, 점순이 미션 진입, 중복 인증/권한 실패 안내

```bash
/Users/mac/Documents/flutter/bin/flutter test test/features/mission/mission_screen_test.dart
```

- 결과: 15개 테스트 통과
- 확인한 흐름: 미션 목록, 퀴즈/걸음/사진/QR 인증 입력, 중복 완료 방지, 방문 인증 미션 상세 진입

```bash
/Users/mac/Documents/flutter/bin/flutter analyze
```

- 결과: No issues found

## 환경 확인

```bash
/Users/mac/Documents/flutter/bin/flutter devices
```

- 감지됨: macOS, Chrome
- 무선 iOS 기기 감지됨: `202184040`, iOS 26.5.2
- Android 기기: 감지되지 않음

```bash
KAKAO_NATIVE_APP_KEY
KAKAO_JAVASCRIPT_KEY
API_BASE_URL
```

- Codex 셸 기준 세 환경변수 모두 missing
- 실제 앱 실행 전 로컬 터미널에서 값을 export 하거나 IDE 실행 구성에 dart-define을 추가해야 한다.

## 실기기 QA 실행 명령

환경변수를 설정한 뒤 iOS는 다음처럼 실행한다.

```bash
cd /Users/mac/Desktop/lee/project/potato-mubwanna/frontend
/Users/mac/Documents/flutter/bin/flutter run \
  -d "202184040" \
  --dart-define=KAKAO_NATIVE_APP_KEY="$KAKAO_NATIVE_APP_KEY" \
  --dart-define=KAKAO_JAVASCRIPT_KEY="$KAKAO_JAVASCRIPT_KEY" \
  --dart-define=API_BASE_URL="$API_BASE_URL"
```

Android는 실제 기기가 연결된 뒤 `flutter devices`에서 나온 device id로 실행한다.

```bash
cd /Users/mac/Desktop/lee/project/potato-mubwanna/frontend
/Users/mac/Documents/flutter/bin/flutter run \
  -d "<android-device-id>" \
  --dart-define=KAKAO_NATIVE_APP_KEY="$KAKAO_NATIVE_APP_KEY" \
  --dart-define=KAKAO_JAVASCRIPT_KEY="$KAKAO_JAVASCRIPT_KEY" \
  --dart-define=API_BASE_URL="$API_BASE_URL"
```

## 남은 리스크

- 실제 iOS/Android 지도 렌더링, 위치 권한 팝업, OS 설정 이동은 widget test로 완전히 대체할 수 없다.
- Android Kakao Map은 에뮬레이터 CPU 아키텍처 이슈가 있었으므로 실제 Android 기기 QA가 필요하다.
- 방문 인증 성공은 백엔드 서버, DB 데이터, 현재 위치 시뮬레이션이 모두 맞아야 하므로 실기기 QA 때 실패 로그를 함께 남겨야 한다.
- 화면 변화가 큰 런타임 UI 수정은 없었으므로 DevTools Performance나 Android Studio Profiler는 실행하지 않았다.

## 후속 작업

- `DEVICE_QA_CHECKLIST.md` 기준으로 iOS 실기기 캡처 추가
- Android 실제 기기 연결 후 동일 루프 캡처 추가
- 권한 거부/영구 거부 상태 화면 캡처 추가
- 실기기에서 발견된 버그가 있으면 별도 fix 커밋으로 분리
