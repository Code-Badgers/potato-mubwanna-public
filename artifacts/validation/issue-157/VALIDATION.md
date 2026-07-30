# #157 미션 OCR 이미지 판독 검증 연결 Validation

## 1. 작업 범위

- Issue: #157 `[BE] feat: 미션 OCR 이미지 판독 검증 연결`
- Branch: `feat/157-mission-ocr-verification`
- 목표: `PHOTO_OCR` 미션이 단순 uploadKey 존재 여부가 아니라, 서버에 저장된 이미지 파일을 읽고 미션 정책 키워드가 판독 결과에 포함될 때만 완료되도록 연결한다.

## 2. PAAR 기록

### Problem

기존 `PHOTO_OCR` 미션은 사진 업로드 흐름과 검증 API의 구조는 있었지만, 실제 검증은 uploadKey 존재 여부에 가까웠다. 이 상태에서는 사용자가 아무 이미지를 업로드해도 OCR형 미션이 완료될 수 있고, `expected_answer`에 정의한 미션별 확인 키워드도 활용되지 못한다.

### Analysis

이번 이슈에서 바로 외부 OCR SaaS까지 붙이면 API 비용, 키 관리, 실패 재시도, 개인정보성 이미지 처리 정책까지 한 번에 커진다. 그래서 우선 도메인 흐름을 안정화하는 것을 먼저 선택했다.

- `MissionPhotoStorage`는 저장만 하는 역할에서 저장된 파일을 다시 읽는 포트까지 확장했다.
- `MissionPhotoTextReader` 포트를 새로 두어 OCR 엔진을 도메인 서비스에서 분리했다.
- 로컬/테스트 환경에서는 파일 bytes를 UTF-8 텍스트로 읽는 `EmbeddedTextMissionPhotoTextReader`를 사용한다.
- 실제 운영 OCR은 같은 포트 뒤에 SaaS 또는 온디바이스 OCR adapter를 교체하면 되도록 열어두었다.
- 키워드는 새 컬럼을 추가하지 않고 기존 `mission_verification_policies.expected_answer`를 재사용했다. 현재 정책 테이블의 의미와 잘 맞고, 스키마 변경 폭도 작다.

### Action

- 저장된 업로드 파일을 읽을 수 있도록 `MissionPhotoStorage.read(uploadKey)`를 추가했다.
- `StoredMissionPhotoFile`과 `MissionPhotoTextReader`를 추가해 OCR 판독 단계를 포트로 분리했다.
- `MissionService`에서 `PHOTO`와 `PHOTO_OCR` 검증 분기를 분리했다.
- `PHOTO_OCR` 검증 시 업로드 파일을 읽고, 판독 문자열에 정책 키워드가 포함되지 않으면 미션 완료를 거부하도록 했다.
- OCR 정책 키워드 seed migration을 추가했다.
  - 강릉 안목: `하지감자`
  - 원주 뮤지엄 산: `물의 정원`
  - 고성 DMZ: `평화의 종`
- API 문서와 전체 진행도 문서를 갱신했다.

### Result

타깃 테스트 기준으로 OCR 검증 흐름은 통과했다. 저장 파일이 없거나 OCR 키워드가 없는 경우에는 미션 완료가 거부된다. 다만 전체 `./gradlew test`는 기존 혼잡도 테스트 실패가 남아 있어 전체 green은 아니다. 해당 실패는 #157에서 수정한 미션/OCR 범위가 아니라 `TourismCongestionSyncServiceTest`의 날짜/혼잡도 기대값 문제로 분리 기록한다.

## 3. 검증 명령

### 통과

```bash
cd backend
./gradlew test \
  --tests com.gamjamubwatna.mission.application.MissionServiceTest \
  --tests com.gamjamubwatna.mission.application.MissionUploadServiceTest \
  --tests com.gamjamubwatna.mission.infrastructure.LocalMissionPhotoStorageTest
```

- 결과: `BUILD SUCCESSFUL`
- 확인 내용:
  - OCR 판독 문자열에 정책 키워드가 있으면 완료
  - 키워드가 없으면 실패
  - uploadKey 파일이 없으면 실패
  - 로컬 사진 저장소 read 동작 검증

```bash
cd backend
./gradlew test --tests com.gamjamubwatna.mission.domain.MissionMigrationTest
```

- 결과: `BUILD SUCCESSFUL`
- 확인 내용:
  - `V17__seed_photo_ocr_keywords.sql` migration이 PHOTO_OCR 미션 정책 키워드를 정상 반영

```bash
cd backend
./gradlew test \
  --tests com.gamjamubwatna.mission.application.MissionServiceTest \
  --tests com.gamjamubwatna.mission.application.MissionUploadServiceTest \
  --tests com.gamjamubwatna.mission.infrastructure.LocalMissionPhotoStorageTest \
  --tests com.gamjamubwatna.mission.domain.MissionMigrationTest
```

- 결과: `BUILD SUCCESSFUL`

### 전체 테스트 잔여 실패

```bash
cd backend
./gradlew test
```

- 결과: 실패
- 실패 테스트: `com.gamjamubwatna.spot.application.TourismCongestionSyncServiceTest.syncsPredictionsAndUpdatesNearestFutureCongestionLevel`
- 실패 메시지: `expected: LOW but was: HIGH`
- 판단: #157의 OCR 검증 변경과 직접 관련 없는 기존 혼잡도 테스트 실패다. 이번 브랜치에서는 범위 밖 수정으로 보고 건드리지 않았다.

## 4. 성능 테스트

k6 성능 테스트는 이번 이슈에서 실행하지 않았다. 이유는 현재 구현이 로컬 파일 읽기와 테스트용 텍스트 판독 adapter 중심이며, 외부 OCR 호출이나 별도 고부하 API 경로가 아직 없다. 실제 OCR SaaS 또는 이미지 판독 엔진을 붙이는 이슈에서 다음 항목을 측정하는 것이 더 의미 있다.

- 이미지 업로드 후 OCR 검증 API 응답 시간
- OCR 실패/성공 비율별 처리량
- OCR provider timeout/retry가 API p95에 미치는 영향

## 5. 후속 작업

- 실제 OCR SaaS 또는 온디바이스 OCR adapter 연결
- OCR 판독 결과 저장/감사 로그 정책 정리
- 이미지 보관 기간과 삭제 배치 정책 구체화
- 전체 테스트를 막고 있는 혼잡도 테스트 날짜/기대값 이슈 별도 해결
