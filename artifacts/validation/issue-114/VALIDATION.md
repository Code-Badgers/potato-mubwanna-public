# Issue 114 Validation

## 작업 목표

- 방문 인증 성공 시 지역 스탬프를 실제 지급한다.
- 신규 지급 여부를 `stampIssued`에 반영하고 랠리북·보상 조건이 즉시 갱신되게 한다.

## 변경 파일

- `backend/src/main/java/com/gamjamubwatna/visit/application/VisitVerificationService.java`
- `backend/src/main/java/com/gamjamubwatna/stamp/application/VisitStampIssuanceService.java`
- `backend/src/main/java/com/gamjamubwatna/stamp/domain/StampRepository.java`
- `backend/src/main/java/com/gamjamubwatna/stamp/domain/UserStampRepository.java`
- 방문 인증·스탬프 발급 단위 테스트 및 통합 테스트

## 구현 메모

- `stampEnabled=true`이고 스팟의 `cityName`과 일치하는 스탬프가 있을 때만 지급한다.
- 같은 지역 스탬프를 이미 보유한 경우 방문 인증은 성공하지만 중복 지급하지 않는다.
- 지역 스탬프 조회에 비관적 락을 사용해 같은 지역의 동시 인증을 직렬화한다.
- 방문 기록과 스탬프 지급은 `VisitVerificationService`의 단일 트랜잭션에서 처리한다.

## 검증 결과

- `backend\\gradlew.bat test --tests "com.gamjamubwatna.visit.*" --tests "com.gamjamubwatna.stamp.application.VisitStampIssuanceServiceTest"`
  - 방문 인증, 스탬프 발급, 랠리북 반영 대상 테스트 통과
- `backend\\gradlew.bat test`
  - 56개 테스트 스위트, 226개 테스트 통과
  - 실패 0, 오류 0, 스킵 0
- `backend\\gradlew.bat build`
  - 전체 백엔드 빌드 성공

## 검증 중 발생한 문제

- 첫 전체 테스트 호출의 실행 제한을 1초로 잘못 지정해 호출이 먼저 종료되었다.
- 남아 있던 Gradle 테스트 프로세스가 결과 파일을 사용 중인 상태에서 재실행해 결과 디렉터리 잠금 오류가 발생했다.
- 기존 프로세스가 정상 종료될 때까지 기다린 뒤 `test`와 `build`를 다시 실행해 성공을 확인했다.

## 잔여 리스크

- 스팟 `cityName`이 스탬프 기준명과 다르거나 비어 있으면 방문 기록만 저장되고 스탬프는 지급되지 않는다.
- 감자 획득과 미션 활성화는 후속 Team B 작업 전까지 `false`를 유지한다.
