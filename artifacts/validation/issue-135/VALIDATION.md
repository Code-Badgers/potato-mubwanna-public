# Issue #135 검증 기록

## 작업 목표

- 관광지 상세 화면에서 방문 인증 API를 호출한다.
- 방문 인증 성공 시 스탬프/감자 획득 결과를 사용자에게 보여준다.
- #128에서 추가된 `acquiredPotato` 응답을 프론트 모델과 UI에 연결한다.

## PAAR 기록

### 1. 방문 인증 API 계층

- Problem: 프론트에는 `POST /api/visits/verify`를 호출하는 repository와 응답 모델이 없었다. 백엔드 응답의 `acquiredPotato`도 아직 파싱되지 않았다.
- Action: `VisitVerificationRequest`, `VisitVerificationResult`, `VisitAcquiredPotato` 모델과 `VisitVerificationRepository`를 추가했다.
- Analysis: 기존 `SpotDetailRepository`, `MissionRepository`와 같은 `Dio + ApiResponse + ApiException` 패턴을 유지했다. 실패 응답은 백엔드 메시지를 그대로 사용자에게 보여줄 수 있게 했다.
- Result: repository 테스트에서 성공 응답 파싱과 409 중복 인증 오류 메시지 전달을 확인했다.

### 2. 위치 기반 인증 컨트롤러

- Problem: 관광지 상세 화면에서 현재 위치를 가져오고 API 호출 상태를 관리할 컨트롤러가 필요했다.
- Action: `VisitVerificationController`를 추가하고 `LocationService.getCurrentPosition()` 결과로 방문 인증 요청을 만들도록 했다.
- Analysis: 실제 GPS 권한 고도화는 이번 이슈 범위에서 제외했다. 다만 provider로 `LocationService`를 주입해 테스트와 후속 네이티브 권한 개선이 쉽도록 만들었다.
- Result: 위젯 테스트에서 fake 위치 서비스로 좌표가 repository에 전달되는 것을 확인했다.

### 3. 성공 결과 UI

- Problem: 방문 인증 성공 후 사용자가 “무엇을 얻었는지” 알 수 있는 화면이 없었다.
- Action: 관광지 상세 화면 하단에 sticky `방문 인증하기` 버튼을 추가하고, 성공 시 바텀시트로 `인증 성공`, 스탬프 획득 여부, 감자 획득/이미 보유 상태, 희귀도를 표시했다.
- Analysis: UX 문서 기준에 맞춰 다음 액션은 `도감 보기`, `다음 장소 추천` 두 개만 제공했다. 버튼 컬러는 기존 핵심 CTA 컬러 `#56C787`을 유지했다.
- Result: 위젯 테스트에서 성공 바텀시트와 실패 스낵바가 표시되는 것을 확인했다.

## 변경 파일 요약

- `frontend/lib/core/constants/api_paths.dart`
  - `visitVerify` API path 추가
- `frontend/lib/features/spot/domain/visit_verification.dart`
  - 방문 인증 요청/응답 모델 추가
- `frontend/lib/features/spot/data/visit_verification_repository.dart`
  - 방문 인증 API repository 추가
- `frontend/lib/features/spot/application/spot_detail_controller.dart`
  - 방문 인증 repository/controller/location provider 추가
- `frontend/lib/features/spot/presentation/screen/spot_detail_screen.dart`
  - 하단 sticky 방문 인증 CTA와 성공 결과 바텀시트 추가
- `frontend/test/features/spot/*`
  - repository, 성공 UI, 실패 UI 테스트 추가

## 실행한 검증

```bash
cd frontend && flutter test test/features/spot/visit_verification_repository_test.dart
```

- 결과: 성공

```bash
cd frontend && flutter test test/features/spot/spot_detail_screen_test.dart
```

- 결과: 성공

```bash
cd frontend && flutter test test/features/spot
```

- 결과: 성공

```bash
cd frontend && flutter analyze
```

- 결과: 성공

## 화면 검증

- 자동 위젯 테스트로 다음 UI 상태를 검증했다.
  - 관광지 상세 화면에 `방문 인증하기` CTA 노출
  - 인증 성공 바텀시트 노출
  - `황금감자`, `희귀도 영웅`, `도감 보기`, `다음 장소 추천` 표시
  - 중복 인증 실패 메시지 스낵바 표시
- 실제 브라우저/시뮬레이터 캡처는 이번 턴에서 남기지 않았다. 라이브 백엔드와 로그인 토큰, 실제 위치 권한이 함께 필요한 흐름이므로 후속 수동 실행 시 캡처를 추가한다.

## 성능 검증

- 화면 변경 범위가 관광지 상세 단일 화면의 버튼/바텀시트 추가이므로 `flutter analyze`와 관련 위젯 테스트를 우선 적용했다.
- DevTools Performance 또는 Android Studio Profiler는 실제 기기에서 방문 인증 플로우를 실행할 때 측정하는 것이 적절하다.
- 후속 측정 포인트:
  - 관광지 상세 진입 후 첫 렌더링
  - 방문 인증 버튼 클릭 후 위치 조회/API 응답까지의 로딩 상태
  - 성공 바텀시트 렌더링 시 frame drop 여부

## 남은 리스크

- 실제 위치 권한 요청/거부 UX는 아직 상세 화면에 직접 연결하지 않았다.
- Web 환경에서는 브라우저 위치 권한과 HTTPS/localhost 조건에 따라 현재 위치 조회가 실패할 수 있다.
- 방문 인증 성공 후 `다음 장소 추천`은 현재 지도 탭으로 이동만 한다. 추천 동선 자동 포커싱은 후속 이슈가 필요하다.
- 실제 감자 이미지가 들어오면 성공 바텀시트의 아이콘 영역을 이미지로 교체할 수 있다.

## 후속 작업

- 실제 위치 권한 요청/거부 안내 고도화
- 방문 인증 성공 후 추천 동선 자동 표시
- 성공 바텀시트에 감자 이미지 에셋 연결
- 실기기에서 DevTools/Profiler 성능 캡처 추가
