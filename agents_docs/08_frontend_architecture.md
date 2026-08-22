# 08_frontend_architecture.md

# Frontend Architecture

## 1. 목표

감자무봤나 앱은 Flutter 기반의 iOS / Android 크로스플랫폼 앱으로 개발한다.

핵심 기능은 다음과 같다.

- 카카오맵 기반 감자 지도
- GPS 방문 인증
- 디지털 스탬프 랠리
- 대표 감자 / 감자 성장 / 감자 도감
- 점순이 미션
- 마이페이지 / 보상함

---

## 2. 기술 스택

```txt
Flutter
Dart
Riverpod
GoRouter
Dio
Freezed
Json Serializable
Kakao Map
Kakao Flutter SDK
Geolocator
Permission Handler
Flutter Secure Storage
Shared Preferences
Firebase Cloud Messaging
Cached Network Image
QR Flutter
Mobile Scanner
Just Audio
```

---

## 3. 프로젝트 구조

```txt
lib/
 ├─ main.dart
 ├─ app/
 │   ├─ app.dart
 │   ├─ router/
 │   │   └─ app_router.dart
 │   └─ theme/
 │       ├─ app_colors.dart
 │       ├─ app_text_styles.dart
 │       └─ app_theme.dart
 │
 ├─ core/
 │   ├─ constants/
 │   ├─ network/
 │   │   ├─ dio_client.dart
 │   │   ├─ api_response.dart
 │   │   ├─ api_exception.dart
 │   │   └─ auth_interceptor.dart
 │   ├─ storage/
 │   │   └─ token_storage.dart
 │   ├─ location/
 │   │   └─ location_service.dart
 │   ├─ permissions/
 │   │   └─ permission_service.dart
 │   └─ utils/
 │
 ├─ features/
 │   ├─ auth/
 │   ├─ map/
 │   ├─ spot/
 │   ├─ stamp/
 │   ├─ potato/
 │   ├─ mission/
 │   ├─ coupon/
 │   └─ mypage/
 │
 └─ shared/
     ├─ widgets/
     ├─ models/
     └─ extensions/
```

---

## 4. Feature 구조

각 feature는 다음 구조를 따른다.

```txt
feature/
 ├─ data/
 │   ├─ datasource/
 │   ├─ dto/
 │   └─ repository_impl/
 │
 ├─ domain/
 │   ├─ entity/
 │   ├─ repository/
 │   └─ usecase/
 │
 └─ presentation/
     ├─ screen/
     ├─ widget/
     └─ provider/
```

---

## 5. 라우팅 구조

```txt
/onboarding
/login
/main
/main/map
/main/stamps
/main/potatoes
/main/missions
/main/mypage
/spots/:spotId
/potatoes/:potatoId
/missions/:missionId
/coupons/:couponId
```

---

## 6. 주요 화면

## 6.1 OnboardingScreen

역할:

- 서비스 소개
- 위치 권한 안내
- 푸시 권한 안내
- 로그인 화면 이동

## 6.2 LoginScreen

역할:

- 카카오 로그인
- 애플 로그인
- JWT 저장
- 로그인 실패 처리

## 6.3 MainScreen

역할:

- BottomNavigationBar 제공
- 지도 / 랠리북 / 감자 / 미션 / 마이 탭 관리

## 6.4 MapScreen

역할:

- 카카오맵 표시
- 현재 위치 표시
- 감자 스팟 마커 표시
- 카테고리 필터
- 주변 관광지 조회
- 미션 팝업 표시

## 6.5 SpotDetailScreen

역할:

- 관광지 상세 정보 표시
- 혼잡도 표시
- 방문 인증 버튼
- 오디오 가이드 재생
- 다음 목적지 추천

## 6.6 StampBookScreen

역할:

- 29개 관광지 패스포트 스탬프 현황 표시
- 스탬프 수집률 표시
- 보상 수령 가능 여부 표시

## 6.7 PotatoCollectionScreen

역할:

- 감자 캐릭터 도감 표시
- 대표 감자 표시
- 오늘의 감자걸음 표시
- 감자 성장 상태 표시
- 획득 / 미획득 감자 구분
- 희귀도 표시
- 성장 단계 표시

