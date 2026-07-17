# Issue #94 대표 감자 변경 API 및 프론트 연동 검증

## 작업 목표

- 사용자가 감자 도감에서 수집한 감자 중 하나를 대표 감자로 변경할 수 있게 한다.
- 백엔드는 `PATCH /api/potatoes/me/representative` API를 제공하고, 프론트는 대표 감자 변경 시트에서 해당 API를 호출한다.
- 대표 감자는 사용자당 하나만 유지하며, 보유하지 않은 감자는 대표 감자로 지정할 수 없다.

## 변경 요약

- API 계약 문서에 대표 감자 변경 endpoint를 추가했다.
- 백엔드에 대표 감자 변경 request/response DTO, command service, 도메인 상태 변경 메서드, controller endpoint를 추가했다.
- 프론트에 대표 감자 변경 API path, repository 메서드, bottom sheet 선택 이벤트, 로딩/스낵바 처리를 추가했다.
- 위젯 테스트에 대표 감자 변경 시 repository 호출 여부를 검증하는 케이스를 추가했다.

## PAAR 기록

### 1. API 계약 선반영

- Problem: 프론트와 백엔드가 동시에 변경되는 작업이라 request/response 형태가 먼저 고정되어야 했다.
- Analysis: 기존 협업 규칙상 API 계약 변경은 구현 전에 `agents_docs/07_api_specification.md`에 명시해야 한다.
- Action: `PATCH /api/potatoes/me/representative`의 request, response, 오류 규칙을 문서에 먼저 추가했다.
- Result: 구현 전 계약이 명확해졌고, 백엔드/프론트 구현이 같은 응답 구조를 바라보게 되었다.

### 2. 대표 감자 단일성 보장

- Problem: 대표 감자는 사용자당 하나만 유지되어야 한다.
- Analysis: 선택한 감자만 `representative=true`로 바꾸고 기존 대표 감자를 해제해야 하며, 같은 감자를 다시 선택해도 성공해야 한다.
- Action: `PotatoCommandService`에서 사용자의 보유 감자 목록을 조회한 뒤 선택 감자는 `markRepresentative()`, 나머지는 `unmarkRepresentative()`로 정규화했다.
- Result: 같은 감자를 다시 선택해도 성공하고, 이전 대표 감자는 자동으로 해제된다.

### 3. 보유하지 않은 감자 방어

- Problem: 클라이언트가 임의의 `potatoId`를 보내면 미획득 감자가 대표 감자로 지정될 수 있다.
- Analysis: 대표 감자는 `user_potatoes`에 존재하는 감자만 선택 가능해야 한다.
- Action: `findByUserId` 결과 안에서 `potatoId`를 찾지 못하면 `PotatoRepresentativeException`을 발생시키고 400 응답으로 매핑했다.
- Result: 미획득 또는 존재하지 않는 감자는 대표 감자로 지정되지 않는다.

### 4. 프론트 상태 갱신

- Problem: 대표 감자 변경 후 화면이 서버 상태를 다시 반영해야 한다.
- Analysis: 로컬 목록을 직접 수정하면 서버 응답과 어긋날 수 있으므로, 성공 후 도감 provider를 다시 불러오는 방식이 안전하다.
- Action: 대표 감자 변경 성공 시 `potatoCollectionProvider`를 invalidate하고 성공 스낵바를 표시했다.
- Result: 다음 렌더링에서 서버 기준 대표 감자 상태를 다시 받아오게 되었다.

## 실행한 검증

```bash
cd backend
./gradlew test --tests 'com.gamjamubwatna.potato.*'
```

- 결과: 성공
- 확인 내용: 대표 감자 변경 service/controller 테스트, 기존 감자 도감 조회 테스트 통과

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter test test/features/potato/potato_collection_screen_test.dart
```

- 결과: 성공
- 확인 내용: 도감 화면 렌더링, 상세 bottom sheet, 비로그인 상태, 대표 감자 변경 선택 흐름 통과

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter analyze
```

- 결과: 성공
- 확인 내용: 정적 분석 오류 없음
- 참고: `flutter_secure_storage`의 iOS Swift Package Manager 미지원 경고가 출력되었으나, 기존 플러그인 경고이며 이번 변경 실패 원인은 아니다.

## 성능 테스트 여부

- k6: 실행하지 않음. 이번 작업은 단일 사용자 대표 감자 변경 API이며, 목록 조회나 대량 처리 성능을 바꾸는 작업이 아니다.
- Flutter DevTools/Profiler: 실행하지 않음. 화면 구조를 크게 바꾸지 않고 기존 bottom sheet에 선택 이벤트와 로딩 상태만 추가했다.
- 후속으로 감자 성장/걸음 수 실시간 반영처럼 렌더링 빈도가 높은 기능을 붙일 때 Flutter DevTools Performance 또는 Android Studio Profiler 측정이 필요하다.

## 남은 리스크

- 실제 로그인 세션과 DB가 켜진 상태에서 iOS/Chrome 수동 확인은 아직 별도 수행하지 않았다.
- 상세 시트 안의 `대표 감자로 설정` 버튼은 아직 API 호출과 연결하지 않았다. 현재 대표 변경은 상단 카드의 `대표 감자 변경` 버튼과 picker 흐름 기준이다.

## 후속 작업

- 상세 시트의 `대표 감자로 설정` 버튼도 동일한 API로 연결할지 UX를 결정한다.
- 대표 감자 변경 성공 후 시트 유지/닫힘 정책을 사용자 테스트로 검토한다.
- 대표 감자 변경 이벤트를 마이페이지 프로필 대표 감자 표시와 연결한다.
