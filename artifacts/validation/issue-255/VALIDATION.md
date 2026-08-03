## 작업 요약

- 이슈: #255 `feat: 미션 업로드 이미지를 여행기록에 연결`
- 브랜치: `feat/255-mission-image-travel-record`
- 담당 영역: 사진 미션 완료 증빙 보관, 소유자 전용 이미지 조회, 여행기록 최신 사진 연결, Flutter 카드 썸네일 표시
- 제외 범위: 여행기록 화면 재설계, 실제 OCR 엔진 도입, 공개 이미지 URL/S3, 기존 완료 기록 역보정, 고아 파일 정리
- 목표: PHOTO/PHOTO_OCR 미션에서 검증된 이미지를 관광지와 연결하고, 해당 사용자의 여행기록 카드에 최신 인증 사진을 우선 표시한다.

## 변경 파일

- `agents_docs/07_api_specification.md`: 여행기록 `uploadedImageUrl` 및 보호 이미지 조회 계약을 명시한다.
- `backend/src/main/resources/db/migration/V27__link_mission_evidence_to_travel_records.sql`: 미션 완료 기록에 증빙 업로드 키와 관광지 관계를 추가한다.
- `backend/src/main/java/com/gamjamubwatna/mission/**`: PHOTO/PHOTO_OCR 검증 성공 시 증빙 관계를 저장하고 소유자 전용 이미지 bytes API를 제공한다.
- `backend/src/main/java/com/gamjamubwatna/visit/**`: 관광지별 가장 최근 미션 증빙 경로를 여행기록 응답에 추가한다.
- `frontend/lib/features/travel_record/**`: 보호 이미지를 인증된 Dio로 읽고 기존 54x54 카드 썸네일에 인증 사진, 관광지 사진, 기본 아이콘 순으로 표시한다.
- `backend/src/test/**`, `frontend/test/features/travel_record/**`: 저장 관계, 인증/404, 최신 사진 선택, bytes 조회, 화면 대체 표시를 검증한다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: `agents_docs/07_api_specification.md`, 새 Flyway migration, 여행기록 공통 응답 DTO
- API 계약 변경: `GET /api/users/me/visits`에 nullable `uploadedImageUrl` 추가, 인증이 필요한 `GET /api/mission-uploads/completions/{userMissionId}/image` 추가
- DB migration: V27에서 `user_missions.evidence_upload_key`, `user_missions.tourist_spot_id`, 조회 인덱스와 관계 제약을 추가한다.
- 환경 변수: 추가 없음
- 외부 API: 추가 없음. 기존 로컬 미션 사진 저장소와 인증 통신 경로를 재사용한다.

## 검증

- 실행: `backend\\gradlew.bat test`
- 결과: 성공, 382개 테스트 통과
- 실행: `flutter analyze`
- 결과: 성공, 이슈 없음
- 실행: `flutter test`
- 결과: 성공, 242개 테스트 통과
- 실행: 로컬 PostgreSQL 16 백엔드 기동 및 Flyway 적용
- 결과: V26에서 V27로 migration 성공, `/api/actuator/health` 상태 `UP`
- 실행: 로컬 API로 사용자 1의 뮤지엄 산 방문 인증 → 미션 14 PHOTO_OCR 이미지 업로드 → 완료 → 여행기록 조회 → 보호 이미지 조회
- 결과: 방문/미션 검증 성공, `/mission-uploads/completions/1/image` 생성, 인증 조회 200, 저장 원본과 응답 3,320 bytes 일치, 무인증 조회 401
- 실행: Android API 36 `emulator-5554`에 디버그 APK 빌드·설치 후 여행기록 진입
- 결과: 뮤지엄 산 1건과 업로드한 PNG가 기존 카드 썸네일 영역에 표시됨
- 실패 이력: 첫 migration SQL은 PostgreSQL식 복수 `ADD` 절을 한 문장에 사용해 H2 migration 테스트 9건이 실패했다. 각 열과 제약을 별도 `ALTER TABLE` 문으로 분리한 뒤 관련 테스트와 전체 테스트를 통과했다.
- 실패 이력: 첫 로컬 API 검증에서 `JWT_SECRET`이 `.env`에 있다고 가정해 401이 발생했다. DB 변경은 없었으며 `application.yml`의 로컬 기본값을 사용해 전체 API 흐름을 다시 성공했다.
- 실패 이력: 첫 Android 설치에서 기존 에뮬레이터의 `am force-stop`과 APK 설치 명령이 응답하지 않았다. 멈춘 Flutter/ADB 실행만 종료하고 에뮬레이터를 재시작한 뒤 동일 APK 설치와 실행에 성공했다.

## 산출물

- 검증 기록: `artifacts/validation/issue-255/VALIDATION.md`
- 화면 캡처: `03-travel-record-photo.png`
- 로컬 테스트 데이터: 사용자 1의 뮤지엄 산 방문 1건, 미션 14 완료 1건, 보호 증빙 이미지 1건

## 남은 리스크

- 관광지 연결은 활성 관광지의 `spotName`, `cityName` 정확 일치에 한정된다. 현재 강릉 감자빵과 안목 커피거리 미션은 관광지 이름이 일치하지 않아 여행기록 사진으로 연결되지 않는다.
- 기존 미션 완료 기록에는 증빙 업로드 키가 없으므로 이번 변경 이후 완료한 사진 미션부터 표시된다.
- 실제 OCR 엔진은 아직 연결되지 않았고 로컬 검증용 바이트 텍스트 판독기를 그대로 사용한다.
- Android 빌드에서 기존 Kotlin Gradle Plugin의 향후 Flutter 호환성 경고가 남아 있으나 이번 빌드와 실행은 성공했다.

## 다음 작업

- 이어서 실행할 명령: PR 머지 후 최신 `main`에서 관광지별 스탬프 이미지/도장 충격 연출 작업 이슈와 브랜치를 확인한다.
- 확인해야 할 파일: `frontend/lib/features/stamp/`, `frontend/assets/`, `backend/src/main/resources/db/migration/`, `agents_docs/07_api_specification.md`
- 조율이 필요한 사람 또는 이슈: 상위 이슈 #244. 여행기록, 미션, `user_missions`를 수정하는 열린 PR이 생기면 먼저 충돌 여부를 확인한다.
