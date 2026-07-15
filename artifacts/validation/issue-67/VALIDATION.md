# Issue #67 검증 기록

## 작업 요약

- 이슈: #67
- 브랜치: `feat/67-coupon-query-api`
- 담당 영역: Team A 쿠폰 조회 백엔드
- 제외 범위: Flutter 연동, QR 조회, 쿠폰 사용 처리, 실제 쿠폰 발급

## API 계약

- `GET /coupons/me`: 인증 사용자의 쿠폰을 발급 최신순으로 조회
- `GET /coupons/{userCouponId}`: 인증 사용자가 소유한 쿠폰 상세 조회
- 저장 상태가 `AVAILABLE`이어도 유효기간이 지났으면 응답 상태를 `EXPIRED`로 계산
- 다른 사용자의 쿠폰은 존재 여부를 노출하지 않고 `404 Not Found` 반환

## 공유 파일 및 데이터베이스 변경

- `V9__create_coupons.sql`을 추가해 `coupons`, `user_coupons` 테이블을 생성
- 이미 반영된 migration은 수정하지 않음
- 사용자별 최신순 조회와 쿠폰 FK 조회를 위한 인덱스 추가
- 환경 변수와 외부 API 변경 없음

## 검증

### 국소 테스트

```powershell
.\gradlew.bat test --tests "com.gamjamubwatna.coupon.*"
```

- 결과: 성공
- 검증 범위: 조회 서비스, 인증/소유권 응답, Controller JSON, migration/JPA 검증

### 백엔드 전체 테스트 및 빌드

```powershell
.\gradlew.bat clean test build
```

- 결과: 성공
- Gradle 출력: `BUILD SUCCESSFUL in 44s`

### Gemini 리뷰 반영

- `Coupon` 생성자에 필수 문자열과 음수 혜택 금액 검증 추가
- `UserCoupon` 생성자에 필수 참조, 발급/만료 시간, 상태/사용 일시 정합성 검증 추가
- 도메인 생성자 테스트 6개 추가
- 쿠폰 국소 테스트 결과: `BUILD SUCCESSFUL in 18s`
- 백엔드 전체 테스트 및 빌드 결과: `BUILD SUCCESSFUL in 38s`

## 남은 작업

- #68 Flutter 보상함 실데이터 연동
- #69 QR 쿠폰 조회 및 사용 처리
- #70 미션 보상부터 QR 사용까지 통합 검증
