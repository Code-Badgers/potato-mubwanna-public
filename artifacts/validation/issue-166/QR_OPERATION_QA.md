# Mission QR Operation QA

## 1. QR 종류 구분

| 구분 | 목적 | Payload 예시 | 검증 위치 | 만료/서명 |
| --- | --- | --- | --- | --- |
| 미션 인증 QR | 특정 장소의 QR_SCAN 미션 완료 | `gamjamubwatna://mission/qr/MISSION_SOKCHO_ONNURI_QR` | `POST /api/missions/{missionId}/verify` | 현재 MVP는 미션별 고정 payload |
| 쿠폰 사용 QR | 사용자가 받은 쿠폰을 현장에서 사용 처리 | 서버가 발급한 쿠폰 QR payload | `POST /api/coupons/{userCouponId}/use` | 서명과 만료 시간을 사용 |

미션 QR은 현장 안내판에 붙는 장소 인증용이고, 쿠폰 QR은 사용자가 제시하는 개인 쿠폰 사용용이다. 두 QR은 서로 다른 API와 정책을 사용하므로 같은 안내판이나 같은 payload 형식을 공유하지 않는다.

## 2. 샘플 QR 이미지

| 미션 | 샘플 파일 | 기대 payload |
| --- | --- | --- |
| 평창 체험장 QR 찾기 | `qr-samples/MISSION_PYEONGCHANG_QR.svg` | `gamjamubwatna://mission/qr/MISSION_PYEONGCHANG_QR` |
| 속초 시장 QR 찾기 | `qr-samples/MISSION_SOKCHO_ONNURI_QR.svg` | `gamjamubwatna://mission/qr/MISSION_SOKCHO_ONNURI_QR` |
| 철원 고석정 철새 QR 찾기 | `qr-samples/MISSION_CHEORWON_GOSEOKJEONG_QR.svg` | `gamjamubwatna://mission/qr/MISSION_CHEORWON_GOSEOKJEONG_QR` |
| 횡성 한우 떡갈비 요리 챌린지 | `qr-samples/MISSION_HOENGSEONG_HANWOO_QR.svg` | `gamjamubwatna://mission/qr/MISSION_HOENGSEONG_HANWOO_QR` |
| 화천 산천어 미션 | `qr-samples/MISSION_HWACHEON_SANCHEONEO_QR.svg` | `gamjamubwatna://mission/qr/MISSION_HWACHEON_SANCHEONEO_QR` |

## 3. iOS/Android QA 체크리스트

### 권한

- 카메라 권한을 허용하지 않은 상태에서 QR 스캔 버튼을 누르면 권한 안내가 표시된다.
- 카메라 권한을 허용한 뒤 다시 QR 스캔 화면에 진입할 수 있다.
- iOS `NSCameraUsageDescription`, Android `android.permission.CAMERA`가 유지된다.

### 올바른 QR

- 속초 시장 QR 미션에서 `MISSION_SOKCHO_ONNURI_QR.svg`를 스캔한다.
- API 요청 payload의 `type`은 `QR_SCAN`, `qrCode`는 expected payload와 일치한다.
- 미션 완료 팝업 또는 완료 상태가 표시된다.
- 보상형 미션이면 보상함 또는 쿠폰 목록이 갱신된다.

### 잘못된 QR

- 속초 시장 QR 미션에서 평창/철원/횡성/화천 QR을 스캔한다.
- 서버는 `올바르지 않은 QR 코드입니다.` 메시지로 거부한다.
- UI는 미션을 완료 상태로 바꾸지 않는다.

### 스캔 취소

- QR 스캔 화면에서 뒤로 가기 또는 닫기를 수행한다.
- 미션 완료 API 요청이 발생하지 않는다.
- 기존 미션 상세 화면으로 돌아온다.

### 재시도

- 잘못된 QR 실패 후 같은 미션에서 올바른 QR을 다시 스캔한다.
- 성공 시 완료 처리되고 중복 제출 버튼 상태가 정상적으로 복구된다.

## 4. 운영 리스크

- 현재 미션 QR payload는 고정 문자열이라 외부로 공유되면 현장 방문 없이도 스캔될 수 있다.
- GPS 방문 인증과 함께 사용하거나, 후속 작업에서 서명/만료/nonce 기반 payload를 검토해야 한다.
- 실물 안내판에는 쿠폰 QR과 혼동되지 않도록 “미션 인증용” 문구를 명확히 표시해야 한다.
- 축제/시즌 미션은 운영 기간이 끝난 뒤 QR 안내판 제거 또는 미션 비활성화를 함께 관리해야 한다.

## 5. 후속 작업 후보

- 관리자용 미션 QR 발급/다운로드 화면
- 운영용 QR payload 서명 및 만료 정책
- QR 스캔 성공/실패 이벤트 로깅
- 실기기 QR 스캔 영상 또는 스크린샷 QA 산출물 추가
