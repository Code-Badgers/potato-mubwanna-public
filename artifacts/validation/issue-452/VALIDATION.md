# Coach Mark 안정화 검증 기록

## 작업 요약

- 이슈: #452 `fix: Coach Mark 노출 누락 및 반복 실행·버벅거림 개선`
- 브랜치: `fix/452-coach-mark-stability-and-coverage`
- 범위: 페이지별 Coach Mark lifecycle, 타깃 측정/스크롤, 주요 화면 타깃 복구, 안전 영역 보정
- 제외 범위: API, DB, 기존 미션·스탬프·지도 기능 계약

## 변경 사항

- 페이지별 완료 상태와 프로세스 내 중복 실행 방지
- 주기적 폴링을 제거하고 안정화된 타깃 측정과 제한된 재시도로 전환
- 지도·스탬프·미션·마이페이지·여행 기록 타깃 연결 복구
- Coach Mark 설명 카드가 Safe Area 밖으로 나가지 않도록 위치와 높이 보정
- 스탬프 marker의 기존 테스트 식별자를 유지하고 방문 인증 타깃의 중복 GlobalKey 제거

## 검증 결과

| 검증 | 결과 |
| --- | --- |
| `flutter analyze` | PASS, No issues found |
| `flutter test test/features/feature_tour/feature_tour_test.dart` | PASS, 7 tests |
| `flutter test test/features/stamp/stamp_book_screen_test.dart` | PASS, 14 tests |
| `flutter test` | PASS, 337 tests |
| `git diff --check` | PASS |

## 수정 중 발견 및 해결한 문제

첫 전체 테스트에서는 스탬프 선택 상태 전환 중 `stampVisit` GlobalKey가 AnimatedSwitcher의 이전/다음 child에 동시에 존재하는 문제가 발견됐습니다. 또한 Coach Mark 타깃 연결 과정에서 기존 marker ValueKey가 대체되어 스탬프 화면 테스트 3건이 실패했습니다.

방문 인증 타깃을 AnimatedSwitcher 바깥의 안정적인 부모에 두고, marker ValueKey 안쪽에 Coach Mark 타깃을 중첩하는 방식으로 수정한 뒤 스탬프 테스트와 전체 테스트를 다시 실행해 통과시켰습니다.

## API/DB 및 공유 파일

- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 없음
- 기존 사용자 변경 `frontend/ios/Podfile.lock`: 수정하거나 스테이징하지 않음

## 남은 리스크

- 실제 iPhone/Android에서 Kakao Map 늦은 렌더링, route 전환 직후 타깃 생성, 실제 스와이프는 수동 확인이 필요합니다.
- 타깃이 약 2.16초 동안 준비되지 않으면 해당 Step을 안전하게 건너뛰도록 제한되어 있습니다.
