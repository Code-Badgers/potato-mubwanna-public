# Issue 53 Validation - Mission Frontend API Integration

## 목표

- 미션 화면의 정적 mock 데이터를 백엔드 미션 API 연동 구조로 전환한다.
- `GET /missions` 응답을 프론트 모델로 매핑한다.
- `POST /missions/{missionId}/complete` 성공 시 상세 화면과 목록 상태가 완료로 갱신되게 한다.
- 중복 완료 등 API 실패 메시지를 사용자에게 표시한다.

## 진행 내용

1. `ApiPaths.missions` 경로를 추가했다.
2. `MissionChallenge.fromJson`을 추가해 백엔드의 `MissionItemResponse`를 프론트 도메인 모델로 변환하게 했다.
3. `MissionRepository`를 Dio 기반 API repository로 교체했다.
4. `MissionController`를 `StateNotifier<AsyncValue<List<MissionChallenge>>>`로 변경했다.
5. `MissionScreen`에 로딩, 에러, 빈 상태를 추가하고 완료 요청 성공 시 UI 상태를 즉시 갱신하게 했다.
6. 미션 API repository 테스트와 화면 상태 갱신 테스트를 추가했다.

## 발생한 문제와 해결

- 기존 화면 테스트는 정적 mock provider를 전제로 작성되어 API provider 변경 후 그대로 사용할 수 없었다.
  - 해결: `missionRepositoryProvider`를 fake repository로 override해서 화면 상태만 검증하도록 테스트를 재작성했다.
- 완료 팝업 닫기 버튼 문구가 실제 UI에서는 `확인`인데 테스트가 다른 문구를 찾고 있었다.
  - 해결: 실제 UI 문구 기준으로 테스트를 수정했다.
- 완료된 미션 카드가 테스트 화면 하단 밖에서 탭되어 hit test warning이 발생했다.
  - 해결: 일일 필터를 먼저 선택해 완료 미션이 화면 안에 들어오도록 테스트 흐름을 변경했다.

## 실행한 검증

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter test test/features/mission/mission_repository_test.dart test/features/mission/mission_screen_test.dart
```

- 결과: 통과
- 비고: `flutter_secure_storage`의 iOS Swift Package Manager 미지원 경고가 출력되었으나 테스트 실패는 아님.

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze
```

- 결과: 통과, `No issues found!`
- 비고: 동일한 Swift Package Manager 경고가 출력됨.

## 남은 리스크

- 실제 iOS/Android/Web 실행 검증은 아직 하지 않았다.
- 현재 완료 API는 “완료 요청”만 연결되어 있다. 퀴즈 정답 검증, QR 스캔, 사진/OCR, GPS, 걸음 수 인증은 후속 이슈에서 타입별 인증 플로우로 분리해야 한다.
- 인증이 만료되었거나 로그인하지 않은 상태에서 `/missions` 호출 시 백엔드 에러 메시지에 의존해 표시된다. 로그인 유도 UX는 후속으로 다듬는 것이 좋다.

## 후속 작업

- 미션 타입별 인증 UI 구현: 퀴즈 선택지, QR 스캐너, 촬영 인증, 위치 인증, 걸음 수 인증.
- HealthKit/Google Fit 또는 기기 pedometer 연동 가능성 검토.
- 미션 완료 보상과 감자 도감/쿠폰함 연동.
- 실제 디바이스에서 미션 완료 요청, 중복 완료 요청, 토큰 만료 재시도 확인.
