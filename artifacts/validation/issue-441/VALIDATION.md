# Issue #441 검증 기록

## 작업 요약

- 이슈: [FE] feat: 첫 실행 도움말 Coach Mark 투어 (#441)
- 브랜치: `feat/441-coach-mark-feature-tour`
- 목표: 사용자가 각 페이지에 처음 진입했을 때 해당 화면의 핵심 기능을 실제 UI와 함께 익히는 페이지별 Guided Feature Tour를 제공한다.
- 제외 범위: 백엔드/API, 기존 지도·스탬프·감자밭·미션 비즈니스 로직, 별도 온보딩 화면

## 구현 확인

### 페이지별 투어

- `map-v3`: 지도 발견 홈, 취향별 코스 카드, 지금 가기 좋은 곳, 마커 선택, 장소 카드 펼치기, 내 동선
- `stamp-v3`: 스탬프 지도, 패스포트 버튼, 명소 선택
- `passport-v2`: 여행 패스포트
- `potato-v3`: 감자 성장 상태, 돌봄 버튼, 걸음 성장, 정보 보기, 대표 감자 변경
- `mission-v2`: 오늘의 미션 카드
- `spot-v1`: 관광 해설 오디오 재생, 방문 인증
- `my-page-v1`: 여행 기록
- 각 투어는 해당 route에 진입했을 때만 시작하며, Coach Mark가 다른 Bottom Navigation 탭으로 사용자를 강제 이동시키지 않는다.

### 상태 저장

- `SharedPreferencesFeatureTourStatusStore`가 `completedFeatureTourVersions`에 투어 ID별 완료 버전을 저장한다.
- 기존 `completedFeatureTourVersion` 키도 읽어 이전 구현의 완료 상태를 호환한다.
- 지도 투어를 완료해도 스탬프·감자밭·미션 투어 상태에는 영향을 주지 않는다.
- 상태 저장 실패가 앱 전체 진입을 막지 않도록 기존의 비차단 정책을 유지한다.

### 실제 UI 연결

- `FeatureTourTargets`의 `GlobalKey`로 화면에 실제 렌더링된 target을 등록한다.
- overlay는 target의 `RenderBox`를 측정하고, 화면 밖이면 `Scrollable.ensureVisible`로 부드럽게 이동한 뒤 약 160ms 동안 레이아웃 안정화를 기다린다.
- target을 찾지 못하면 최대 10회 재시도한 뒤 해당 단계만 건너뛰며 앱을 막지 않는다.
- 지도 홈의 코스/지금 가기 좋은 곳, 감자밭의 정보 보기/대표 감자 변경, 마이페이지의 여행 기록처럼 화면 아래에 있는 target도 같은 자동 스크롤 흐름을 사용한다.
- DraggableScrollableSheet의 장소 카드 펼치기 단계는 사용자가 실제로 위로 스와이프해야 다음 단계로 진행한다.
- 지도 마커와 Kakao/custom map처럼 Flutter 하위 RenderBox를 직접 얻기 어려운 대상은 지도 영역을 spotlight하고, 실제 marker callback이 해당 단계를 완료한다.
- `targetTap`, `swipeUp`, `navigationResult`, `nextButton` 유형을 분리했다.
- 상호작용 단계에서는 target 바깥만 `AbsorbPointer`로 막아 실제 버튼·지도·스와이프 입력이 target까지 전달되도록 했다.

### Coach Mark UI

- 화면 바깥은 반투명 검정 scrim으로 처리한다.
- 정확한 target만 초록색 outline과 spotlight로 강조한다.
- 설명 카드는 흰색 92% 투명도, `BackdropFilter` blur 20, 낮은 투명도의 `#56C787` border를 사용한다.
- 설명 카드의 최대 높이는 210px이며, 내부 여백과 글자 크기를 줄여 화면을 과하게 가리지 않도록 했다.
- 단순 안내 단계는 `다음`, 실제 조작 단계는 `직접 눌러보세요`/`카드를 위로 올려보세요` 힌트를 표시한다.

## 변경 파일

- `frontend/lib/features/feature_tour/data/feature_tour_status_store.dart`: 투어 ID별 완료 버전 저장 및 기존 키 호환
- `frontend/lib/features/feature_tour/presentation/feature_tour_targets.dart`: 페이지별 실제 target registry
- `frontend/lib/features/feature_tour/presentation/feature_tour_overlay.dart`: RenderBox spotlight, 자동 스크롤, 상호작용 통과, glass Coach Mark
- `frontend/lib/features/feature_tour/presentation/feature_tour_host.dart`: route 단위 투어 lifecycle, controller, scope, 완료 저장
- `frontend/lib/features/feature_tour/presentation/feature_tour_definitions.dart`: map/stamp/passport/potato/mission/spot/my-page 투어 단계 정의
- `frontend/lib/app/router/app_router.dart`: 지도 셸 외 spot·my-page route의 `FeatureTourHost` 연결
- `frontend/lib/shared/widgets/navigation/main_shell.dart`: 전역 강제 투어와 탭 이동 제거, 기존 shell 유지
- `frontend/lib/features/map/presentation/screen/map_screen.dart`: 지도 크게 보기, 마커, 장소 카드 펼치기, 내 동선 target 및 실제 완료 callback
- `frontend/lib/features/stamp/presentation/screen/stamp_book_screen.dart`: 스탬프 지도·마커·패스포트 target과 실제 이동 callback 연결
- `frontend/lib/features/potato/presentation/screen/potato_collection_screen.dart`: 성장·돌봄·걸음·정보 보기·대표 감자 target 연결
- `frontend/lib/features/spot/presentation/screen/spot_detail_screen.dart`: 오디오 재생·방문 인증 target과 실제 완료 callback 연결
- `frontend/lib/features/mypage/presentation/screen/my_page_screen.dart`: 여행 기록 target 연결
- `frontend/test/features/feature_tour/feature_tour_test.dart`: 페이지별 target 정의, target tap, 자동 스크롤, 독립 상태 검증

## API/DB/환경 설정

- API 계약 변경: 없음
- DB migration: 없음
- 백엔드 변경: 없음
- 환경 변수: 없음
- 외부 API: 없음
- 상태 저장: 기기 로컬 `SharedPreferences`만 사용

## 실행한 검증

### 통과

- `flutter test test/features/feature_tour/feature_tour_test.dart test/features/spot/spot_detail_screen_test.dart`
  - 페이지별 target 정의, target tap, 자동 스크롤, 오디오/방문 인증 회귀 등 19개 테스트 통과
- `flutter test test/features/potato/potato_collection_screen_test.dart`
  - 대표 감자 변경·감자밭 상호작용을 포함한 감자밭 회귀 테스트 21개 통과
- `flutter analyze`
  - `No issues found!`
- `flutter test`
  - 전체 Flutter 테스트 335개 통과
- `git diff --check`
  - 공백 오류 없음

## 시각/실기기 검증 상태

- 자동 위젯 테스트로 overlay 표시, target tap 전후 단계 유지, 자동 스크롤, 페이지별 상태 독립을 확인했다.
- 오디오 재생과 방문 인증 버튼은 기존 spot detail 위젯 테스트에서 실제 key와 callback 렌더링을 확인했다.
- 실제 iPhone/Android 화면 캡처는 이번 검증에서 생성하지 못했다. iPhone 16e와 작은 Android에서 Safe Area, target과 카드의 겹침, 지도 native marker 터치 전달을 실기기에서 확인해야 한다.
- 실제 위치 권한 팝업과 방문 인증 성공 여부는 이번 변경 대상이 아니므로 기존 지도/방문 인증 QA를 별도로 수행해야 한다.

## 기존 변경사항 보호

- 작업 시작 전부터 존재한 `frontend/ios/Podfile.lock` 변경은 이슈 범위 밖의 사용자 변경으로 판단해 수정하거나 커밋하지 않았다.

## 남은 리스크와 후속 확인

- 로그인 직후 각 route 최초 진입에서 status read와 첫 frame 사이에 overlay가 자연스럽게 나타나는지 확인이 필요하다.
- 지도 크게 보기 후 Kakao map이 준비되기 전 target retry가 발생할 수 있으므로 실제 기기에서 marker 단계가 안전하게 skip되지 않는지 확인해야 한다.
- 실제 swipe 입력이 `spotSheetHandle` target까지 전달되고, 설명 카드가 target을 가리지 않는지 확인해야 한다.
- 접근성 측면의 스크린리더 순서와 spotlight 외부 콘텐츠 차단 동작은 별도 QA가 필요하다.
