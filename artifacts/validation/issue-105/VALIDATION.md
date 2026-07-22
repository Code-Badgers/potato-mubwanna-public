# Issue #105 검증 기록

## 작업 요약

- 이슈: #105 `[FE] feat(audio): 관광지 상세 오디오 가이드 실데이터 연동`
- 브랜치: `feat/105-audio-guide-ui`
- 담당 영역: 관광지 상세 조회, 오디오 가이드 조회 및 재생 UI
- 제외 범위: 랠리북 다시 듣기, 방문 성공 모달, 백그라운드 재생, 오프라인 저장, Backend/API 계약 변경
- 목표: 기존 관광지 상세 화면의 placeholder를 실제 API 데이터와 오디오 재생 흐름으로 교체한다.

## 변경 내용

- `GET /api/spots/{spotId}` 응답을 관광지 상세 화면에 표시한다.
- `GET /api/audio-guides/spots/{spotId}` 응답을 제목, 음원, 대본, 캐릭터 멘트로 표시한다.
- `just_audio` 기반 재생/일시정지/탐색/재시도 상태를 Riverpod controller로 분리했다.
- 관광지 및 오디오 로딩, 404 미제공, 503/네트워크 오류 상태를 각각 제공한다.
- 모바일 폭과 큰 글자 배율에서 상세 정보와 재생 컨트롤의 레이아웃을 검증했다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: `frontend/lib/core/constants/api_paths.dart`에 기존 API 경로 helper 2개만 추가했다.
- API 계약 변경: 없음. 기존 `GET /api/spots/{spotId}`, `GET /api/audio-guides/spots/{spotId}` 계약을 사용한다.
- DB migration: 없음
- 환경 변수: 없음
- 외부 API: Backend가 반환하는 ODII 음원 URL을 소비한다. Frontend에서 새 외부 API를 직접 호출하지 않는다.

## 검증

```powershell
cd frontend
flutter test --no-pub test\features\audio test\features\spot
```

- 결과: 성공, 12 tests passed
- 범위: 상세/오디오 repository 매핑, 404/503 분기, 재생/탐색/해제, 화면 상태, 1.4배 글자 크기

```powershell
cd frontend
flutter analyze --no-pub
```

- 결과: 성공, `No issues found`

```powershell
cd frontend
flutter test --no-pub
```

- 결과: 성공, 127 tests passed
- 실패했던 시도: 첫 실행은 shell 제한 시간을 실수로 1초로 지정해 테스트 출력 파이프가 중단됐다. 코드 실패가 아니며 제한 시간을 240초로 수정한 재실행에서 전체 테스트가 통과했다.

```powershell
cd frontend
flutter build web --profile --no-pub
```

- 결과: 성공
- 비차단 경고: CupertinoIcons 폰트 미포함, 일부 플러그인의 WebAssembly 호환성 dry-run 경고

### 화면 검증

- URL: `http://127.0.0.1:18405`
- viewport: 430 x 932
- 확인: 상단 상세 정보, 태그, 오디오 재생 카드, 캐릭터 멘트, 대본 스크롤
- 상호작용: 재생 버튼 클릭 후 재생 아이콘이 일시정지 아이콘으로 변경됨
- 결과: 텍스트 겹침/잘림 및 브라우저 콘솔 오류 없음

## 산출물

- `spot_detail_preview.dart`: API 계약과 동일한 fixture를 사용하는 독립 화면 검증 target
- `spot-detail-mobile.png`: 모바일 viewport 화면 캡처
- `VALIDATION.md`: 작업 및 검증 기록

## 남은 리스크

- 실제 인증 Backend와 ODII API key를 연결한 E2E 테스트는 실행하지 않았다.
- 실제 음원 URL의 codec, CORS, 네트워크 지연은 운영과 같은 환경에서 추가 확인이 필요하다.
- iOS/Android 실제 단말의 오디오 출력 및 OS 오디오 포커스 동작은 실행하지 않았다.

## 다음 작업

- 이어서 실행할 명령: `cd frontend && flutter run`
- 확인해야 할 파일: `frontend/lib/features/spot/presentation/screen/spot_detail_screen.dart`, `frontend/lib/features/audio/application/audio_playback_controller.dart`
- 조율이 필요한 사람 또는 이슈: 실서비스 ODII 연동 점검 시 Backend 오디오 가이드 담당자와 API key 및 음원 URL 응답을 함께 확인한다.
