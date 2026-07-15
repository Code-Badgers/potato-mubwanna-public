# Issue #70 검증 기록

## 작업 요약

- 이슈: #70 `test(reward): 미션 보상부터 QR 쿠폰 사용까지 통합 검증`
- 브랜치: `test/70-reward-coupon-e2e`
- 담당 영역: Team A 미션 보상, 쿠폰 발급, QR 사용 흐름
- 제외 범위: 관리자 사용 처리, 외부 제휴점 연동, 쿠폰 정책 확장
- 목표: 쿠폰 보상 미션 완료 시 보상 이력과 사용자 쿠폰을 한 번만 발급하고, 기존 QR 조회·사용 흐름까지 연결한다.

## 진행 과정과 해결 방법

1. 기존 미션 완료 트랜잭션이 `user_missions`, `reward_histories`만 저장하고 `user_coupons`를 만들지 않는 단절을 확인했다.
2. `reward_label`은 마이그레이션에 따라 표시용 한글과 코드가 섞여 있어 문자열 매칭에 사용하지 않았다.
3. V10 마이그레이션에서 쿠폰 카탈로그 코드, 유효일, 미션의 `reward_coupon_id`를 추가하고 쿠폰 보상 미션 7개를 명시적으로 연결했다.
4. 미션 완료, 보상 이력, 쿠폰 발급을 같은 Spring 트랜잭션 안에서 처리했다. 기존 `user_missions`와 `reward_histories`의 유일 제약으로 중복 완료 경쟁 시 전체 트랜잭션이 롤백된다.
5. 프런트는 서버 완료 응답의 보상 타입이 `COUPON`일 때만 `couponListProvider`를 무효화해 보상함을 다시 조회하도록 연결했다.

## 변경 파일 요약

- `backend/src/main/resources/db/migration/V10__connect_mission_coupon_rewards.sql`: 쿠폰 코드·유효일과 미션-쿠폰 보상 매핑 추가
- `backend/src/main/java/com/gamjamubwatna/mission/application/MissionService.java`: 쿠폰 보상 발급을 미션 완료 트랜잭션에 연결
- `backend/src/main/java/com/gamjamubwatna/mission/domain/Mission.java`: 보상 쿠폰 식별자 매핑
- `backend/src/main/java/com/gamjamubwatna/coupon/domain/Coupon.java`: 카탈로그 코드와 유효일 모델링
- `backend/src/test/java/com/gamjamubwatna/reward/application/RewardCouponFlowIntegrationTest.java`: 완료부터 QR 사용까지 통합 검증
- `frontend/lib/features/mission/application/mission_controller.dart`: 쿠폰 보상 완료 후 보상함 갱신
- `frontend/test/features/mission/mission_controller_test.dart`: 쿠폰 보상에만 갱신이 발생하는지 검증

## 자동화 검증

- `cd backend && .\gradlew.bat test --tests "com.gamjamubwatna.mission.application.MissionServiceTest" --tests "com.gamjamubwatna.coupon.domain.CouponTest" --tests "com.gamjamubwatna.mission.domain.MissionMigrationTest" --tests "com.gamjamubwatna.coupon.domain.CouponMigrationTest"`
  - 결과: 성공
- `cd backend && .\gradlew.bat test --tests "com.gamjamubwatna.reward.application.RewardCouponFlowIntegrationTest"`
  - 결과: 성공
- `cd backend && .\gradlew.bat build`
  - 결과: 성공
- `cd frontend && flutter analyze`
  - 결과: 문제 없음
- `cd frontend && flutter test`
  - 결과: 86개 테스트 성공
- `cd frontend && flutter build web`
  - 결과: 성공
  - 참고: 현재 의존성의 WebAssembly 비호환 및 Cupertino 아이콘 폰트 경고가 출력됐지만 JavaScript 웹 빌드는 정상 생성됐다.

## PostgreSQL 및 실제 HTTP 검증

- PostgreSQL 16, Redis 7 임시 컨테이너와 백엔드 서버를 실행했다.
- Flyway가 빈 PostgreSQL 스키마에 V1~V10을 모두 적용했고 최종 버전 `10`, 성공 상태를 확인했다.
- 실제 HTTP 호출 결과:
  - 미션 완료: `completed=true`, `rewardType=COUPON`
  - 보상 이력: 1건
  - 사용자 쿠폰: 1건, `화천 지역 쿠폰`, 최초 상태 `AVAILABLE`
  - QR payload 발급 후 사용: `USED`
  - 같은 미션 재완료: HTTP 409
  - 같은 QR 재사용: HTTP 409
- DB 최종 확인:
  - `user_missions=1`, `reward_histories=1`, `user_coupons=1`
  - 쿠폰 상태 `USED`
  - 쿠폰 보상 미션 7개 모두 `reward_coupon_id` 매핑됨
- 검증에 사용한 임시 컨테이너와 서버 프로세스는 종료·삭제했다.

## 런타임 화면 검증

- Android 16(API 36) 에뮬레이터에서 디버그 APK 빌드·설치·부팅에 성공했다.
- 온보딩 화면의 한글 문구, 이미지, 하단 CTA가 잘림이나 겹침 없이 렌더링됐다.
- Flutter 웹을 `http://localhost:54631`에서 실제 실행하고 브라우저로 열었다.
- 웹 온보딩 화면이 정상 렌더링됐고 브라우저 콘솔의 warning/error는 없었다.
- `frontend/.env`는 로컬에 없었으므로 비밀 키를 새 파일로 저장하지 않았다. 따라서 Kakao 로그인 기반의 앱 UI 보상 흐름은 실행하지 않고, 실제 PostgreSQL HTTP 흐름과 Flutter 상태 테스트로 검증했다.
- iOS 런타임은 Windows 호스트에서 실행할 수 없어 검증하지 못했다.

## 산출물

- `artifacts/validation/issue-70/android-runtime.png`: Android 16 실제 앱 부팅 화면
- `artifacts/validation/issue-70/web-runtime.png`: Flutter 웹 실제 렌더링 화면

## 남은 리스크

- `benefit_amount`는 금액만 표현하는 기존 모델이라 `양양 서핑 체험 10% 할인권`의 10을 UI에서 금액처럼 표시할 수 있다. 혜택 단위 확장은 이번 이슈 범위에서 제외했다.
- iOS 실제 기기/시뮬레이터 및 Kakao 로그인된 앱 UI의 종단 간 검증은 macOS와 로컬 키 설정이 준비된 환경에서 추가 확인해야 한다.
- Android 빌드에서 Kotlin Gradle Plugin의 향후 Flutter 호환성 경고와 Java 8 source/target 사용 경고가 출력됐다. 현재 빌드는 성공하며 별도 도구 업그레이드 이슈로 분리하는 편이 안전하다.

## 다음 작업

- PR CI에서 PostgreSQL 기반 전체 테스트와 Flutter 검증 결과를 다시 확인한다.
- macOS 담당자가 iOS에서 Kakao 로그인 → 쿠폰 보상 미션 완료 → 보상함 → QR 표시를 확인한다.
- 혜택 단위 모델링이 필요하면 별도 이슈에서 `amount/percent/exchange` 정책을 합의한다.
