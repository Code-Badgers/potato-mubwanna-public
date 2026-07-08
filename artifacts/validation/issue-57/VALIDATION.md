# Issue 57 Validation - Mission Verification API

## 목표

- 미션 타입별 인증 입력값을 프론트 임시 검증에만 의존하지 않고 백엔드 검증 API로 전달한다.
- 백엔드는 미션 타입별 최소 검증을 수행한 뒤 성공한 경우에만 완료 저장과 보상 응답을 반환한다.
- 프론트는 퀴즈 답안, 걸음 수, 인증샷 업로드 키, QR 값을 `/missions/{missionId}/verify`로 전달하고 실패 메시지를 UI에 표시한다.

## 진행 내용

1. `agents_docs/07_api_specification.md`에 `POST /api/missions/{missionId}/verify` 계약을 추가했다.
2. 백엔드에 `MissionVerifyRequest`, `MissionVerifyResponse`, `MissionVerificationException`을 추가했다.
3. `MissionService.verifyMission`에서 미션 활성 여부, 중복 완료 여부, 타입별 입력값을 검증한 뒤 완료 저장을 수행하도록 했다.
4. `MissionController`에 `/missions/{missionId}/verify` endpoint를 추가하고 검증 실패를 `400 Bad Request`, 중복 완료를 `409 Conflict`로 매핑했다.
5. 프론트 `MissionRepository.verifyMission`과 `MissionVerificationPayload`를 추가했다.
6. 미션 화면은 퀴즈/걸음/사진/QR 입력값을 payload로 만들어 서버 검증 API를 호출하도록 변경했다.
7. 프론트 fake repository 테스트도 서버 검증 실패 흐름을 흉내 내도록 조정했다.

## 발생한 문제와 해결

- 걸음 검증 테스트에서 목표값보다 큰 테스트 입력값을 사용해 실패를 기대한 테스트가 잘못 통과 조건을 만들었다.
  - 해결: 목표보다 작은 입력값으로 수정한 뒤 백엔드 미션 테스트를 재실행했다.
- 프론트 `flutter analyze`에서 `MissionVerificationPayload` 생성자에 `const`를 붙이라는 정적 분석 경고가 발생했다.
  - 해결: `completeMission` 호환 wrapper의 payload 생성에 `const`를 추가했다.
- `agents_docs`가 `.gitignore`에 포함되어 API 문서 변경이 일반 `git add`로 스테이징되지 않았다.
  - 해결: 이번 이슈 범위의 명시적 문서 변경이므로 `git add -f agents_docs/07_api_specification.md`로 스테이징했다.

## 실행한 검증

```bash
cd backend && ./gradlew test --tests '*mission*'
```

- 결과: 통과
- 비고: 첫 실행에서 걸음 테스트 데이터 오류로 실패했고, 수정 후 재실행에서 통과했다.

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter test test/features/mission/mission_repository_test.dart test/features/mission/mission_verification_test.dart test/features/mission/mission_screen_test.dart
```

- 결과: 통과
- 비고: `flutter_secure_storage`의 iOS Swift Package Manager 미지원 경고가 출력되었으나 테스트 실패는 아님.

```bash
cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze
```

- 결과: 통과, `No issues found!`
- 비고: 동일한 Swift Package Manager 경고가 출력됨.

## 남은 리스크

- 퀴즈 정답 판단은 아직 임시 규칙이다. 장기적으로는 미션별 정답/검증 정책을 DB 컬럼 또는 별도 검증 테이블로 분리해야 한다.
- 사진 인증은 실제 업로드/OCR 연동 전이라 `uploadKey` 존재 여부만 검증한다.
- QR 인증은 실제 QR 코드 매칭 전이라 `qrCode` 존재 여부만 검증한다.
- 걸음 수는 HealthKit/Google Fit/Pedometer 연동 전이라 프론트가 전달한 `stepCount` 기준으로만 검증한다.
- 기존 `/missions/{missionId}/complete` endpoint는 호환을 위해 유지되어 있다. 추후 앱이 완전히 `verify`로 전환되면 제거 또는 내부용으로 제한할지 결정해야 한다.

## 후속 작업

- 미션별 정답/QR/검증 정책을 DB schema로 분리한다.
- 실제 카메라/갤러리 업로드와 OCR 검증 API를 연결한다.
- HealthKit/Google Fit/Pedometer 권한 및 걸음 수 측정값을 연결한다.
- QR scanner 플러그인을 연결하고 QR 값 서버 검증을 강화한다.
