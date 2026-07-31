# #166 QR 안내판 운영 샘플 및 QA 검증 기록

## 작업 범위

- QR_SCAN 미션에서 사용할 운영 샘플 QR SVG 생성
- 미션 인증 QR과 쿠폰 사용 QR의 역할 차이 정리
- iOS/Android 실기기 QA 체크리스트 작성
- 팀 B 전체 진행도 문서 업데이트
- 프론트 미션 테스트의 QR payload를 운영 샘플 형식으로 교체

## PAAR 기록

### 1. Problem

미션의 QR_SCAN 흐름은 구현되어 있었지만, 운영자가 실제 안내판에 붙일 수 있는 QR 샘플과 QA 기준이 부족했다. 또한 기존 프론트 테스트는 `mock-qr`라는 임시 문자열로 검증하고 있어, 실제 운영 payload 형식과 테스트 기준이 분리되어 있었다.

### 2. Analysis

QR은 두 종류로 분리해서 관리해야 한다고 판단했다.

- 미션 인증 QR: 관광지 안내판에 붙는 고정형 QR이다. 예시는 `gamjamubwatna://mission/qr/MISSION_SOKCHO_ONNURI_QR`처럼 미션 식별 payload를 담는다.
- 쿠폰 사용 QR: 사용자가 보상함에서 제시하는 QR이다. 사용자, 쿠폰, 만료 시간, 서명값을 포함해야 하므로 미션 인증 QR과 같은 방식으로 고정 배포하면 안 된다.

운영 샘플은 PNG보다 SVG가 문서/PR diff에서 관리하기 쉽고, 확대해도 깨지지 않아 QR 안내판 샘플로 적합하다고 보았다. QR 생성은 프론트 의존성에 이미 포함된 `qr` 패키지를 재사용했다.

### 3. Action

- `frontend/test/features/mission/mission_screen_test.dart`의 QR 미션 테스트 payload를 운영 샘플 payload로 교체했다.
- `artifacts/validation/issue-166/generate_qr_samples.dart`를 작성해 QR SVG와 manifest를 생성했다.
- `artifacts/validation/issue-166/qr-samples/` 아래에 5개 미션 QR SVG를 생성했다.
- `artifacts/validation/issue-166/QR_SAMPLE_MANIFEST.md`에 QR 파일명, 미션명, payload를 정리했다.
- `artifacts/validation/issue-166/QR_OPERATION_QA.md`에 실기기 QA 체크리스트와 운영 리스크를 정리했다.
- `artifacts/progress/team_work_progress_overview.md`에 #166 진행 상태와 남은 QR 실기기 QA 항목을 반영했다.

### 4. Result

프론트 미션 테스트는 통과했고, QR 샘플 생성도 완료했다. 이번 작업은 화면 런타임 변경이 거의 없어서 Flutter Performance Overlay, DevTools, k6 성능 테스트는 진행하지 않았다. 대신 QR 운영 샘플과 QA 문서가 추적 가능한 산출물로 남았다.

## 검증

### 통과

```bash
/Users/mac/Documents/flutter/bin/flutter test test/features/mission/mission_screen_test.dart
```

- 결과: 15개 테스트 통과

```bash
cd frontend
/Users/mac/Documents/flutter/bin/dart --packages=.dart_tool/package_config.json ../artifacts/validation/issue-166/generate_qr_samples.dart
```

- 결과: QR SVG 5개와 `QR_SAMPLE_MANIFEST.md` 생성 완료

## 트러블슈팅

### Flutter 명령어 경로 문제

처음에는 `flutter` 명령어가 PATH에 없어 실행되지 않았다.

- 원인: 현재 셸에서 Flutter SDK 경로가 PATH에 잡혀 있지 않았다.
- 해결: 설치 경로인 `/Users/mac/Documents/flutter/bin/flutter`를 직접 사용했다.

### QR 생성 스크립트의 패키지 해석 문제

처음에는 저장소 루트에서 `dart run ../artifacts/...` 방식으로 실행했을 때 `package:qr/qr.dart`를 찾지 못했다.

- 원인: 생성 스크립트가 Flutter 패키지 밖의 `artifacts` 경로에 있어 Dart가 프론트 패키지 의존성을 자동으로 해석하지 못했다.
- 해결: `frontend` 디렉터리에서 `.dart_tool/package_config.json`을 명시해 실행했다.

## 남은 작업

- 실제 iOS/Android 기기에서 QR 샘플을 카메라로 스캔하고 화면 캡처 또는 영상으로 QA 기록 남기기
- 운영용 QR payload를 서명/만료/nonce 기반으로 강화할지 결정
- 관리자용 QR 생성/다운로드 화면 필요 여부 결정
- QR 스캔 성공/실패 이벤트 로그 수집 기준 정리
