# Issue #147 Validation

## 작업 목표

점순이 미션의 QR/사진/OCR 계열 인증 입력이 mock 값에만 의존하지 않도록 프론트 네이티브 입력 흐름을 연결했다. 실제 파일 업로드 서버와 OCR 엔진은 이슈 제외 범위이므로, 이번 작업은 카메라/갤러리/QR 스캔 사용자 액션을 `MissionVerificationPayload`의 `uploadKey`, `qrCode`로 전달하는 것까지를 목표로 했다.

## PAAR 기록

### Problem

미션 화면에는 사진 인증, 촬영 인증, QR 스캔 버튼이 있었지만 내부적으로는 `mock-${mission.id}`, `mock-qr` 같은 고정 값으로 검증 요청을 보냈다. 이 상태에서는 실제 장소에서 사용자가 카메라나 갤러리, QR 스캔으로 미션을 수행했다는 흐름을 검증하기 어렵다.

### Action

- `image_picker`와 `mobile_scanner`를 추가했다.
- iOS `Info.plist`에 카메라/사진 접근 목적 문구를 추가했다.
- Android Manifest에 `CAMERA` 권한을 추가했다.
- `MissionNativeInputService`를 추가해 미션 화면과 네이티브 입력 구현을 분리했다.
- QR 스캔 화면 `MissionQrScannerScreen`을 추가했다.
- 사진/OCR 미션 시트에서 카메라 촬영 또는 갤러리 선택을 호출하고, 선택 결과를 `local:<missionId>:<source>:<filename>` 형태의 `uploadKey`로 변환했다.
- QR 미션은 스캐너에서 읽은 실제 문자열을 `qrCode`로 검증 요청에 전달하도록 변경했다.
- 이미지 선택 중/취소/권한 실패/입력 실패 상태를 화면에 표시하도록 보강했다.
- 위젯 테스트에서 fake native input service를 주입해 사진 payload, QR payload, 입력 실패 메시지를 검증했다.

### Analysis

실제 파일 업로드와 OCR 엔진을 이번 이슈에 같이 넣으면 백엔드 저장소, 파일 서버, OCR provider, 업로드 실패/재시도 정책까지 범위가 커진다. 따라서 MVP의 다음 단계로 가기 위해 먼저 “사용자 액션 기반 입력값을 검증 API payload로 전달한다”는 경계까지만 구현했다.

사진/OCR 미션은 현재 백엔드가 `uploadKey`만 검증하므로 로컬 입력 결과를 임시 `uploadKey`로 만든다. 장기적으로는 이 키를 S3 또는 백엔드 업로드 API가 반환한 key로 바꾸면 된다. QR은 실제 스캔 문자열을 전달하므로 백엔드 정책의 expected QR과 바로 연결될 수 있다.

### Result

- 사진/OCR 미션은 카메라 또는 갤러리 선택 이후에만 완료 요청을 보낼 수 있다.
- QR 미션은 스캐너에서 읽은 QR 값으로 완료 요청을 보낸다.
- 권한 실패 또는 이미지 선택 실패 시 사용자가 볼 수 있는 메시지가 표시된다.
- 미션 화면 테스트에서 실제 입력 결과 기반 payload 전달을 검증했다.

## 실행한 검증

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter pub add image_picker mobile_scanner
```

결과: 성공. `image_picker 1.2.3`, `mobile_scanner 7.4.0`이 추가되었다.

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter analyze
```

결과: 통과.

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter test test/features/mission/mission_screen_test.dart
```

결과: 통과. 13개 테스트 통과.

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter test
```

결과: 통과. 전체 프론트 테스트 167개 통과.

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter build web \
  --dart-define=KAKAO_JAVASCRIPT_KEY=dummy \
  --dart-define=KAKAO_NATIVE_APP_KEY=dummy \
  --dart-define=API_BASE_URL=http://localhost:8080/api
```

결과: 통과. `build/web` 생성.

## 경고와 제약

- `health`, `flutter_secure_storage`가 iOS Swift Package Manager를 아직 지원하지 않는다는 기존 경고가 있다.
- Web build 중 Wasm dry-run에서 `flutter_secure_storage_web`, `geolocator_web`의 `dart:html` 사용 경고가 있었다. 일반 Web build는 성공했다.
- QR 스캔과 카메라 촬영은 실제 카메라 권한과 디바이스가 필요하므로 위젯 테스트에서는 fake service로 검증했다.
- 실제 파일 업로드 서버가 아직 없으므로 `uploadKey`는 `local:<missionId>:<source>:<filename>` 형식의 임시 키다.

## 화면 캡처

이번 변경은 카메라/갤러리/QR 네이티브 기능 의존도가 높아 로컬 자동 캡처를 남기지 않았다. 대신 위젯 테스트로 사진 선택 완료 상태, 입력 실패 상태, QR payload 전달을 검증했다. 실제 iOS/Android 화면 캡처는 실기기 QA 이슈에서 남기는 것이 적절하다.

## 남은 리스크

- 실제 iOS/Android 기기에서 카메라 권한 팝업, 갤러리 선택, QR 스캔 성공/취소 흐름을 확인해야 한다.
- OCR 미션은 아직 텍스트 추출이 아니라 사진 입력 key만 전달한다.
- 실제 업로드 API가 생기면 `local:` 임시 키를 서버 반환 key로 교체해야 한다.

## 후속 작업

- 미션 사진 업로드 API 또는 S3 pre-signed URL 흐름 설계.
- OCR provider 또는 온디바이스 OCR 도입 여부 결정.
- QR 운영 코드 발급/관리 정책과 관리자 입력 도구 설계.
- iOS/Android 실기기 QA와 화면 캡처 기록.
