# Issue #490 스탬프 모션·지도 초기 로딩·뒤로가기 UX 검증

## 작업 요약

- 이슈: #490
- 브랜치: `feat/490-stamp-motion-navigation`
- 기준 브랜치: 최신 `origin/main` (`602f41e`)
- 대상: 스탬프 방문 인증 결과, 메인 탭 및 내부 화면 뒤로가기, 지도 탐색 홈 초기 노출

## 변경 사항

- 신규 스탬프 발급 시 실제 스탬프 도구가 내려와 압인되고 올라가는 동작을 추가했다.
- 압인 순간 도장 이미지, 충격 링, 강한 햅틱이 함께 나타나도록 조정했다.
- 하단 탭 이동 시 방문 이력을 보존하고 시스템 뒤로가기로 직전 탭을 복원하도록 변경했다.
- 내부 라우트와 바텀시트는 지도로 이동하기 전에 먼저 닫히도록 공통 뒤로가기 처리를 조정했다.
- 방문 인증 결과에서 미션·감자밭·추천 지도로 이동한 뒤에도 직전 관광지 상세로 돌아갈 수 있게 했다.
- 최신 `main`에 반영된 지도 초기 로딩 개선을 유지했다. 관광지 API가 지연되어도 전체 로딩 화면으로 막지 않고 지도 탐색 홈과 진행 표시를 먼저 노출한다.

## 자동 검증

- `flutter analyze`: 이슈 없음
- `flutter test`: 전체 371개 통과
- `flutter test test/shared/widgets/main_shell_test.dart`: 6개 통과
  - 이전에 방문한 탭 순서 복원
  - 내부 바텀시트 우선 닫기
  - 지역별 스탬프 화면에서 부모 스탬프 탭 복원
  - 루트 지도 유지
- `flutter test test/features/spot/spot_detail_screen_test.dart`: 13개 통과
  - 신규 스탬프 압인 UI와 햅틱 1회
  - 이미 획득한 스탬프에는 압인 동작 미노출
  - 인증 결과에서 감자밭 진입 후 관광지 상세 복원
- `flutter test test/features/map/map_screen_test.dart`: 통과
  - 관광지 목록 로딩 완료 전 지도 탐색 홈 우선 노출
- `flutter build apk --debug --dart-define-from-file=.env`: 성공

## 빌드 산출물

- 경로: `frontend/build/app/outputs/flutter-apk/app-debug.apk`
- 크기: 256,515,104 bytes
- SHA-256: `515F00E64EE516AE6B2ECB412D65111FF6350175F0AD94039128EECC0A251920`

## 실기기 검증

- 이번 작업 시점에는 `flutter devices`에 Android 기기가 연결되어 있지 않아 신규 APK 설치와 육안 검증은 수행하지 못했다.
- 위젯 테스트에서 실제 Android 시스템 뒤로가기 이벤트를 재현해 탭·내부 라우트·바텀시트 순서를 검증했다.

## 남은 리스크

- 스탬프 압인 동작의 최종 체감과 햅틱 세기는 Android 실기기에서 한 번 더 확인하는 것이 좋다.
- Android 빌드는 성공했지만, 현재 일부 플러그인의 Kotlin Gradle Plugin 적용 방식에 관한 Flutter 경고가 있다. 이번 변경과 무관하며 현재 빌드를 차단하지는 않는다.