## 6.8 MissionScreen

역할:

- 점순이 미션 표시
- 일일 미션 표시
- 주간 미션 표시
- 이벤트 미션 표시
- 미션 보상 표시

## 6.9 MyPageScreen

역할:

- 내 정보 표시
- 보상함 표시
- 보유 쿠폰 목록 표시
- QR 코드 표시
- 여행 기록 표시
- 위치 권한 설정
- 알림 설정
- 로그아웃
- 회원 탈퇴

---

## 7. 상태관리 규칙

Riverpod을 사용한다.

주요 Provider:

```txt
authProvider
locationProvider
spotProvider
stampProvider
potatoProvider
missionProvider
couponProvider
mypageProvider
```

규칙:

- 화면에서는 Provider만 참조한다.
- API 호출은 Repository를 통해서만 수행한다.
- DTO를 화면에서 직접 사용하지 않는다.
- 화면에서는 Entity 또는 ViewModel만 사용한다.

---

## 8. 네트워크 규칙

- Dio 사용
- 모든 API 응답은 ApiResponse로 감싼다.
- Access Token은 AuthInterceptor에서 자동 첨부한다.
- 401 응답 발생 시 Refresh Token으로 재발급한다.
- 재발급 실패 시 로그인 화면으로 이동한다.
- API 에러는 공통 Exception으로 변환한다.

---

## 9. 지도 구현 규칙

- 지도는 Kakao Map을 사용한다.
- 관광지 마커는 감자 아이콘을 사용한다.
- 마커 클릭 시 SpotDetailScreen으로 이동한다.
- 현재 위치는 별도 마커로 표시한다.
- 카테고리 필터 변경 시 관광지 목록을 다시 조회한다.
- GPS 방문 인증은 클라이언트에서 1차 확인하고 서버에서 최종 검증한다.

---

## 10. 위치 권한 규칙

- 최초 실행 시 위치 권한 안내를 표시한다.
- 방문 인증 기능 사용 시 위치 권한이 필수다.
- 권한 거부 시 설정 화면 이동 버튼을 제공한다.
- 위치 정보는 서버 인증 요청 시에만 전송한다.

---

## 11. 푸시 알림 규칙

- Firebase client 설정이 모두 있는 Android/iOS에서만 FCM을 초기화한다.
- Web과 설정이 없는 로컬 환경에서는 push client를 비활성화하고 앱 시작은 계속한다.
- FCM 자동 초기화는 기본적으로 끈다. 알림 권한이 `authorized` 또는 `provisional`일 때만 활성화한다.
- 로그인과 세션 갱신 후 현재 token을 서버에 등록하고, `onTokenRefresh`를 통해 변경된 token과 이전 token을 함께 동기화한다.
- 로그아웃, 회원 탈퇴, 알림 권한 철회 시 서버 token 삭제, Firebase token 삭제, 자동 초기화 해제를 수행한다.
- foreground 알림은 앱 내 알림으로 표시한다.
- background/terminated 알림 탭은 `MISSIONS`, `COUPONS`, `STAMPS`, `MAP`, `SPOT` whitelist만 라우팅한다.
- 전체 registration token은 로그나 오류 메시지에 남기지 않는다.
- Firebase 콘솔, APNs, 서버 자격 증명과 실제 기기 검증 절차는 `FCM_SETUP_GUIDE.md`를 따른다.

---

## 12. 앱 배포 구조

## Android

```bash
flutter build appbundle --release
```

결과물:

```txt
build/app/outputs/bundle/release/app-release.aab
```

Google Play Console에 `.aab` 파일을 업로드한다.

## iOS

```bash
flutter build ipa --release
```

결과물:

```txt
build/ios/ipa/*.ipa
```

Xcode 또는 Transporter를 통해 App Store Connect에 업로드한다.

---

## 13. 최소 배포 전략

가장 빠른 출시 순서:

```txt
1. Android Play Store 내부 테스트
2. Android Play Store 공개 출시
3. iOS TestFlight
4. iOS App Store 공개 출시
```

MVP에서는 Android 먼저 출시하고, 이후 iOS를 출시한다.
