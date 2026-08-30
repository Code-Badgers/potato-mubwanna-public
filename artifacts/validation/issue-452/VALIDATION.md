# Coach Mark 안정화 검증 기록

## 작업 요약

- 이슈: #452 `fix: Coach Mark 노출 누락 및 반복 실행·버벅거림 개선`
- 브랜치: `fix/452-coach-mark-stability-and-coverage`
- 범위: 설치별·페이지별 Coach Mark lifecycle, 타깃 측정/스크롤, 주요 화면 타깃 복구, 안전 영역 보정, 스탬프 선택 명소 카드 정보 보강
- 제외 범위: API, DB, 기존 미션·스탬프·지도 기능 계약

## 변경 사항

- 페이지별 완료 상태와 프로세스 내 중복 실행 방지
- 페이지 이동이 필요한 tour는 현재 단계 번호를 저장하고 돌아왔을 때 같은 단계부터 재개
- 데이터 로딩 중 타깃을 찾지 못한 페이지는 완료 상태로 소비하지 않고 다음 진입에서 다시 시도
- 주기적 폴링을 제거하고 안정화된 타깃 측정과 약 14.4초 이내의 제한된 재시도로 전환
- 타깃이 준비되기 전에는 설명 카드를 표시하지 않고, 실제 위치가 확인된 뒤에만 표시
- 지도 marker 안내 카드는 타깃 위치를 따라 재배치하지 않고 하단 위에 고정해 깜빡임 방지
- 지도·스탬프·패스포트·감자밭·미션·명소 상세·마이페이지·여행 기록 타깃 연결 복구
- 미션 목록이 비어도 첫 일일 미션 타깃을 사용할 수 있도록 안정적인 fallback 타깃 연결
- 동일 페이지의 새 안내 단계가 이전 완료 기록에 가려지지 않도록 페이지별 tour version 갱신
- 페이지별 tour는 완료 또는 건너뛰기 시에만 완료 상태로 고정하고, 중간에 다른 화면으로 이동하면 저장된 단계부터 이어서 표시
- 하단 내비게이션을 제외한 실제 Coach Mark Host 높이로 viewport를 계산해 감자밭 하단 기능까지 자동 스크롤
- 스크롤할 수 없는 전체 지도 타깃에는 불필요한 `ensureVisible`을 실행하지 않아 검은 scrim만 남는 상태를 방지
- 지도 여행 홈의 장소 카드 안내 뒤에는 홈을 유지해 네 번째 `지도 크게 보기` 안내와 전체 지도 marker 안내가 이어지도록 수정
- 전체 지도 marker 안내는 선택 장소 카드가 아니라 장소 카드 위의 실제 지도 영역 전체를 Spotlight하고, 같은 영역의 지도 터치를 허용하도록 수정
- marker 선택 뒤에는 장소 카드 펼치기와 `내 동선` 안내가 차례로 이어지도록 지도 7단계 구성을 테스트로 고정
- 스탬프의 방문 인증 안내는 카드 전체가 아니라 `방문 인증하기` 버튼만 Spotlight하도록 타깃을 분리
- 방문 인증 안내에서 스탬프 획득과 관광 오디오 해설을 함께 알리고, 장소 상세의 오디오 재생 → 방문 인증 안내로 이어지도록 문구와 tour version 갱신
- 잘못 저장된 기존 본 상태를 무효화하고 수정된 안내를 페이지별로 한 번 다시 제공하도록 tour version 갱신
- Coach Mark 설명 카드가 Safe Area 밖으로 나가지 않도록 위치와 높이 보정
- 스탬프 marker의 기존 테스트 식별자를 유지하고 방문 인증 타깃의 중복 GlobalKey 제거
- 기존 `spotDetailProvider`를 재사용해 선택한 명소 카드에 이미지, 설명, 주소, 영업시간을 실제 값이 있을 때만 표시
- 상세 응답이 없거나 실패해도 스탬프 명소명, 주소 fallback, 방문 인증 CTA와 이미지 placeholder를 유지

## 검증 결과

| 검증 | 결과 |
| --- | --- |
| `flutter analyze` | PASS, No issues found |
| `flutter test test/features/feature_tour/feature_tour_test.dart --reporter expanded` | PASS, 17 tests |
| 지도·스탬프·감자밭·미션·마이 화면 회귀 테스트 | PASS, 93 tests |
| `flutter test --reporter compact` | PASS, 354 tests |
| `git diff --check` | PASS |

## 최신 main 병합 충돌 해결

