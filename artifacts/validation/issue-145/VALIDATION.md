# Issue #145 Validation

## 작업 목표

방문 인증 성공 응답이 `missionAvailable` 여부만 알려주던 상태에서, 실제 해금된 점순이 미션의 `missionId`, 제목, 타입, 장소, 보상 정보를 함께 내려주도록 확장했다. 프론트는 이 정보를 사용해 방문 인증 결과 바텀시트에서 미션 제목과 보상을 보여주고, 사용자가 한 번의 액션으로 해당 미션 상세 화면에 바로 진입하도록 연결했다.

## PAAR 기록

### Problem

방문 인증 후 “점순이 미션 등장” CTA는 있었지만, 어떤 미션이 열렸는지 알 수 없었다. 프론트는 미션 목록으로 이동한 뒤 안내 배너만 보여줄 수 있었고, 사용자는 실제로 수행해야 하는 미션을 다시 찾아야 했다. 특정 장소 도착으로 미션이 열리는 게임형 UX를 만들려면 방문 인증 응답에 미션 상세 식별자가 필요했다.

### Action

- `agents_docs/07_api_specification.md`에 `unlockedMission` 응답 계약을 먼저 추가했다.
- 백엔드 `POST /api/visits/verify` 응답 DTO에 `UnlockedMissionResponse`를 추가했다.
- 방문 인증 성공 후 관광지 `spotName/cityName`과 연결된 활성 미션을 조회하고, 사용자가 이미 완료한 미션이면 응답하지 않도록 `user_missions`를 확인했다.
- 프론트 `VisitVerificationResult`에 `VisitUnlockedMission` 파싱을 추가했다.
- 방문 인증 성공 바텀시트에 해금 미션 카드와 보상 요약을 표시했다.
- `/main/missions?entry=visit&spotName=...&missionId=...` 라우팅을 추가하고, 미션 화면이 `missionId`를 받으면 해당 상세를 즉시 열도록 연결했다.
- `artifacts/progress/team_work_progress_overview.md`에서 #145 진행 상태를 완료로 갱신했다.

### Analysis

미션 테이블에는 현재 `tourist_spot_id` FK가 없고 `spot_name/city_name` 기준 데이터가 들어 있다. 이번 이슈에서 새 migration으로 FK를 추가하면 기존 seed와 외부 관광지 데이터 정합성까지 함께 손봐야 하므로 범위가 커진다. 그래서 MVP 단계에서는 이름/지역 기준으로 연결하고, 중복 장소가 생길 수 있는 장기 리스크는 후속 데이터 품질 작업으로 남겼다.

또한 기존 클라이언트 호환을 위해 `missionAvailable` 필드는 유지했다. 새 클라이언트는 `unlockedMission`을 우선 사용하고, 값이 없지만 `missionAvailable=true`인 경우에는 기존처럼 일반 미션 진입 CTA를 유지한다.

### Result

- 백엔드 방문 인증 응답에 해금 미션 상세가 포함된다.
- 이미 완료한 미션은 방문 인증 결과에서 다시 해금 미션으로 안내하지 않는다.
- 프론트 방문 인증 결과 바텀시트는 미션 제목과 보상 정보를 보여준다.
- 사용자는 CTA를 누르면 해당 미션 상세 화면으로 바로 이동한다.

## 실행한 검증

```bash
cd backend
./gradlew test --tests com.gamjamubwatna.visit.application.VisitVerificationServiceTest --tests com.gamjamubwatna.visit.api.VisitControllerTest
```

결과: 통과.

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter test test/features/spot/visit_verification_repository_test.dart test/features/spot/spot_detail_screen_test.dart test/features/mission/mission_screen_test.dart
```

결과: 통과.

```bash
cd frontend
/Users/mac/Documents/flutter/bin/flutter analyze
```

결과: 통과. `health`, `flutter_secure_storage`의 iOS Swift Package Manager 미지원 경고는 기존 의존성 경고이며 이번 변경과 직접 관련 없다.

```bash
cd backend
./gradlew test
```

결과: 실패. 전체 271개 중 1개 실패.

- 실패 테스트: `com.gamjamubwatna.spot.application.TourismCongestionSyncServiceTest.syncsPredictionsAndUpdatesNearestFutureCongestionLevel`
- 실패 내용: `expected: LOW but was: HIGH`
- 판단: #145 방문 인증/미션 응답 변경 범위가 아니라 기존 혼잡도 예측 정책 테스트의 기대값 문제로 보인다. 이번 PR에서는 혼잡도 코드를 수정하지 않고 리스크로 기록한다.

## 남은 리스크

- 미션과 스팟 연결이 FK가 아니라 `spotName/cityName` 기반이라 같은 이름의 장소가 늘어나면 오연결 가능성이 있다.
- 실제 GPS 방문 인증 후 iOS/Android에서 미션 상세 진입까지의 전체 실기기 QA가 필요하다.
- 백엔드 전체 테스트 실패 1건은 혼잡도 영역 후속 작업에서 확인해야 한다.

## 후속 작업

- 미션 QR/OCR/사진 인증을 실제 네이티브 입력으로 연결한다.
- 스팟과 미션을 장기적으로 `tourist_spot_id` 또는 명확한 외부 content id 기준으로 연결할지 결정한다.
- 혼잡도 테스트 실패 원인을 별도 이슈에서 정리한다.
