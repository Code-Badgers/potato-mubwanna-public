# 02_tech_stack

## Frontend

Framework:

- Flutter 3.44.1
- Flutter Web
- Flutter Android
- Flutter iOS

Language:

- Dart 3.12.1

Build Toolchain:

- Android Gradle Plugin 9.0.1
- Gradle 9.1.0
- Kotlin Gradle Plugin 2.3.20
- Android build JDK: Java 17
- iOS CocoaPods

Build Toolchain Notes:

- Flutter 3.44.1 stable로 업그레이드해 Web/iOS 빌드 호환성을 확보한다.
- Flutter 3.44.1의 Android 템플릿은 declarative Gradle plugin 적용 방식이 필요하므로 Android Gradle Plugin 9.0.1, Gradle 9.1.0, Kotlin Gradle Plugin 2.3.20으로 갱신한다.
- Android 빌드는 현재 Java 17로 실행한다. 백엔드의 Java 21 기준과 다르며, 백엔드는 Spring Boot 3.5.x 실행 런타임이고 프론트 Android 빌드 JDK는 Flutter/Android Gradle Plugin 호환성 기준으로 관리한다.
- Android minSdkVersion은 `health` 13.3.1 요구사항에 맞춰 26(Android 8.0)으로 설정한다. Kakao Maps Android SDK v2 요구사항도 함께 충족한다.
- Android는 Firebase 계열 의존성으로 64K method limit을 넘기므로 multidex를 사용한다.
- iOS minimum deployment target은 Firebase 최신 패키지 요구사항 때문에 15.0으로 설정한다.
- Kakao Maps Android SDK 최신 문서 버전은 2.13.2이지만, 현재 Android 에뮬레이터 검증 환경에서는 Kakao Maps 네이티브 라이브러리의 ARM64 의존성 때문에 실제 Android 기기에서 최종 확인한다.

State Management:

- Riverpod

Routing:

- GoRouter

Networking:

- Dio

Map:

- Kakao Map
- Kakao Maps JavaScript SDK for Flutter Web preview
- Kakao Maps Android SDK v2 2.12.11
- KakaoMapsSDK iOS 2.12.12
- Flutter platform view bridge for Android/iOS native map rendering

Push:

- Firebase Cloud Messaging

Storage:

- Flutter Secure Storage

Platform Secret Policy:

- Web Kakao JavaScript key: `KAKAO_JAVASCRIPT_KEY`
- Android/iOS Kakao native app key: `KAKAO_NATIVE_APP_KEY`
- Kakao REST API key: `KAKAO_REST_API_KEY`
- Local secret values are stored in `.env` only and must not be committed.
- Firebase platform files such as `google-services.json`, `GoogleService-Info.plist`, and `firebase_options.dart` must not be committed until sanitized/configured for the target environment.

Reason for Changes:

- The original frontend scope was Flutter app-first, but only the Web platform existed in the repository.
- Android and iOS platform folders were generated to match the mobile app direction in `08_frontend_architecture.md`.
- Kakao Map was reconnected on Web using bounded `HtmlElementView` constraints so the planning/demo screen can still be inspected in a browser.
- Android/iOS map rendering uses native Kakao Maps SDKs through Flutter platform views.
- Web map rendering uses Kakao Maps JavaScript SDK and coordinate-based custom overlays so markers stay fixed to map positions during zoom/pan.

---

## Backend

Framework:

- Spring Boot 3.5.x

Language:

- Java 21

Security:

- Spring Security
- JWT

ORM:

- Spring Data JPA
- QueryDSL

Database:

- PostgreSQL
- PostGIS

Cache:

- Redis

Documentation:

- Swagger OpenAPI

---

## Infrastructure

Docker
AWS EC2
AWS RDS
AWS S3
GitHub Actions
Nginx
