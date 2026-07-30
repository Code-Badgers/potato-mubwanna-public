# #159 미션 QR 검증 실데이터 연결 Validation

## 1. 작업 범위

- Issue: #159 `[BE/FE] feat: 미션 QR 검증 실데이터 연결`
- Branch: `feat/159-mission-qr-verification`
- 목표: `QR_SCAN` 미션이 mock 값이 아니라 미션별 운영형 QR payload를 기준으로 검증되도록 연결한다.

## 2. PAAR 기록

### Problem

기존 DB seed는 모든 QR 미션의 `expected_qr_code`를 `mock-qr`로 넣고 있었다. 백엔드 검증 로직 자체는 `expected_qr_code`와 요청 `qrCode`를 비교할 수 있었지만, 정책 데이터가 mock 값이면 실제 안내판 QR을 스캔하는 운영 흐름을 검증할 수 없다. 문서에도 `QR_SCAN`은 존재 여부만 검증하고 실제 매칭은 후속이라고 적혀 있어 현재 구현 상태와 목표가 일치하지 않았다.

### Analysis

이번 이슈는 관리자 QR 발급 화면이나 실물 QR 안내판 제작까지 포함하면 너무 커진다. 그래서 MVP에서 바로 검증 가능한 단위로 범위를 줄였다.

- QR payload는 미션 코드와 1:1로 대응되는 URI 형식으로 정했다.
- 예: `gamjamubwatna://mission/qr/MISSION_SOKCHO_ONNURI_QR`
- 프론트는 이미 `mobile_scanner`로 실제 QR 값을 읽고 `MissionVerificationPayload.qrCode`로 보내는 구조가 있었다.
- 따라서 프론트 의존성을 새로 추가하지 않고, 백엔드 정책 seed와 검증 테스트, API 문서 정합성에 집중했다.
- 실제 스캐너가 앞뒤 공백을 포함한 문자열을 넘길 수 있어 서버 비교 시 `trim()`을 적용했다.

### Action

- `V18__seed_mission_qr_codes.sql`을 추가해 QR 미션별 고유 payload를 seed했다.
- `MissionMigrationTest`에 QR 미션 정책 seed 검증을 추가했다.
- `MissionService.validateQrCode`에서 expected/scanned QR payload의 앞뒤 공백을 제거한 뒤 비교하도록 보강했다.
- `MissionServiceTest`에 QR 성공, QR 누락, QR 정책 누락, QR 불일치 케이스를 명확히 남겼다.
- `agents_docs/07_api_specification.md`에 QR request 예시와 미션별 QR payload 표를 추가했다.
- `artifacts/progress/team_work_progress_overview.md`에서 #159 진행 상태와 Team B 남은 작업을 갱신했다.

### Result

백엔드 기준으로 `QR_SCAN` 미션은 이제 미션별 정책 QR payload와 정확히 일치해야 완료된다. 잘못된 QR, 빈 QR, QR 정책 누락은 모두 미션 완료로 이어지지 않는다. 프론트는 기존 실제 카메라 스캔 흐름이 그대로 `qrCode`를 전달하므로 이번 이슈에서 추가 코드 변경은 하지 않았다.

## 3. QR payload 샘플

| 미션 코드 | QR payload |
| --- | --- |
| `MISSION_PYEONGCHANG_QR` | `gamjamubwatna://mission/qr/MISSION_PYEONGCHANG_QR` |
| `MISSION_SOKCHO_ONNURI_QR` | `gamjamubwatna://mission/qr/MISSION_SOKCHO_ONNURI_QR` |
| `MISSION_CHEORWON_GOSEOKJEONG_QR` | `gamjamubwatna://mission/qr/MISSION_CHEORWON_GOSEOKJEONG_QR` |
| `MISSION_HOENGSEONG_HANWOO_QR` | `gamjamubwatna://mission/qr/MISSION_HOENGSEONG_HANWOO_QR` |
| `MISSION_HWACHEON_SANCHEONEO_QR` | `gamjamubwatna://mission/qr/MISSION_HWACHEON_SANCHEONEO_QR` |

## 4. 검증 명령

### 통과

```bash
cd backend
./gradlew test --tests com.gamjamubwatna.mission.domain.MissionMigrationTest
```

- 결과: `BUILD SUCCESSFUL`
- 확인 내용:
  - QR 미션 5개가 mock 값이 아닌 미션별 payload를 가진다.

```bash
cd backend
./gradlew test --tests com.gamjamubwatna.mission.application.MissionServiceTest
```

- 결과: `BUILD SUCCESSFUL`
- 확인 내용:
  - 올바른 QR payload면 미션 완료
  - 앞뒤 공백이 있어도 trim 후 성공
  - QR 값 누락 시 실패
  - QR 정책 누락 시 실패
  - QR payload 불일치 시 실패

```bash
cd backend
./gradlew test \
  --tests com.gamjamubwatna.mission.application.MissionServiceTest \
  --tests com.gamjamubwatna.mission.domain.MissionMigrationTest
```

- 결과: `BUILD SUCCESSFUL`

## 5. 프론트 확인

- `frontend/lib/features/mission/data/mission_native_input_service.dart`는 `mobile_scanner`로 실제 QR 값을 읽는다.
- `frontend/lib/features/mission/presentation/screen/mission_screen.dart`는 스캔된 값을 `MissionVerificationPayload.qrCode`로 전달한다.
- `frontend/android/app/src/main/AndroidManifest.xml`에는 `android.permission.CAMERA`가 있다.
- `frontend/ios/Runner/Info.plist`에는 `NSCameraUsageDescription`이 있다.

이번 이슈에서는 프론트 구조가 이미 실제 scanner 기반이어서 추가 코드 변경은 하지 않았다. 실제 QR 이미지/안내판을 카메라로 비추는 실기기 QA는 별도 후속 작업으로 남긴다.

## 6. 성능 테스트

k6 성능 테스트는 실행하지 않았다. 이번 변경은 QR payload 문자열 비교와 seed migration 중심이어서 별도 부하 측정 가치가 낮다. QR 검증 자체는 DB에서 읽힌 정책 문자열과 요청 payload 비교만 수행하므로 병목은 낮다. 추후 관리자 QR 발급, QR 감사 로그, 대량 미션 동시 완료 검증을 붙일 때 k6로 측정하는 것이 적절하다.

## 7. 남은 리스크와 후속 작업

- 실제 QR 이미지 생성 산출물과 실기기 스캔 QA가 아직 없다.
- 운영 QR 안내판이 외부에 노출될 경우 payload를 단순 URI로 둘지, 서명/만료가 있는 payload로 바꿀지 정책 결정이 필요하다.
- 관리자용 QR 발급/다운로드 화면은 아직 없다.
- 쿠폰 사용 QR과 미션 인증 QR은 목적이 다르므로 혼동되지 않게 운영 문서가 필요하다.
