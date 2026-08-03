# Issue #235 Validation

## 작업 요약

- 이슈: #235 `[BE] fix: 동시 오디오 캐시 미스의 중복 저장 복구`
- 브랜치: `fix/235-audio-cache-race`
- 담당 영역: 오디오 안내 첫 조회 캐시 저장의 동시성 복구와 외부 API 일시 실패 재시도 검증
- 제외 범위: UI, 프론트엔드, API request/response, DB migration, 오디오 콘텐츠 품질 변경
- 목표: 같은 관광지의 첫 오디오 조회가 동시에 실행돼도 두 요청이 같은 캐시를 반환하고 DB에는 한 건만 저장되도록 한다.

## 변경 파일

- `backend/src/main/java/com/gamjamubwatna/audio/application/AudioGuideService.java`: 캐시 저장을 즉시 flush하고, 유일 키 충돌 시 다른 요청이 저장한 캐시를 다시 조회해 반환한다.
- `backend/src/test/java/com/gamjamubwatna/audio/application/AudioGuideServiceTest.java`: 동시 승자 캐시 반환과 승자 캐시가 없는 저장 실패 재전파를 검증한다.
- `backend/src/test/java/com/gamjamubwatna/audio/AudioGuideFlowIntegrationTest.java`: 동시 첫 조회와 외부 API 일시 실패 후 재시도 흐름을 검증한다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: 없음
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 없음
- 외부 API: 기존 Odii 연동을 그대로 사용하며 새 연동이나 호출 형식 변경 없음
- UI 변경: 없음

## 원인과 수정

- 기존 흐름은 DB 캐시 조회 후 Odii 데이터를 저장하므로, 같은 관광지와 언어의 첫 요청 두 개가 동시에 캐시 미스를 확인할 수 있었다.
- 두 요청이 모두 `(tourist_spot_id, language)` 유일 키로 저장을 시도하면 한 요청은 성공하지만 다른 요청은 `DataIntegrityViolationException`으로 실패했다.
- `saveAndFlush`로 유일 키 오류를 저장 호출 안에서 확인하고, 충돌한 요청은 승자가 저장한 캐시를 다시 조회해 같은 응답을 반환하도록 수정했다.
- 충돌 후에도 캐시가 없다면 다른 DB 오류일 수 있으므로 원래 예외를 그대로 다시 던진다.
- 외부 API 오류는 캐시하지 않아 다음 요청이 다시 Odii 조회를 시도하는 기존 동작을 유지했다.

## 실패 재현 및 시행착오

1. 동시성 통합 테스트를 처음 추가했을 때 테스트 fixture에 존재하지 않는 `SpotCategory.TOURIST_ATTRACTION`을 사용해 테스트 컴파일이 실패했다. 기존 도메인 값인 `POTATO_TOUR`로 바로잡았다.
2. 운영 코드를 수정하기 전 두 요청을 `CountDownLatch`로 같은 캐시 미스 구간에 진입시킨 결과, 한 Future가 `DataIntegrityViolationException`을 원인으로 하는 `ExecutionException`으로 실패해 버그를 재현했다.
3. 운영 코드 수정 후 같은 동시성 테스트를 강제 재실행으로 5회 반복했고 5회 모두 성공했다.

## 자동화 검증

- `cd backend && .\\gradlew.bat test --tests "com.gamjamubwatna.audio.AudioGuideFlowIntegrationTest.concurrentCacheMissesReturnTheSamePersistedGuide" --rerun-tasks`
  - 성공, 5회 연속 통과
  - 각 실행에서 두 요청이 같은 오디오 가이드 ID를 반환하고 캐시 증가량이 정확히 1건인지 확인
- `cd backend && .\\gradlew.bat test --tests "com.gamjamubwatna.audio.*" --rerun-tasks`
  - 성공
- `cd backend && .\\gradlew.bat test --rerun-tasks`
  - 성공, 365개 테스트 통과, 실패 0, 오류 0, 건너뜀 0
- `cd backend && .\\gradlew.bat build --rerun-tasks`
  - 성공, 365개 테스트 재통과 및 애플리케이션 산출물 생성
- `git diff --check`
  - 성공

## 완료 조건 확인

- 동시 첫 조회 두 건 모두 같은 캐시 응답 반환: 충족
- 캐시 row 한 건만 저장: 충족
- 외부 API의 첫 호출이 실패해 503을 반환한 뒤 다음 호출이 성공해 200과 캐시를 반환: 충족
- UI·API 계약·DB migration 비변경: 충족

## 남은 리스크

- 통합 테스트는 H2의 실제 유일 제약과 JPA 트랜잭션을 사용하지만 Odii 응답은 테스트 대역으로 검증했다. 운영 Odii 네트워크 품질 자체는 이번 이슈 범위가 아니다.
- 동시 캐시 미스 시 두 요청이 Odii를 각각 한 번 호출할 수 있다. 이번 수정은 사용자 요청 실패와 중복 DB row를 막는 범위이며, 외부 호출 단일화는 별도 성능 개선 항목이다.

## 다음 작업

- 이어서 실행할 명령: `git diff && git status --short`
- 확인해야 할 파일: `backend/src/main/java/com/gamjamubwatna/audio/application/AudioGuideService.java`, 오디오 단위·통합 테스트
- 조율이 필요한 사람 또는 이슈: 열린 PR과 오디오 변경 파일이 겹치지 않아 현재 조율 대상 없음
