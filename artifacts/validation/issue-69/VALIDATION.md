# Issue 69 QR 쿠폰 조회 및 사용 처리 검증

## 작업 요약

- 이슈: #69
- 브랜치: `feat/69-coupon-qr-use`
- 담당 영역: Team A 쿠폰 QR 조회, 쿠폰 사용 처리, Flutter QR 표시 및 상태 갱신
- 제외 범위: 제휴점 관리자 앱, 관리자 쿠폰 CRUD, 외부 QR 검증 서비스
- 목표: 사용 가능한 본인 쿠폰만 짧게 만료되는 QR을 발급하고, 같은 쿠폰은 한 번만 사용 처리한다.

## 구현 및 문제 해결

1. `GET /coupons/{userCouponId}/qr`에서 사용자와 쿠폰 소유권 및 사용 가능 상태를 확인한다.
2. QR payload에 `userCouponId`, `userId`, 만료 시각을 담고 HMAC-SHA256으로 서명한다.
3. QR 만료 시각은 기본 5분과 쿠폰 자체 만료 시각 중 빠른 값으로 제한한다.
4. `POST /coupons/{userCouponId}/use`에서 서명, QR 만료, 사용자, 쿠폰 ID를 다시 검증한다.
5. 쿠폰 행에 비관적 쓰기 잠금을 적용해 동시 사용 요청 중 하나만 상태를 변경하게 했다.
6. Flutter 상세 화면에서 QR을 표시하고, 되돌릴 수 없다는 한글 확인창을 거친 뒤 사용 처리한다.
7. 사용 성공 후 목록, 상세, QR provider를 무효화해 화면을 즉시 `사용 완료` 상태로 갱신한다.

컨트롤러 POST 테스트를 처음 실행했을 때 Spring MVC 슬라이스의 기본 CSRF 보호로 `403`이 발생했다. 실제 애플리케이션은 `SecurityConfig`에서 stateless API의 CSRF를 비활성화하므로, 컨트롤러 단위 테스트 요청에 `csrf()`를 추가해 테스트 환경과 실제 보안 구성을 구분했다.

## 변경 파일 요약

- `backend/src/main/java/com/gamjamubwatna/coupon/**`: QR 토큰, 조회·사용 서비스, API DTO와 엔드포인트, 쿠폰 사용 도메인 규칙
- `backend/src/main/resources/application.yml`: `COUPON_QR_SECRET`, `COUPON_QR_TTL_SECONDS` 설정
- `backend/src/test/java/com/gamjamubwatna/coupon/**`: 서명, 만료, 소유권, 중복 사용, API 응답 테스트
- `frontend/lib/features/coupon/**`: QR 모델·repository·provider·한글 QR 다이얼로그와 사용 흐름
- `frontend/test/features/coupon/**`: API 경로·payload와 화면 상태 갱신 테스트

## 자동화 검증

### Backend

- `backend\\gradlew.bat test --tests 'com.gamjamubwatna.coupon.*'`
  - 결과: 쿠폰 테스트 29개 통과
- `backend\\gradlew.bat build`
  - 결과: 전체 테스트 111개 및 빌드 통과

### Frontend

- `flutter test test\\features\\coupon`
  - 결과: 쿠폰 테스트 12개 통과
- `flutter analyze`
  - 결과: `No issues found!`
- `flutter test`
  - 결과: 전체 테스트 84개 통과
- `flutter build web`
  - 결과: `build/web` 생성 성공
  - 참고: 기존 `flutter_secure_storage_web`, `geolocator_web`의 Wasm 호환 경고와 기존 Cupertino 아이콘 폰트 경고가 출력됐지만 일반 Web 빌드는 성공했다.

## 실제 HTTP 검증

Docker Desktop을 백그라운드로 시작하고 일회성 `postgres:16`, `redis:7-alpine` 컨테이너를 실행했다. Flyway V1~V9 적용 후 검증 전용 사용자와 쿠폰을 삽입하고 Spring Boot 서버를 실제 PostgreSQL에 연결했다. 검증이 끝난 뒤 서버와 두 컨테이너는 종료 및 삭제했다.

| 시나리오 | 결과 |
| --- | --- |
| 본인 사용 가능 쿠폰 QR 조회 | `200`, 서명 payload와 5분 만료 시각 반환 |
| QR payload로 최초 사용 | `200`, 상태 `USED`와 `usedAt` 반환 |
| 같은 payload로 다시 사용 | `409`, `이미 사용한 쿠폰입니다.` |
| 다른 사용자가 쿠폰 QR 조회 | `404` |
| 서명을 변경한 payload로 사용 | `409`, `쿠폰 QR payload가 유효하지 않거나 만료되었습니다.` |

실제 검증에서 QR payload 길이는 191자였고, 발급 시각으로부터 약 5분 뒤로 만료 시각이 설정됐다. 비밀값과 전체 payload는 산출물에 남기지 않았다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: `backend/src/main/resources/application.yml`
- API 계약: 이슈 #69 작업 시작 댓글에 request/response와 상태 코드를 먼저 기록했다.
- DB migration: 없음
- 환경 변수:
  - `COUPON_QR_SECRET`: 운영 환경 전용 QR 서명 키. 미설정 시 `JWT_SECRET`을 사용한다.
  - `COUPON_QR_TTL_SECONDS`: QR 유효 시간, 기본 300초
- 외부 API: 없음

## 남은 리스크

- Flutter 실제 로그인 세션과 운영 데이터로 Web/iOS/Android 화면을 확인하는 작업은 선행 이슈 #68 머지와 통합 환경이 필요하다.
- 미션 보상 발급부터 QR 사용까지의 플랫폼별 실제 런타임 검증은 후속 이슈 #70에서 수행한다.
- 현재 MVP는 쿠폰 소유자의 Flutter 앱에서 직원 확인 후 사용 완료를 누르는 방식이며, 별도 제휴점 검증 앱은 범위 밖이다.

## 다음 작업

- #68 PR 머지 후 이 브랜치를 최신 `main` 위로 정리한다.
- PR 리뷰와 CI를 확인하고 필요한 피드백을 반영한다.
- #69 머지 후 #70 통합 검증을 진행한다.
