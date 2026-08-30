# Issue #458 Validation

## 작업 목표

- 제휴 미확정 쿠폰을 공모전 시연용으로 명확히 표시한다.
- 공개 앱에서 실제 쿠폰 사용 완료 처리를 막는다.
- 최신 Release APK로 Android 실기기 핵심 기능을 재검증한다.

## 변경 내용

- 쿠폰 목록, 상세, QR 화면에 `공모전 시연용 쿠폰 · 실제 사용 불가` 안내를 추가했다.
- 사용 가능 상태를 `시연용`, 사용 완료 상태 묶음을 `지난 기록`으로 표시한다.
- QR은 시연을 위해 유지하고 `실제 사용 불가` 버튼을 비활성화했다.
- V45 Flyway migration으로 기존 10개 쿠폰 카탈로그의 이름, 설명, 사용처를 시연용으로 변경한다.

## 검증 결과

- `flutter analyze`: 통과, 이슈 0건
- `flutter test`: 통과, 343건
- `gradlew test`: 통과, 497건
- `gradlew build`: 통과
- 쿠폰 화면 단위 테스트: 통과, 실제 사용 API 미호출 확인
- 쿠폰 migration 테스트: 통과, 전체 10개 카탈로그 시연 문구 확인

## 진행 중 발생한 문제와 해결

- 사용 완료 흐름을 제거한 뒤 QR 닫기 버튼에 기존 `_isBusy` 참조가 남아 첫 프론트 테스트가 컴파일에 실패했다. 남은 참조를 제거하고 다시 실행해 통과했다.
- 첫 전체 정적 검사에서 비활성 버튼에 `const` 최적화 경고 2건이 발생했다. 생성자를 상수화한 뒤 `flutter analyze` 이슈 0건을 확인했다.

## 변경 파일

- `frontend/lib/features/coupon/presentation/screen/coupon_screen.dart`
- `frontend/test/features/coupon/coupon_screen_test.dart`
- `backend/src/main/resources/db/migration/V45__mark_coupons_as_demo_only.sql`
- `backend/src/test/java/com/gamjamubwatna/coupon/domain/CouponMigrationTest.java`

## 남은 검증

- 정식 서명 Release APK 빌드 및 실기기 설치: 통과
- Android 실기기(Samsung SM-S916N, Android 16) 핵심 흐름: 통과
  - 시작 화면 → 홈 지도 로딩 및 기존 로그인 세션 유지: 통과
  - 감자밭 대표 감자·레벨·성장 수치·걸음 수 표시: 통과
  - 미션 목록·미션 상세 진입: 통과
  - 카메라 권한 거부 시 앱 종료 없이 `카메라 권한이 필요합니다.` 안내: 통과
  - 스탬프 패스포트·관광지 상세·모의 위치 방문 인증 중복 방지: 통과
  - 관광지 상세의 Odii 오디오 재생(남이섬 00:00 → 00:26 진행): 통과
  - 지도 전체 보기·카테고리 필터·동선 추가/제거: 통과
  - 여행 기록 장소·날짜 표시: 통과
  - 공지 목록·상세, 설정·약관 화면: 통과
  - 강제 종료·재실행 및 뒤로가기 연속 입력: 통과
- APK 증적: `C:\Users\user\Desktop\potato-mubwanna-release-build\potato-mubwanna-issue458-demo-release.apk`
  - SHA-256: `FCAF6AFD0F5C3D8710D6D42717A5FD905025B01B7FE2A0ED87713E0905D78D47`
  - 정식 JKS v2 서명 확인
- 실기기 캡처는 release-build 폴더의 `issue458-*.png`에 보관했다.
- Notion 출시 체크리스트의 실기기 증적 반영은 V45 운영 배포 후 쿠폰 카탈로그 문구까지 확인한 뒤 마무리한다.

## 제외 범위와 리스크

- 가맹점용 QR 스캐너, POS, 정산 기능은 이번 이슈 범위가 아니다.
- QR 미션의 정상·오류 실물 QR 검증은 현재 노출되는 일일 미션에 QR 유형이 없어 실기기에서 수행하지 못했다. 현장 또는 별도 QR 표본이 필요하다.
- V45 쿠폰 카탈로그 문구는 백엔드 운영 반영 전이라 현재 실기기 상세 데이터가 구문구로 보일 수 있으며, 앱 전면 배너가 시연 전용 상태를 명확히 고지한다.
