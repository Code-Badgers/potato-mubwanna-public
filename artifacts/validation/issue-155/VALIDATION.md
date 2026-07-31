# Issue #155 Validation - 미션 사진 업로드 스토리지 연동

## PAAR

### Problem

- #153에서 사진/OCR 미션의 uploadKey 발급 API는 구현했지만, 실제 파일 bytes는 저장하지 않았다.
- 이 상태에서는 사용자가 사진을 선택해도 서버에 검증 가능한 파일 원본이 남지 않아 OCR, 운영 보관, 감사 로그로 확장하기 어렵다.
- 업로드 산출물이 생기는 기능이므로 저장 위치가 Git에 올라가지 않도록 안전장치가 필요했다.

### Action

- `MissionPhotoStorage` 포트를 추가해 `MissionUploadService`가 저장소 구현에 직접 의존하지 않도록 분리했다.
- 로컬 개발용 `LocalMissionPhotoStorage`를 추가했다.
  - 기본 저장 루트: `local-runtime/mission-uploads`
  - 저장 key: `mission-uploads/{userId}/{missionId}/{timestamp}-{uuid}-{fileName}`
  - `Path.normalize()`와 `startsWith(rootDirectory)` 검증으로 경로 탈출을 방지했다.
- `MissionUploadService`가 파일 타입/용량/사용자/미션 검증 후 실제 저장소에 파일을 저장하도록 변경했다.
- `.gitignore`에 `local-runtime/`을 추가해 로컬 업로드 산출물이 실수로 커밋되지 않도록 했다.
- `agents_docs/07_api_specification.md`에 로컬 저장 방식과 환경변수 이름을 기록했다.

### Analysis

- 이번 단계에서는 S3 SDK를 바로 추가하지 않았다. 현재 프로젝트의 로컬 실행/테스트 안정성을 우선하고, S3 접근 키와 버킷 정책을 요구하지 않는 저장소 포트부터 만드는 편이 작고 검증 가능한 단위라고 판단했다.
- `MISSION_UPLOAD_STORAGE_TYPE`은 문서와 설정에 남겼지만 현재 구현체는 local만 제공한다. S3 구현은 후속 이슈에서 별도 bean 조건화와 함께 추가하는 것이 안전하다.
- 저장 실패는 `MissionUploadException`으로 변환해 기존 controller의 400 응답 경로를 재사용한다. 추후 운영 스토리지 장애를 5xx로 분리할지는 S3 연동 시 결정해야 한다.

### Result

- 업로드 API 호출 시 서버가 실제 파일을 로컬 디렉터리에 저장하고 저장된 object key를 `uploadKey`로 반환한다.
- 로컬 저장 파일은 `local-runtime/` 하위에 생성되며 Git 추적에서 제외된다.
- 추후 OCR 판독은 `uploadKey`를 기준으로 저장된 파일을 읽는 방식으로 이어붙일 수 있다.

## 변경 파일 요약

- `backend/src/main/java/com/gamjamubwatna/mission/application/MissionPhotoStorage.java`
- `backend/src/main/java/com/gamjamubwatna/mission/application/StoredMissionPhoto.java`
- `backend/src/main/java/com/gamjamubwatna/mission/infrastructure/LocalMissionPhotoStorage.java`
- `backend/src/main/java/com/gamjamubwatna/mission/application/MissionUploadService.java`
- `backend/src/main/resources/application.yml`
- `backend/src/test/java/com/gamjamubwatna/mission/application/MissionUploadServiceTest.java`
- `backend/src/test/java/com/gamjamubwatna/mission/infrastructure/LocalMissionPhotoStorageTest.java`
- `.gitignore`
- `agents_docs/07_api_specification.md`

## 검증

### 통과

```bash
cd backend
./gradlew test --tests com.gamjamubwatna.mission.application.MissionUploadServiceTest --tests com.gamjamubwatna.mission.infrastructure.LocalMissionPhotoStorageTest --tests com.gamjamubwatna.mission.api.MissionUploadControllerTest
```

결과: 통과

확인한 내용:

- 허용 이미지 업로드 key 생성
- 로컬 디렉터리 파일 저장
- 저장 파일 bytes 일치
- 경로 탈출 시도 차단
- 미허용 content-type 거부
- 5MB 초과 파일 거부
- 존재하지 않는 미션 거부
- controller 응답 구조 유지

### 전체 테스트 시도

```bash
cd backend
./gradlew test
```

결과: 실패

실패 테스트:

- `TourismCongestionSyncServiceTest > syncsPredictionsAndUpdatesNearestFutureCongestionLevel()`
- 실패 메시지: `expected: LOW but was: HIGH`

판단:

- 실패 파일은 혼잡도 동기화 도메인이고 이번 #155 업로드 저장소 변경 파일과 직접 관련이 없다.
- 실패 원인은 `TourismCongestionSyncService`의 대표 혼잡도 날짜 계산 또는 테스트 기대값이 현재 날짜 기준과 어긋나는 기존 이슈로 보인다.
- #155 범위 밖 파일을 수정하지 않는 규칙에 따라 이번 브랜치에서는 수정하지 않았다.
- 후속으로 별도 이슈를 열어 `LocalDate.now(clock)` 사용 여부와 nearest future 선택 정책을 정리하는 것이 좋다.

## 성능 테스트 메모

- 이번 변경은 로컬 파일 저장 I/O가 포함되지만, 운영 스토리지나 OCR 외부 호출은 아직 없다.
- k6 부하 테스트는 서버/DB/스토리지 실행 환경이 고정된 후 수행하는 것이 의미 있으므로 이번 단계에서는 수행하지 않았다.
- S3 또는 OCR 연동 시에는 업로드 API p95 latency, 실패율, 파일 크기별 처리 시간을 k6로 측정해야 한다.

## 남은 작업

- S3 또는 호환 오브젝트 스토리지 구현체 추가
- `MISSION_UPLOAD_STORAGE_TYPE` 기반 bean 조건화
- 업로드 실패를 4xx/5xx로 세분화할지 정책 결정
- OCR/이미지 판독 파이프라인 연동
- 저장된 파일 cleanup/보관 기간 정책
