## 작업 요약

- 이슈: #257
- 브랜치: `feat/257-attraction-stamp-impact`
- 담당 영역: Flutter 랠리북 관광지 스탬프와 방문 인증 성공 피드백
- 제외 범위: 화면 재설계, 시군 스탬프 정책/API/DB 변경, QR/OCR, 실물 위치 방문 인증
- 목표: 공식 관광지 29곳에 고유 스탬프 자산을 연결하고 신규 발급 시 도장이 눌리는 피드백 제공

## 변경 파일

- `frontend/assets/stamps/*.png`: 관광지별 한글 스탬프 29개
- `frontend/lib/features/stamp/presentation/widget/attraction_stamp_image.dart`: 관광지명-자산 매핑과 자산 실패 fallback
- `frontend/lib/features/stamp/presentation/screen/stamp_book_screen.dart`: 기존 선택 카드 아이콘 영역에 선택 관광지 스탬프 표시
- `frontend/lib/features/spot/presentation/screen/spot_detail_screen.dart`: 신규 스탬프 발급 시 압인/충격 링 애니메이션과 짧은 햅틱
- `frontend/pubspec.yaml`: `assets/stamps/` 번들 등록
- 관련 테스트: 공식 목록 전수 매핑, 같은 시군 선택 갱신, 성공 시 자산/애니메이션/햅틱 검증

## 공유 파일 / 계약 변경

- 공유 위험 파일: `frontend/pubspec.yaml`에 자산 디렉터리 한 줄 추가
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 없음
- 외부 API: 없음

## 검증

- 실행: 프런트 전체 분석, 관련 테스트 21개, 프런트 전체 테스트 243개, Android API 36 디버그 빌드·설치·기동
- 결과: 분석 오류 없음, 테스트 전체 통과, APK 빌드·설치·기동 성공
- 실행하지 못한 명령: 실제 관광지 반경 내 방문 인증
- 이유: 인증 계정과 현장 위치가 필요한 시나리오

## 산출물

- 검증 기록: `artifacts/validation/issue-257/README.md`
- 화면/API 캡처: `stamp_contact_sheet.png`, `android-app.png`
- 기타: 공통 도장 원본과 자산 생성 스크립트

## 남은 리스크

- 백엔드 발급 단위는 기존과 같이 시군 스탬프입니다. 성공 연출의 이미지는 인증한 `spot.name`으로 선택하며 정책은 바꾸지 않았습니다.
- 등록되지 않은 신규 관광지는 fallback 아이콘이 보이므로, 공식 목록이 늘어나면 매핑과 PNG를 함께 추가해야 합니다.
- Android 빌드의 기존 Kotlin 플러그인 전환 경고는 별도 의존성 정리 이슈 대상입니다.

## 다음 작업

- 이어서 실행할 명령: `flutter test test/features/stamp/attraction_stamp_image_test.dart test/features/stamp/stamp_book_screen_test.dart test/features/spot/spot_detail_screen_test.dart`
- 확인해야 할 파일: `attraction_stamp_image.dart`, `spot_detail_screen.dart`, `stamp_book_screen.dart`
- 조율이 필요한 사람 또는 이슈: PR #209와 파일 중복 없음. 병합 전 새 PR의 CI만 확인
