# Issue #441 검증 기록

## 작업 요약

- 이슈: [FE] feat: 첫 실행 도움말 Coach Mark 투어 (#441)
- 브랜치: `feat/441-coach-mark-feature-tour`
- 목표: 로그인 이후 메인 셸에 처음 진입한 사용자에게 지도, 내 동선, 스탬프, 감자밭, 미션의 핵심 사용법을 한 번만 안내한다.
- 제외 범위: 백엔드/API, 기존 지도·스탬프·감자밭·미션 비즈니스 로직, 실제 위치 인증 로직, 별도 튜토리얼 페이지

## 구현 확인

### 투어 상태

- `SharedPreferencesFeatureTourStatusStore`가 `completedFeatureTourVersion`에 현재 버전 `1`을 저장한다.
- 같은 버전을 이미 완료한 경우 투어를 다시 열지 않는다.
- 저장소 오류가 발생해도 기존 메인 화면 진입을 막지 않는다.
- 건너뛰기, 마지막 단계의 시작하기, 시스템 뒤로가기는 투어를 종료하고 완료 상태를 저장한다.

### 단계와 이동

1. 지도 발견 영역: `강원도에서 오늘 갈 곳을 찾아보세요`
2. 내 동선: `가고 싶은 곳은 내 동선에 담아보세요`
3. 스탬프: `직접 방문하고 스탬프를 모아요`
4. 감자밭: `여행하며 나만의 감자를 키워보세요`
5. 미션: `점순이와 여행 미션도 즐겨보세요`

- 각 단계는 `GlobalKey`로 실제 렌더링된 위젯의 위치를 읽는다.
- 화면 전환 후에도 120ms 주기로 target 위치를 다시 계산해 고정 좌표에 의존하지 않는다.
- 지도 발견 영역이 아직 렌더링되지 않은 경우 지도 하단 네비게이션을 대체 target으로 사용한다.
- 첫 번째 단계 다음에는 기존 전체 지도 화면으로 이동하고, 두 번째 단계에서 건너뛰거나 뒤로 종료하면 지도 발견 화면으로 돌아온다.
- 지도 기능은 기존 `MapScreen`과 라우팅을 재사용하며 새 지도 인스턴스나 API를 추가하지 않았다.

## 변경 파일

- `frontend/lib/features/feature_tour/data/feature_tour_status_store.dart`: 버전 기반 완료 상태 저장소
- `frontend/lib/features/feature_tour/presentation/feature_tour_targets.dart`: 실제 위젯 target registry
- `frontend/lib/features/feature_tour/presentation/feature_tour_overlay.dart`: scrim, spotlight, 설명 카드, 단계 전환 UI
- `frontend/lib/shared/widgets/navigation/main_shell.dart`: 첫 실행 확인, 화면 이동, 종료/영속화 연결
- `frontend/lib/shared/widgets/navigation/main_bottom_navigation.dart`: 하단 탭 target 연결
- `frontend/lib/app/router/app_router.dart`: 투어 중 전체 지도 진입 query 연결
- `frontend/lib/features/map/presentation/screen/map_screen.dart`: 지도 발견 영역과 내 동선 target 연결
- `frontend/test/features/feature_tour/feature_tour_test.dart`: 상태 저장소와 메인 셸 투어 흐름 테스트

## API/DB/환경 설정

- API 계약 변경: 없음
- DB migration: 없음
- 백엔드 변경: 없음
- 환경 변수: 없음
- 외부 API: 없음
- 상태 저장: 기기 로컬 `SharedPreferences`만 사용

## 실행한 검증

### 통과

- `flutter analyze`
  - 초기 새 테스트에서 `sort_child_properties_last` lint 1건을 확인했다.
  - 테스트 위젯 속성 순서를 수정한 뒤 재실행했고 `No issues found!`로 통과했다.
- `flutter test test/shared/widgets/main_shell_test.dart test/features/map/map_screen_test.dart`
  - 기존 메인 셸/지도 회귀 테스트 통과
- `flutter test test/features/feature_tour/feature_tour_test.dart`
  - 완료 버전 저장/불일치, 건너뛰기, 5단계 이동 및 완료, 완료 후 미표시 검증 통과
- `flutter test`
  - 전체 테스트 `333개 모두 통과`
- `git diff --check`
  - 공백 오류 없음

## 시각/실기기 검증 상태

- 자동 위젯 테스트로 overlay 표시, 단계 문구, target fallback, 탭 이동, 완료 상태를 확인했다.
- 이번 작업에서는 실제 iPhone/Android 화면 캡처를 생성하지 못했으므로, Safe Area 안에서 spotlight와 설명 카드가 모든 단계에 자연스럽게 배치되는지는 실기기에서 추가 확인이 필요하다.
- 실제 위치 권한 팝업과 방문 인증 성공 여부는 이번 이슈의 변경 대상이 아니며, 기존 지도/방문 인증 QA를 별도로 수행해야 한다.

## 현재 UI 관련 확인 메모

- 지도 추천 장소 그룹은 제목과 설명만 남겨 헤더를 단순화했고, 장소 카드의 혼잡도 정보는 장소를 비교하는 데 필요하므로 유지했다.
- 스탬프 지도는 강원도 path의 중심을 유지하고 주변 육지 tint를 기존보다 강화했다. 지도 marker와 선택/인증 동작은 변경하지 않았다.
- 미션 메인은 특별 미션의 점순이 이미지가 카드 경계를 넘지 않도록 조정하고, 일일 미션 완료 수를 상태 칩으로 정리했다. 미션 완료 로직과 하루 3개 노출 정책은 변경하지 않았다.
- 미수확 감자의 최종 정체를 `???`로 보여주는 정책은 기존 감자밭 구현 범위이며, 현재 구현에서도 수확 전 `???`가 유지된다.

## 후속 UI 검증

- `flutter test test/features/map/map_screen_test.dart`: 추천 장소 그룹의 보조 배지 제거와 기존 장소 혼잡도 표시 회귀 확인
- `flutter test test/features/stamp`: 스탬프 지도 중심/육지 배경 조정 후 기존 지도·선택·인증 화면 회귀 확인
- `flutter test test/features/mission/mission_screen_test.dart`: 특별 미션 카드와 일일 미션 메인 화면, 상세 진입/완료 흐름 확인
- 미션 메인 카드는 점순이 이미지와 CTA가 카드 내부에 배치되도록 고정했으며, 실제 기기별 픽셀 단위 시각 검증은 별도 확인이 필요하다.

## 기존 변경사항 보호

- 작업 시작 전부터 존재한 `frontend/ios/Podfile.lock` 변경은 이슈 범위 밖의 사용자 변경으로 판단해 수정하거나 커밋하지 않았다.

## 남은 리스크와 후속 확인

- 실제 로그인 직후 첫 메인 셸 진입, 앱 재시작 후 투어 미표시, iPhone/작은 Android에서 카드가 화면 밖으로 나가지 않는지 실기기 확인이 필요하다.
- 접근성 측면의 스크린리더 순서와 spotlight 외부 콘텐츠 차단 동작은 별도 QA가 필요하다.
