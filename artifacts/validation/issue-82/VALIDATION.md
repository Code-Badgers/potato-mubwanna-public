# Issue #82 Flyway V11 마이그레이션 버전 충돌 복구 검증

## 작업 목표

- 최신 `main`에서 중복된 Flyway version 11을 제거한다.
- 먼저 머지된 감자 도감 migration은 `V11`로 유지한다.
- 나중에 머지된 오디오 가이드 migration을 `V12`로 재번호화한다.
- 애플리케이션 컨텍스트와 전체 백엔드 테스트를 다시 통과시킨다.

## 발생한 문제

PR #77과 PR #78이 각각 version 11 migration을 추가해 Flyway가 애플리케이션 시작 전에 중단됐다.

```text
Found more than one migration with version 11
-> V11__create_potatoes.sql
-> V11__create_audio_guides.sql
```

재현 명령:

```powershell
cd backend
.\gradlew.bat test --tests 'com.gamjamubwatna.GamjaApplicationTest'
```

수정 전 결과: `1 test completed, 1 failed`

## 원인과 해결

- `V11__create_potatoes.sql`은 PR #77에서 먼저 `main`에 머지됐다.
- `V11__create_audio_guides.sql`은 이후 PR #78에서 추가되며 충돌을 만들었다.
- 먼저 반영된 감자 migration의 version 11을 유지하고 오디오 migration을 `V12__create_audio_guides.sql`로 재번호화했다.
- 이미 원격에 반영된 migration 변경 금지 규칙은 사용자 승인 후 이번 충돌 복구에 한해 예외 적용했다.

## 변경 파일

- `backend/src/main/resources/db/migration/V11__create_audio_guides.sql`: 제거
- `backend/src/main/resources/db/migration/V12__create_audio_guides.sql`: 동일 DDL을 version 12로 재번호화
- `artifacts/validation/issue-76/VALIDATION.md`: 실제 migration 파일명으로 정정
- `artifacts/validation/issue-82/VALIDATION.md`: 실패와 복구 검증 기록

## 검증

### 충돌 재현 및 migration 집중 테스트

```powershell
cd backend
.\gradlew.bat test `
  --tests 'com.gamjamubwatna.GamjaApplicationTest' `
  --tests 'com.gamjamubwatna.potato.domain.PotatoMigrationTest' `
  --tests 'com.gamjamubwatna.audio.domain.AudioGuideMigrationTest'
```

결과: `BUILD SUCCESSFUL`

- 수정 전에 실패했던 애플리케이션 컨텍스트가 정상 시작된다.
- version 11 감자 스키마와 version 12 오디오 스키마가 함께 적용된다.
- 두 JPA migration 검증 테스트가 통과한다.

### 전체 백엔드 테스트

```powershell
cd backend
.\gradlew.bat test
```

결과: `BUILD SUCCESSFUL`, 142 tests, 실패 0, 오류 0, 제외 0

### 전체 백엔드 빌드

```powershell
cd backend
.\gradlew.bat build
```

결과: `BUILD SUCCESSFUL`

### 변경 파일 검사

```powershell
git diff --check
```

결과: 공백 오류 없음. Windows 체크아웃의 CRLF 변환 안내만 출력됨.

## 남은 리스크

- 공유 또는 운영 DB에서 오디오 migration을 version 11로 수동 적용한 이력이 있다면 `flyway_schema_history` 확인과 별도 repair가 필요하다.
- 정식 `main` 기반 애플리케이션은 이 수정 PR이 머지된 뒤 정상화된다.

## 후속 작업

- 이슈 #82 PR 머지 후 이슈 #81 연관 관광지 추천 API 작업을 최신 `main`에서 재개한다.
