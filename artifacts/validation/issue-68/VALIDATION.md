# Issue #68 검증 기록

## 작업 요약

- 이슈: #68
- 브랜치: `feat/68-coupon-inbox`
- 담당 영역: Team A Flutter 보상함
- 제외 범위: QR 표시, 쿠폰 사용 처리, 백엔드 스키마, 실제 쿠폰 발급

## 구현 범위

- `GET /coupons/me` 사용자 쿠폰 목록 연동
- `GET /coupons/{userCouponId}` 본인 쿠폰 상세 연동
- 사용 가능 / 사용 완료·만료 목록 분리
- 쿠폰 상세 바텀시트
- 로그인 차단, 로딩, 빈 상태, 오류, 재시도 처리
- 인증 세션 변경 시 쿠폰 데이터 폐기 및 재조회

## 검증

### 쿠폰 국소 테스트

```powershell
flutter test test/features/coupon
```

- 결과: 성공, 9개 테스트 통과
- 범위: JSON 파싱, API 경로, 오류 응답, 인증 세션, 탭 필터, 상세, 상태 UI

### 정적 분석

```powershell
flutter analyze
```

- 결과: `No issues found!`

### 전체 Flutter 테스트

```powershell
flutter test
```

- 결과: 성공, 81개 테스트 통과
- 기존 마이페이지 보상함 이동 테스트를 실데이터 화면의 빈 상태 기준으로 갱신

### Web 빌드

```powershell
flutter build web --dart-define=KAKAO_JAVASCRIPT_KEY=test-key --dart-define=KAKAO_NATIVE_APP_KEY=test-key --dart-define=API_BASE_URL=http://localhost:8080/api
```

- 결과: `Built build\web`
- 기존 의존성의 Wasm 호환성 및 CupertinoIcons 경고가 있으나 JavaScript Web 빌드는 성공

## 남은 리스크

- 현재 DB에는 사용자 쿠폰을 자동 발급하는 흐름이 없어 실제 계정에서는 빈 상태가 정상입니다.
- QR 표시와 사용 처리는 #69, 미션 보상 쿠폰 발급과 실제 전체 흐름은 #70에서 검증합니다.
