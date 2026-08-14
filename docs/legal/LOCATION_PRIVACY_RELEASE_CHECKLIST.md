# 위치정보·개인정보 출시 체크리스트

이 문서는 `감자무봤나`의 현재 구현과 앱 내 법적 고지를 연결하기 위한 개발 체크리스트다. 법률 자문을 대신하지 않으며, 사업자 정보와 실제 운영정책이 확정되면 위치정보지원센터 또는 전문가에게 최종 검토를 받는다.

## 앱 내 문서와 동의

- 앱 문서 원본: `frontend/lib/features/legal/domain/legal_document_catalog.dart`
- 동의 버전과 로컬 저장: `frontend/lib/features/legal/data/legal_consent_store.dart`
- 최초·개정 시 동의 화면: `/legal-consent`
- 설정에서 재열람·철회:
  - `/legal/service-terms`
  - `/legal/privacy-policy`
  - `/legal/location-terms?manage=true`
  - `/legal/health-data-consent?manage=true`

서비스 이용약관만 필수로 받는다. 개인위치정보와 걸음 정보는 각각 별도 선택 동의이며, 거부해도 위치·걸음 기능 외의 서비스를 이용할 수 있어야 한다. 운영체제 권한은 앱 내 동의와 별개로 요청한다.

## 출시 빌드 입력값

실제 값은 Git에 커밋하지 않고 `frontend/.env`에만 둔다. 출시 빌드는 다음 값이 모두 전달되지 않으면 실패해야 한다.

- `LEGAL_BUSINESS_NAME`
- `LEGAL_REPRESENTATIVE_NAME`
- `LEGAL_BUSINESS_REGISTRATION_NUMBER`
- `LEGAL_BUSINESS_ADDRESS`
- `LEGAL_CONTACT_EMAIL`
- `LEGAL_CONTACT_PHONE`
- `LEGAL_EFFECTIVE_DATE`

빌드 예시:

```powershell
flutter build apk --release --dart-define-from-file=.env
```

## 현재 처리 항목

| 구분 | 처리 항목 | 현재 처리 방식 |
| --- | --- | --- |
| 카카오 로그인 | 카카오 회원번호, 닉네임, 이메일·프로필 이미지(제공된 경우) | 회원 탈퇴 시 사용자 행 삭제 |
| 방문 인증 | 요청 시 GPS 위도·경도 | 서버에서 거리 계산 후 원본 좌표 DB 미저장 |
| 방문 기록 | 관광지, 인증 시각, 계산 거리 | 회원 탈퇴 시까지 저장 |
| 걸음 성장 | 활동 날짜, 걸음 수, 계산 이동거리, 출처, 동기화 시각 | 별도 선택 동의 후 서버 저장 |
| 미션 증빙 | 이용자가 선택한 사진과 파일 정보 | 서버 로컬 저장소와 미션 완료 기록에 저장 |
| 푸시 | FCM 토큰, 플랫폼, 갱신 시각 | 알림 허용 시 등록, 철회·만료·탈퇴 시 삭제 대상 |
| 활동 기록 | 스탬프, 감자, 미션, 쿠폰, 보상, 즐겨찾기 | 회원 탈퇴 시 관련 행 삭제 또는 DB cascade |

## 출시 전 차단 항목

1. 위치정보 이용·제공사실 확인자료를 위치정보를 제외한 형태로 전자적으로 자동 기록하고 최소 6개월 보존해야 한다. 현재 `user_visits`만으로 모든 위치 이용 사실을 충족하는지 확인하고, 부족하면 별도 감사 로그와 파기 작업을 구현한다. 통합 추적: GitHub Issue #311.
2. 회원 탈퇴 시 `user_missions` 행은 삭제되지만 서버 파일시스템의 미션 증빙 사진도 함께 삭제되는지 보장해야 한다. 현재 저장 인터페이스에는 삭제 동작이 없다. 통합 추적: GitHub Issue #311.
3. 걸음 수는 HealthKit·Health Connect에서 읽는 건강 관련 정보이므로 앱 내 별도 동의와 운영체제 권한을 모두 확인하고, 철회 이후 백그라운드 동기화가 중단되는지 실기기에서 확인한다.
4. 만 14세 미만 이용자를 허용할지 정책을 확정한다. 허용한다면 법정대리인 동의와 권리행사 절차를 구현하고, 허용하지 않는다면 가입 단계에서 연령정책을 명확히 적용한다.
5. 원스토어 심사용 개인정보처리방침 URL이 필요하므로 앱과 동일한 내용을 HTTPS 공개 페이지에 게시한다. 앱 내부 화면만으로 스토어의 외부 URL 요구사항을 대신할 수 없다. 통합 추적: GitHub Issue #311.
6. AWS 리전, Firebase 처리 국가·연락처와 실제 위탁계약/설정이 개인정보처리방침의 위탁·국외 이전 문구와 일치하는지 운영 설정으로 확인한다.
7. 접속·오류 로그의 실제 보존기간이 개인정보처리방침에 적은 3개월과 일치하도록 서버 로그 순환·파기 설정을 확인한다.
8. 현재 `origin/main`에서 재현되는 mission·stamp·potato 위젯 테스트 17건을 복구하고 전체 테스트를 다시 실행한다. 통합 추적: GitHub Issue #311.
9. 현재 앱 로컬에만 저장되는 약관·위치·건강정보 동의 상태를 사용자별 문서 버전, 동의·철회 시각과 함께 서버에 보존한다. 앱 삭제·재설치와 다중기기 정책도 확정한다. 통합 추적: GitHub Issue #311.

## 변경 운영

- 필수 문서의 중요한 내용이 바뀌면 `requiredDocumentVersion`을 올려 재동의를 받는다.
- 개인위치정보 이용 범위가 바뀌면 `personalLocationConsentVersion`을 올린다.
- 걸음 정보 항목·목적·보유기간이 바뀌면 `healthDataConsentVersion`을 올린다.
- 상호, 대표자, 주소, 연락처 또는 위치기반서비스 내용이 바뀌면 위치기반서비스사업 변경신고 대상인지 확인한다.
- 문서 변경 전후 버전, 시행일, 공지 내용과 동의 이력을 보존한다.

## 공식 참고자료

- 위치정보법 제19조·제21조의2: https://www.law.go.kr/LSW/lsInfoP.do?lsiSeq=277359
- 위치정보 보호조치 및 사업자 준수사항: https://www.kmcc.go.kr/download.do?fileSeq=62907
- 개인정보 처리방침 작성지침: https://www.pipc.go.kr/np/cop/bbs/selectBoardArticle.do?bbsId=BS074&mCode=C020010000&nttId=12021
- 위치정보지원센터: https://www.lbsc.kr/
