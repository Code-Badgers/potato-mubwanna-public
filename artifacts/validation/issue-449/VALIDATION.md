# Issue #449 출시 전 QA 보완 검증

## 작업 요약

- 이슈: #449 출시 전 QA 실패 항목 보완
- 브랜치: `fix/449-release-qa-blockers`
- 기준 커밋: `769c1a5` (최신 `origin/main` `e256357`에 QA 보완을 적용한 커밋)
- 대상 빌드: `versionName 0.1.0`, `versionCode 1`
- 대상 기기: Samsung Android 16 / API 36 / 1080x2340, serial `R3CW2056XCY`

이번 검증에 사용한 APK는 과거 `artifacts/validation/issue-93`에서 사용한 APK가 아니라 최신 `origin/main`에 QA 보완을 적용한 뒤 다시 빌드·설치한 파일이다.

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
- 최신 수정본 빌드: `flutter build apk --debug` 성공 후 실기기 재설치 확인
- 릴리스 설정 누락 검증: 필요한 서명키·법적 문구·Firebase define이 없을 때 예상대로 빌드 차단

### 2026-08-29 재검증

- 지도 관광지 상세 UI 변경은 이번 적용 범위에서 제외했다.
- `flutter test test/features/stamp/stamp_book_screen_test.dart test/features/spot/spot_detail_screen_test.dart test/features/audio/audio_playback_controller_test.dart test/features/map/map_screen_test.dart`: 58개 통과
- `flutter test`: 전체 339개 통과
- 스탬프 마커 선택 → `방문 인증하기` → 관광지 상세 → 오디오 재생 흐름을 위젯 테스트로 확인했다.
- `flutter analyze` 대상 스탬프·관광지 상세·오디오·지도 파일: 이슈 없음
- `flutter build apk --debug --dart-define-from-file=.env`: 성공
- 공개 API에서 스탬프 대상 남이섬(`/spots/2`)과 오디오(`/audio-guides/spots/2`)가 200으로 응답하고, 음원 URL이 `audio/mpeg`로 응답하는 것을 확인했다.

### 실기기 확인

- 온보딩·권한 안내·지도 로드 확인
- 현재 위치 버튼으로 서울 부근 재중심 및 파란 위치 표식 확인
- 게스트 미션 목록과 로그인 필요 안내 확인
- 오디오 운영 API 89개 점검: 제공 12개, 미제공 77개, 기타 오류 0개
- 성공 음원 URL HTTP 200 및 `audio/mpeg` 응답 확인
- 성공 응답은 서버 `audio_guides` DB 캐시로 재사용되고, 미제공 404는 원천 매핑 부족으로 확인
- 최신 APK를 실기기에 재설치하고 스탬프 탭·패스포트 화면 진입을 확인했다.
- 실기기는 게스트 세션이어서 인증이 필요한 랠리북 마커와 스탬프 상세 오디오의 직접 재생은 수행하지 못했다. 해당 경로는 위젯 통합 테스트와 공개 API 응답으로 보완했다.

## 캡처

- `../issue-449-map-loaded.png`: 지도 로드
- `../issue-449-full-map.png`: 전체 지도
- `../issue-449-current-location.png`: 현재 위치 표식 및 재중심
- `../issue-449-stamp-audio-start.png`: 최신 APK 시작 화면
- `../issue-449-stamp-audio-tour.png`: 최신 APK 스탬프 투어 화면
- `../issue-449-mission-list-guest.png`: 게스트 미션 목록
- `AUDIO.md`: 오디오 제공 현황·캐시·응답 속도 기록

## 남은 리스크

- 서명키 파일과 법적 사업자 정보를 이 환경에서 확인할 수 없어 실제 서명 릴리스 APK는 아직 만들지 못했다.
- FCM은 Firebase 프로젝트 설정을 최신 빌드에 주입했지만, 실제 로그인 계정의 토큰으로 포그라운드·백그라운드·종료 상태 수신까지는 별도 발송 테스트가 필요하다.
- QR 제휴 검증은 사용자 요청대로 제외한다.
- 사진 업로드와 방문 기록 장소명은 최신 `main`에 이미 구현되어 이번 변경에서 중복 수정하지 않았다.
- 인증된 실기기에서 남이섬 등 오디오 제공 스탬프 관광지를 직접 재생하는 최종 확인은 카카오 로그인 세션 확보 후 한 번 더 수행할 수 있다.
