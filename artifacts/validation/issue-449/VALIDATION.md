# Issue #449 출시 전 QA 보완 검증

## 작업 요약

- 이슈: #449 출시 전 QA 실패 항목 보완
- 브랜치: `fix/449-release-qa-blockers`
- 기준 커밋: `e256357` (`origin/main`)
- 대상 빌드: `versionName 0.1.0`, `versionCode 1`
- 대상 기기: Samsung Android 16 / API 36 / 1080x2340, serial `R3CW2056XCY`

이번 검증에 사용한 APK는 과거 `artifacts/validation/issue-93`에서 사용한 APK가 아니라 최신 `origin/main`을 새로 빌드한 파일이다.

## 변경 사항

- 네이티브 카카오 지도 PlatformView가 생성되기 전에 위치 조회가 끝나는 경우에도 현재 위치·스팟·경로를 다시 동기화하도록 보완했다.
- 미션 상세 화면에서 Android 시스템 뒤로가기를 누르면 앱 종료 대신 미션 목록으로 돌아가도록 `PopScope` 처리를 추가했다.
- 릴리스 빌드에서 Firebase 클라이언트 설정이 누락되면 즉시 실패하도록 필수 Dart define 검사를 추가했다.

## 검증

### 자동 검증

- `flutter test test/features/mission/mission_screen_test.dart`: 17개 통과
- `flutter test`: 338개 통과
- `flutter analyze`: 이슈 없음
- `backend/gradlew.bat test`: 496개 테스트, 실패 0, 오류 0, 건너뜀 0
- 최신 빌드: `flutter build apk --debug` 성공
- 릴리스 설정 누락 검증: 필요한 서명키·법적 문구·Firebase define이 없을 때 예상대로 빌드 차단

### 실기기 확인

- 온보딩·권한 안내·지도 로드 확인
- 현재 위치 버튼으로 서울 부근 재중심 및 파란 위치 표식 확인
- 게스트 미션 목록과 로그인 필요 안내 확인
- 오디오 운영 API 89개 점검: 제공 12개, 미제공 77개, 기타 오류 0개
- 성공 음원 URL HTTP 200 및 `audio/mpeg` 응답 확인
- 성공 응답은 서버 `audio_guides` DB 캐시로 재사용되고, 미제공 404는 원천 매핑 부족으로 확인

## 캡처

- `../issue-449-map-loaded.png`: 지도 로드
- `../issue-449-full-map.png`: 전체 지도
- `../issue-449-current-location.png`: 현재 위치 표식 및 재중심
- `../issue-449-mission-list-guest.png`: 게스트 미션 목록
- `AUDIO.md`: 오디오 제공 현황·캐시·응답 속도 기록

## 남은 리스크

- 서명키 파일과 법적 사업자 정보를 이 환경에서 확인할 수 없어 실제 서명 릴리스 APK는 아직 만들지 못했다.
- FCM은 Firebase 프로젝트 설정을 최신 빌드에 주입했지만, 실제 로그인 계정의 토큰으로 포그라운드·백그라운드·종료 상태 수신까지는 별도 발송 테스트가 필요하다.
- QR 제휴 검증은 사용자 요청대로 제외한다.
- 사진 업로드와 방문 기록 장소명은 최신 `main`에 이미 구현되어 이번 변경에서 중복 수정하지 않았다.
