# Issue #232 validation

## 작업 요약

- 이슈: #232 `[FE] fix: 지도 상세 진입 후 시스템 뒤로가기 복원`
- 브랜치: `fix/232-map-detail-back-navigation`
- 담당 영역: 지도 카드에서 관광지 상세로 진입하는 라우팅
- 제외 범위: UI 디자인, 지도 핀·카드 상태, 카카오맵 SDK, API·백엔드

## 원인과 변경

- 재현: 지도 카드의 `상세보기` 후 Android 시스템 뒤로가기를 누르면 지도로 복귀하지 않고 앱이 백그라운드로 이동했다.
- 원인: `context.go` 호출이 지도 경로를 상세 경로로 교체해 뒤로갈 히스토리가 남지 않았다.
- 변경: 상세 진입만 `context.push` 방식으로 바꾸어 기존 지도 화면과 선택 카드 상태를 유지했다.
- 회귀 방지: widget test가 상세 진입 후 시스템 pop을 보내고 기존 지도 카드로 돌아왔는지 검증한다.

## 변경 파일

- `frontend/lib/features/map/presentation/screen/map_screen.dart`
- `frontend/test/features/map/map_screen_test.dart`

## 공유 파일 / 계약 변경

- open PR #209, #233의 변경 파일과 겹치지 않는다.
- API 계약, DB migration, 환경 변수, 외부 API 변경 없음
- UI 변경 없음

## 검증

- 수정 전 재현 테스트: 상세에서 시스템 pop 후에도 `상세 2`가 남아 실패했다.
- `flutter test test/features/map/map_screen_test.dart --plain-name "opens detail for the currently selected map marker"`: 통과
- `flutter test test/features/map/map_screen_test.dart`: 지도 13개 테스트 통과
- `flutter analyze`: 이슈 없음
- `flutter test`: 전체 226개 테스트 통과
- `flutter build apk --debug`: 통과
- Android `emulator-5554`: 상세 진입 후 `KEYCODE_BACK` 전송 결과 선택했던 지도 카드로 복귀했고, 앱이 전면에 유지됨

## 산출물

- `android-detail.png`: 시스템 뒤로가기 전 관광지 상세 화면
- `android-after-back.png`: 시스템 뒤로가기 후 복귀한 지도 카드

## 남은 리스크

- 현재 Android 에뮤레이터는 x86_64이고 Kakao Map 네이티브 라이브러리는 ARM64라 지도 타일·핀이 렌더링되지 않는다. 로그의 ABI 불일치로 확인했으며 API 키 문제가 아니다.
- Android ARM64 실기기에서 지도 렌더링 자체는 별도 QA가 필요하다.

## 다음 작업

- 커밋·push 후 PR을 생성하고 CI 통과 시 사용자에게 머지를 요청한다.