PR #454의 최신 `main` 병합 과정에서 `stamp_book_screen_test.dart`가 충돌했습니다. 최신 main의 스탬프 오디오 해설 진입 테스트와 이 브랜치의 선택 명소 상세 정보 테스트를 모두 유지하고, 지도 모듈과 장소 모듈에 중복 정의된 `SpotDetail` 및 provider는 import 별칭으로 분리했습니다.

- `git fetch origin main` 후 `git merge --no-commit --no-ff origin/main` 실행
- 충돌 파일: `frontend/test/features/stamp/stamp_book_screen_test.dart`
- 병합 후 스탬프 화면 테스트: PASS, 15 tests
- 병합 후 전체 Flutter 테스트: PASS, 340 tests
- 병합 후 `flutter analyze`: PASS, No issues found

추가로 최신 `main`의 인증 복구 변경을 반영하는 과정에서는 `map_screen.dart` 한 곳이 충돌했습니다. 최신 지도 화면 구조를 유지하고, 전체 지도 Coach Mark가 장소 카드 위의 실제 지도 영역 전체만 Spotlight하도록 결합했습니다.

- 병합 후 지도·Coach Mark·미션 대상 테스트: PASS, 63 tests
- 병합 후 전체 Flutter 테스트: PASS, 354 tests
- 병합 후 `flutter analyze`: PASS, No issues found

## 수정 중 발견 및 해결한 문제

첫 전체 테스트에서는 스탬프 선택 상태 전환 중 `stampVisit` GlobalKey가 AnimatedSwitcher의 이전/다음 child에 동시에 존재하는 문제가 발견됐습니다. 또한 Coach Mark 타깃 연결 과정에서 기존 marker ValueKey가 대체되어 스탬프 화면 테스트 3건이 실패했습니다.

방문 인증 타깃을 AnimatedSwitcher 바깥의 안정적인 부모에 두고, marker ValueKey 안쪽에 Coach Mark 타깃을 중첩하는 방식으로 수정한 뒤 스탬프 테스트와 전체 테스트를 다시 실행해 통과시켰습니다.

실기기에서 스탬프·미션·마이페이지 안내가 사라진 원인은 타깃이 아직 준비되지 않은 상태에서도 Host 활성화와 동시에 `seen`을 저장하던 순서였습니다. 화면 데이터가 늦게 준비되면 안내는 한 번도 보이지 않았지만 이미 본 페이지로 남았습니다. 저장 시점을 첫 카드 표시 이후로 옮기고, 모든 타깃이 누락된 경우에는 상태를 저장하지 않도록 수정했습니다.

지도 네 번째 단계의 검은 배경만 남는 현상과 감자밭 하단 안내의 스크롤 실패는 전체 `MediaQuery` 높이와 하단 내비게이션을 제외한 실제 Host 높이가 달랐기 때문입니다. Overlay `RenderBox`의 실제 크기와 Scrollable 존재 여부를 기준으로 자동 스크롤을 결정하도록 바꾸고 해당 조건을 widget test로 고정했습니다.

## API/DB 및 공유 파일

- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 없음
- 기존 사용자 변경 `frontend/ios/Podfile.lock`: 수정하거나 스테이징하지 않음
- 스탬프 카드 정보 보강은 기존 API/DB 계약과 장소 상세 provider를 재사용하며 별도 API/DB 변경 없음
- 페이지별 Coach Mark 상태는 기존 SharedPreferences 저장소의 완료 기록과 새 단계 진행 기록을 함께 사용함. map `v9`, stamp `v7`, passport `v6`, potato `v7`, mission `v5`, spot `v3`, my page `v4`, travel record `v3`로 안내 계약을 관리함
- 진행 중인 단계는 `featureTourStepIndex.<tourId>`에 저장하고 완료 시 제거함
- 완료 상태(`completedFeatureTourVersion`, `completedFeatureTourVersions`)는 기존 호환성을 유지하며, 완료된 tour는 seen 상태로 간주함

## 남은 리스크

- 실제 iPhone/Android에서 Kakao Map 늦은 렌더링, route 전환 직후 타깃 생성, 실제 스와이프는 수동 확인이 필요합니다.
- 타깃이 준비되지 않으면 최대 약 14.4초까지 기다린 뒤 해당 Step을 안전하게 건너뜁니다. 기다리는 동안 scrim과 설명 카드를 띄우지 않아 화면을 막지 않습니다.
- 같은 설치에서 페이지 tour를 완료하거나 건너뛰면 다시 표시하지 않습니다. 중간 이탈 시에는 처음부터 반복하지 않고 저장된 단계부터 재개합니다.
- 저장 정책은 계정 서버 동기화가 아닌 설치 단위 SharedPreferences입니다. 기기 변경이나 앱 데이터 삭제 뒤에는 다시 표시될 수 있습니다.
