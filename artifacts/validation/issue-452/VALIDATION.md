# Coach Mark 안정화 검증 기록

## 작업 요약

- 이슈: #452 `fix: Coach Mark 노출 누락 및 반복 실행·버벅거림 개선`
- 브랜치: `fix/452-coach-mark-stability-and-coverage`
- 범위: 페이지별 Coach Mark lifecycle, 타깃 측정/스크롤, 주요 화면 타깃 복구, 안전 영역 보정, 스탬프 선택 명소 카드 정보 보강
- 제외 범위: API, DB, 기존 미션·스탬프·지도 기능 계약

## 변경 사항

- 페이지별 완료 상태와 프로세스 내 중복 실행 방지
- 주기적 폴링을 제거하고 안정화된 타깃 측정과 약 7.2초 이내의 제한된 재시도로 전환
- 타깃이 준비되기 전에는 설명 카드를 표시하지 않고, 실제 위치가 확인된 뒤에만 표시
- 지도 marker 안내 카드는 타깃 위치를 따라 재배치하지 않고 하단 위에 고정해 깜빡임 방지
- 지도·스탬프·미션·마이페이지·여행 기록 타깃 연결 복구
- 미션 목록이 비어도 첫 일일 미션 타깃을 사용할 수 있도록 안정적인 fallback 타깃 연결
- 동일 페이지의 새 안내 단계가 이전 완료 기록에 가려지지 않도록 페이지별 tour version 갱신
- Coach Mark 설명 카드가 Safe Area 밖으로 나가지 않도록 위치와 높이 보정
- 스탬프 marker의 기존 테스트 식별자를 유지하고 방문 인증 타깃의 중복 GlobalKey 제거
- 기존 `spotDetailProvider`를 재사용해 선택한 명소 카드에 이미지, 설명, 주소, 영업시간을 실제 값이 있을 때만 표시
- 상세 응답이 없거나 실패해도 스탬프 명소명, 주소 fallback, 방문 인증 CTA와 이미지 placeholder를 유지

## 검증 결과

| 검증 | 결과 |
| --- | --- |
| `flutter analyze` | PASS, No issues found |
| `flutter test test/features/feature_tour/feature_tour_test.dart` | PASS, 9 tests |
| `flutter test test/features/stamp/stamp_book_screen_test.dart` | PASS, 15 tests |
| `flutter test` | PASS, 342 tests |
| `git diff --check` | PASS |

## 최신 main 병합 충돌 해결

PR #454의 최신 `main` 병합 과정에서 `stamp_book_screen_test.dart`가 충돌했습니다. 최신 main의 스탬프 오디오 해설 진입 테스트와 이 브랜치의 선택 명소 상세 정보 테스트를 모두 유지하고, 지도 모듈과 장소 모듈에 중복 정의된 `SpotDetail` 및 provider는 import 별칭으로 분리했습니다.

- `git fetch origin main` 후 `git merge --no-commit --no-ff origin/main` 실행
- 충돌 파일: `frontend/test/features/stamp/stamp_book_screen_test.dart`
- 병합 후 스탬프 화면 테스트: PASS, 15 tests
- 병합 후 전체 Flutter 테스트: PASS, 340 tests
- 병합 후 `flutter analyze`: PASS, No issues found

## 수정 중 발견 및 해결한 문제

첫 전체 테스트에서는 스탬프 선택 상태 전환 중 `stampVisit` GlobalKey가 AnimatedSwitcher의 이전/다음 child에 동시에 존재하는 문제가 발견됐습니다. 또한 Coach Mark 타깃 연결 과정에서 기존 marker ValueKey가 대체되어 스탬프 화면 테스트 3건이 실패했습니다.

방문 인증 타깃을 AnimatedSwitcher 바깥의 안정적인 부모에 두고, marker ValueKey 안쪽에 Coach Mark 타깃을 중첩하는 방식으로 수정한 뒤 스탬프 테스트와 전체 테스트를 다시 실행해 통과시켰습니다.

## API/DB 및 공유 파일

- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 없음
- 기존 사용자 변경 `frontend/ios/Podfile.lock`: 수정하거나 스테이징하지 않음
- 스탬프 카드 정보 보강은 기존 API/DB 계약과 장소 상세 provider를 재사용하며 별도 API/DB 변경 없음
- 페이지별 Coach Mark 완료 상태는 기존 저장소를 재사용하며 map `v5`, stamp/passport `v4`, mission `v3`, my page `v2`로 안내 계약을 갱신함

## 남은 리스크

- 실제 iPhone/Android에서 Kakao Map 늦은 렌더링, route 전환 직후 타깃 생성, 실제 스와이프는 수동 확인이 필요합니다.
- 타깃이 준비되지 않으면 최대 약 7.2초까지 기다린 뒤 해당 Step을 안전하게 건너뜁니다.
- 이전 앱 데이터에 이미 같은 페이지 완료 버전이 저장된 개발 기기에서는 재현을 위해 앱 데이터 초기화 또는 재설치가 필요할 수 있습니다.
