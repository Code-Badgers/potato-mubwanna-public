# Issue 55 Validation - Mission Verification Flow

## 목표

- 미션 타입별 인증 입력 흐름을 화면 내부 임시 분기에서 분리 가능한 구조로 정리한다.
- 퀴즈, 걸음, 인증샷 미션이 완료 API 호출 전에 각 타입에 맞는 사전 검증을 거치게 한다.
- 추후 백엔드 검증 API, 카메라/갤러리, HealthKit/Google Fit 연동 시 교체하기 쉬운 구조를 만든다.

## 진행 내용

1. `MissionVerificationService`를 추가해 퀴즈 정답, 걸음 목표 충족, 사진 업로드 준비 상태 판단을 화면 밖으로 분리했다.
2. `MissionVerificationResult`를 추가해 완료 가능/차단 상태와 사용자 안내 메시지를 명시적으로 반환하게 했다.
3. 퀴즈 바텀시트를 선택지 선택 후 `정답 제출하기`를 누르는 흐름으로 변경했다.
4. 인증샷 바텀시트를 카메라/갤러리 선택 후 업로드 준비 상태를 보여주고 `인증 완료하기`를 누르는 흐름으로 변경했다.
5. 미션 인증 서비스 단위 테스트와 화면 위젯 테스트를 보강했다.
6. PR 리뷰 반영으로 인증샷 바텀시트 취소와 검증 실패 처리를 분리했다.
7. 퀴즈 선택지가 항상 정답부터 보이지 않도록 선택지 순서를 섞어 반환하게 했다.

## 발생한 문제와 해결

- 기존 인증 판단이 `MissionScreen` 내부 private method에 묶여 있어 백엔드 검증 API로 교체하기 어려웠다.
  - 해결: 인증 판단을 `MissionVerificationService`로 분리했다.
- 퀴즈 선택지가 선택 즉시 완료 판단을 해서 사용자가 자신의 선택 상태를 확인하기 어려웠다.
  - 해결: 선택지 선택 상태를 보여주고 별도 제출 버튼으로 확인하게 했다.
- 인증샷 미션은 카메라/갤러리 버튼 클릭 즉시 완료로 이어져 업로드 상태가 보이지 않았다.
  - 해결: mock 업로드 준비 상태를 보여준 뒤 완료 버튼을 누르게 했다.
- 실제 화면 캡처를 시도하려면 백엔드와 인증 토큰이 함께 필요했다.
  - 해결: 사용자 요청에 따라 이번 검증에서는 스크린샷을 건너뛰고 테스트/정적 분석으로 대체했다.
- 인증샷 바텀시트는 `true` 또는 `null`만 반환하는데, 기존 조건은 `false`일 때만 스낵바를 표시했다.
  - 해결: `null`은 취소로 먼저 처리하고, 그 외 검증 실패는 항상 메시지를 표시하도록 수정했다.
- 퀴즈 정답이 항상 첫 번째 선택지로 노출되었다.
  - 해결: 선택지 목록을 반환할 때 `shuffle()`로 순서를 섞도록 수정했다.

## 실행한 검증

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter test test/features/mission/mission_verification_test.dart test/features/mission/mission_repository_test.dart test/features/mission/mission_screen_test.dart
```

- 결과: 통과
- 비고: `flutter_secure_storage`의 iOS Swift Package Manager 미지원 경고가 출력되었으나 테스트 실패는 아님.

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze
```

- 결과: 통과, `No issues found!`
- 비고: 동일한 Swift Package Manager 경고가 출력됨.

## 남은 리스크

- 인증샷은 실제 이미지 선택 플러그인 연동 전이라 mock 업로드 상태만 표시한다.
- 걸음 수는 실제 HealthKit/Google Fit/Pedometer 연동 전이라 API 응답의 `progress` 값만 기준으로 판단한다.
- 퀴즈 정답 데이터는 프론트 임시 규칙이다. 백엔드 검증 API가 생기면 정답을 프론트에 노출하지 않는 구조로 바꿔야 한다.
- 실제 Web/iOS/Android 화면 캡처는 백엔드와 인증 세션을 준비한 뒤 추가 검증이 필요하다.

## 후속 작업

- 백엔드 미션 검증 API 설계 및 연결
  - 퀴즈 정답 검증
  - 사진/OCR 검증
  - 위치/걸음 수 검증
  - QR 스캔 검증
- 프론트에서 `MissionVerificationService`를 백엔드 검증 repository와 연결
- 실제 카메라/갤러리 이미지 선택 플러그인 검토 및 연결
- HealthKit/Google Fit/Pedometer 권한과 측정 데이터 연동 검토
