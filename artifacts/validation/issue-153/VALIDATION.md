# Issue #153 Validation - 미션 사진 업로드 키 실제 연동

## PAAR

### Problem

- 사진/OCR 미션에서 프론트가 `local:` 형태의 임시 uploadKey를 만들어 `/missions/{id}/verify`에 전달하고 있었다.
- 이 구조는 실제 파일 업로드/검증 흐름과 분리되어 있어, 서버가 발급한 키인지 확인할 수 없고 이후 S3/OCR 연동으로 확장하기 어렵다.

### Action

- API 계약을 `POST /api/mission-uploads`로 먼저 문서화했다.
- 백엔드에 multipart 기반 업로드 키 발급 API를 추가했다. 현재 MVP에서는 파일을 실제 저장하지 않고, 사용자/미션/파일 메타데이터를 검증한 뒤 `mission-uploads/{userId}/{missionId}/...` 형태의 서버 발급 키를 반환한다.
- 프론트 사진 선택 흐름을 “사진 선택 → 업로드 키 발급 요청 → 미션 검증 요청” 순서로 변경했다.
- 사진 바텀시트에 업로드 진행 상태와 실패 메시지를 표시하도록 보강했다.
- 백엔드 검증에서 `mission-uploads/` prefix를 확인해 `local:` 임시 키로 미션이 완료되지 않도록 막았다.

### Analysis

- `XFile.fromData` 테스트 더블에서 파일명이 비어 반환되는 케이스가 있어, 업로드 repository에서 파일명 fallback(`mission-photo.jpg`)을 추가했다.
- 프론트는 디바이스 입력 서비스가 파일만 반환하고, 네트워크 repository가 업로드 키 발급을 담당하도록 역할을 분리했다.
- 백엔드는 실제 스토리지 저장 전 단계이므로, 이번 범위에서는 파일 MIME/크기/사용자/미션 존재 여부와 서버 발급 키 형식 검증을 우선했다.

### Result

- 사진/OCR 미션 완료 payload에는 서버 API가 발급한 uploadKey만 들어가도록 변경됐다.
- 업로드 키 발급 실패 시 미션 완료 요청이 호출되지 않고, 바텀시트에서 실패 문구가 표시된다.
- 추후 S3 presigned upload 또는 OCR 파이프라인을 붙일 때 `MissionUploadService` 내부 구현만 확장하면 된다.

## 검증

- `/Users/mac/Documents/flutter/bin/flutter test test/features/mission/mission_upload_repository_test.dart test/features/mission/mission_screen_test.dart`
  - 결과: 통과
- `/Users/mac/Documents/flutter/bin/flutter analyze`
  - 결과: 통과
- `./gradlew test --tests com.gamjamubwatna.mission.application.MissionServiceTest --tests com.gamjamubwatna.mission.application.MissionUploadServiceTest --tests com.gamjamubwatna.mission.api.MissionUploadControllerTest`
  - 결과: 통과

## 성능 테스트 메모

- 이번 변경은 파일 저장/이미지 처리/외부 OCR 호출이 없는 uploadKey 발급과 UI 연결 범위다.
- DB 또는 외부 스토리지를 부하시키는 경로가 아직 없어 k6 부하 테스트는 수행하지 않았다.
- 실제 S3 presigned URL 발급, 이미지 저장, OCR 비동기 처리 도입 시 업로드 키 발급 p95 latency와 verify API 처리량을 k6로 기록할 예정이다.

## 남은 작업

- S3 또는 호환 오브젝트 스토리지 presigned URL 발급/저장 연동
- 업로드 완료 callback 또는 object key 확정 흐름
- OCR/이미지 판독 결과 기반 PHOTO_OCR 미션 자동 검증
- 업로드 파일 바이러스/확장자/이미지 dimension 검증 정책
