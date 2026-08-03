# Issue #229 validation

## 작업 요약

- 이슈: #229 `[FE/BE] feat: Odii 오디오 가이드 실데이터 재생 연결`
- 브랜치: `feat/229-odii-audio-live-integration`
- 담당 영역: Odii 외부 API 호출, 빈 검색 결과 처리, Android 오디오 재생 검증
- 제외 범위: Team B 화면 UI 정리, 지도 핀/카드 이슈, 실기기 QA, 관광 데이터 품질 보정
- 목표: 디코딩 인증키로 Odii 실데이터를 조회하고 앱에서 음원을 재생한다.

## 변경 파일

- `backend/src/main/java/com/gamjamubwatna/audio/infrastructure/external/OdiiApiClient.java`: 디코딩 인증키의 예약 문자를 안전하게 인코딩하고, Odii의 빈 검색 결과 형식(`items: ""`)을 빈 목록으로 처리한다.
- `backend/src/test/java/com/gamjamubwatna/audio/infrastructure/external/OdiiApiClientTest.java`: 디코딩 키와 빈 검색 결과 회귀 테스트를 추가한다.
- `artifacts/validation/issue-229/android-odii-playback.png`: Android 에뮬레이터 실제 재생 화면을 기록한다.

## 공유 파일 / 계약 변경

- 공유 위험 파일: 없음
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 기존 `ODII_API_SERVICE_KEY` 사용, 새 변수 없음
- 외부 API: 한국관광공사 Odii `storySearchList`

## 검증

- 실행: `gradlew.bat test --tests "com.gamjamubwatna.audio.infrastructure.external.OdiiApiClientTest" --tests "com.gamjamubwatna.audio.application.AudioGuideServiceTest" --tests "com.gamjamubwatna.audio.api.AudioGuideControllerTest" --tests "com.gamjamubwatna.audio.AudioGuideFlowIntegrationTest"`
- 결과: 성공
- 실행: `gradlew.bat test --tests "com.gamjamubwatna.audio.*"`
- 결과: 오디오 API, 서비스, 외부 클라이언트, 통합 흐름, DB migration 테스트 전체 성공
- 실행: `flutter test test/features/audio test/features/spot/spot_detail_repository_test.dart test/features/spot/spot_detail_screen_test.dart`
- 결과: 18개 테스트 전체 성공
- 실행: `flutter analyze`
- 결과: 이슈 없음
- 실행: 로컬 백엔드 `GET /api/audio-guides/spots/2`
- 결과: 남이섬 실데이터와 HTTPS 음원 URL 조회 성공, DB 저장 후 재조회 약 37ms
- 실행: 로컬 백엔드 `GET /api/audio-guides/spots/3`
- 결과: Odii 빈 검색 결과를 404 `이 관광지의 오디오 가이드를 찾을 수 없습니다.`로 반환
- 실행: Android 에뮬레이터에서 `관광 > 남이섬 > 상세보기 > 재생`
- 결과: 실음원 재생, 재생 위치 `01:17 / 02:01`, 일시정지 상태 전환 확인
- 실패했던 시도: 수정 전 빈 검색 결과는 Jackson 역직렬화 실패로 503을 반환했다. `items: ""` 대응 후 404로 수정됐다.

## 산출물

- 검증 기록: 이 문서
- 화면/API 캡처: `artifacts/validation/issue-229/android-odii-playback.png`
- 기타: 로컬 DB `audio_guides`에 남이섬 캐시 1건 생성 확인

## 남은 리스크

- x86 Android 에뮬레이터는 Kakao Map SDK를 표시하지 못하므로 카카오 지도 자체는 이번 검증 범위가 아니다.
- Odii에 정확히 일치하는 해설이 없는 관광지는 404가 정상 동작이다.

## 다음 작업

- 이어서 실행할 명령: 최신 `origin/main` 동기화 후 PR CI 확인
- 확인해야 할 파일: `OdiiApiClient.java`, `OdiiApiClientTest.java`
- 조율이 필요한 사람 또는 이슈: PR 준비 완료 후 사용자에게 머지 요청
