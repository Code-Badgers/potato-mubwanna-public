# 걸음 미션 상세 정보 표시 수정

## 작업 요약

- 이슈: #574 https://github.com/Code-Badgers/potato-mubwanna/issues/574
- 브랜치: `fix/574-mission-step-detail`
- 담당 영역: Flutter 미션 상세 화면과 위젯 테스트
- 제외 범위: 백엔드 API, 미션 데이터, 앱스토어 배포
- 목표: 선택한 3,000걸음/5,000걸음 미션의 제목과 현재·목표 걸음 수를 상세 화면에 정확히 표시

## 변경 파일

- `frontend/lib/features/mission/presentation/screen/mission_screen.dart`: 걸음 미션의 API 제목을 유지하고 현재/목표 걸음 수 행을 추가
- `frontend/test/features/mission/mission_screen_test.dart`: 3,000걸음과 5,000걸음 상세 표시 회귀 테스트 추가

## 공유 파일 / 계약 변경

- 공유 위험 파일: 없음
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: 없음
- 외부 API: 없음

## 검증

- 실행: `flutter test test/features/mission/mission_screen_test.dart`
- 결과: 26개 테스트 통과. 3,000걸음과 5,000걸음 각각 선택한 제목, 현재 31걸음, 목표 걸음 수 표시 및 잘못된 `강원 여행길 방문하기` 문구 미표시 확인
- 실행: `flutter analyze`
- 결과: 문제 없음
- 실행: `git diff --check`
- 결과: 공백 오류 없음
- 실행하지 못한 명령: 수정 APK 실기기 설치 검증
- 이유: 단말에는 원스토어 공개판이 설치되어 있으며 로컬 디버그 APK는 서명이 달라 기존 앱을 삭제해야 한다. 공개판의 로그인·데이터 상태를 보존하기 위해 설치하지 않음

## 산출물

- 검증 기록: `artifacts/validation/issue-574/VALIDATION.md`
- 화면/API 캡처: 없음. 위젯 테스트로 두 목표값의 상세 렌더링을 검증
- 기타: 없음

## 남은 리스크

- 원스토어 공개판에는 아직 이 수정이 포함되지 않는다. 병합 및 다음 앱 배포 후 실기기에서 최종 확인이 필요하다.

## 다음 작업

- 이어서 실행할 명령: 병합 및 배포 후 원스토어판을 업데이트하고 3,000걸음/5,000걸음 상세 화면을 각각 확인
- 확인해야 할 파일: `frontend/lib/features/mission/presentation/screen/mission_screen.dart`
- 조율이 필요한 사람 또는 이슈: 앱 배포 담당자, #574
