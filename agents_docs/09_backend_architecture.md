# 09_backend_architecture.md

# Backend Architecture

## 1. 목표

백엔드는 Spring Boot 3.5.x / Java 21 기반의 단일 Gradle 모듈 Modular Monolith 구조로 개발한다.

도메인 주도 설계, DDD를 모놀리식 구조에 적용하되, 도메인별로 패키지를 격리하여 향후 특정 도메인을 MSA로 분리하기 쉽게 만든다.

---

## 2. 기술 스택

```txt
Java 21
Spring Boot 3.5.x
Spring Security
JWT
Spring Data JPA
QueryDSL
PostgreSQL
PostGIS
Redis
Swagger / Springdoc OpenAPI
Docker
GitHub Actions
AWS S3
```

---

## 3. 아키텍처 원칙

```txt
Modular Monolith
Domain Driven Design
Layered Architecture
Package by Domain
DTO 공유 금지
Entity 직접 노출 금지
Fat Entity 지향
Application Service에서 Transaction 관리
Domain Layer는 순수 Java 중심
Infrastructure Layer가 외부 기술 담당
```

---

## 4. 전체 패키지 구조

```txt
com.gamjamubwatna
 ├─ GamjaApplication.java
 │
 ├─ global
 │   ├─ config
 │   ├─ security
 │   ├─ exception
 │   ├─ response
 │   ├─ common
 │   └─ util
 │
 ├─ user
 ├─ auth
 ├─ spot
 ├─ stamp
 ├─ potato
 ├─ mission
 ├─ coupon
 ├─ reward
 ├─ visit
 ├─ audio
 └─ admin
```

---

## 5. 도메인별 레이어 구조

각 도메인은 다음 구조를 따른다.

```txt
domain-name/
 ├─ api
 │   ├─ DomainController.java
 │   ├─ request
 │   └─ response
 │
 ├─ application
 │   ├─ DomainService.java
 │   └─ command
 │
 ├─ domain
 │   ├─ DomainEntity.java
 │   ├─ vo
 │   ├─ repository
 │   └─ exception
 │
 └─ infrastructure
     ├─ persistence
     ├─ external
     └─ config
```

---

## 6. 각 레이어 역할

## 6.1 API / Interfaces Layer

역할:

- 외부 클라이언트와의 접점
- Controller 관리
- Request / Response DTO 관리
- 인증 사용자 식별
- 응답 포장

포함:

```txt
Controller
Request DTO
Response DTO
```

규칙:

- 비즈니스 로직 금지
- Entity 직접 반환 금지
- DTO는 Java 21 record 사용
- Application Service만 호출

예시:

```java
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/spots")
public class SpotController {

    private final SpotQueryService spotQueryService;

    @GetMapping("/{spotId}")
    public ApiResponse<SpotDetailResponse> getSpot(
            @PathVariable Long spotId
    ) {
        return ApiResponse.success(spotQueryService.getSpot(spotId));
    }
}
```

---

## 6.2 Application Layer

역할:

- Use Case 처리
- 도메인 객체 조합
- 트랜잭션 관리
- 외부 시스템 호출 조율

포함:

```txt
Application Service
Command
Query Service
```

규칙:

- `@Transactional`은 Application Service에 선언한다.
- Repository Interface에 의존한다.
- Infrastructure 구현체에 직접 의존하지 않는다.
- 여러 도메인을 조합하는 로직은 Application Layer에서 처리한다.

예시:

```java
@Service
@RequiredArgsConstructor
public class StampCommandService {

    private final UserRepository userRepository;
    private final TouristSpotRepository touristSpotRepository;
    private final StampRepository stampRepository;
    private final UserStampRepository userStampRepository;
    private final VisitLogRepository visitLogRepository;

    @Transactional
    public StampVerifyResult verify(Long userId, StampVerifyCommand command) {
        User user = userRepository.getById(userId);
        TouristSpot spot = touristSpotRepository.getById(command.touristSpotId());

        spot.validateVisitable(command.latitude(), command.longitude());

        Stamp stamp = stampRepository.getByCityName(spot.getCityName());

        UserStamp userStamp = UserStamp.acquire(user, stamp, spot);
        userStampRepository.save(userStamp);

        visitLogRepository.save(VisitLog.success(user, spot, command.latitude(), command.longitude()));

        return StampVerifyResult.from(userStamp);
    }
}
```

---

## 6.3 Domain Layer

역할:

- 핵심 비즈니스 규칙 관리
- Entity
- Value Object
- Repository Interface
- Domain Exception

포함:

```txt
Entity
Value Object
Enum
Repository Interface
Domain Service
Domain Exception
```

규칙:

- 가장 순수한 Java 코드로 작성한다.
- 외부 기술에 의존하지 않는다.
- Controller DTO를 참조하지 않는다.
- Infrastructure 클래스를 참조하지 않는다.
- 핵심 상태 변경 메서드는 Entity 내부에 둔다.
- Fat Entity를 지향한다.

예시:

```java
@Entity
@Table(name = "tourist_spots")
public class TouristSpot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String cityName;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private Integer verificationRadiusMeter;

    public void validateVisitable(BigDecimal userLat, BigDecimal userLng) {
        double distance = DistanceCalculator.calculate(
            this.latitude,
            this.longitude,
            userLat,
            userLng
        );

        if (distance > verificationRadiusMeter) {
            throw new SpotVisitNotAllowedException();
        }
    }
}
```

---

## 6.4 Infrastructure Layer

역할:

- DB 접근 구현
- 외부 API 연동
- Redis 연동
- S3 연동
- 한국관광공사 OpenAPI 연동
- Kakao API 연동

포함:

```txt
Repository Implementation
JpaRepository
QueryDSL Repository
External API Client
Redis Adapter
S3 Client
```

규칙:

- Domain Layer의 Repository Interface를 구현한다.
- 외부 기술 변경이 Application / Domain에 영향을 주지 않도록 한다.

예시:

```java
@Repository
@RequiredArgsConstructor
public class TouristSpotRepositoryImpl implements TouristSpotRepository {

    private final TouristSpotJpaRepository touristSpotJpaRepository;

    @Override
    public TouristSpot getById(Long id) {
        return touristSpotJpaRepository.findById(id)
            .orElseThrow(TouristSpotNotFoundException::new);
    }
}
```

---

## 7. 도메인 목록

## 7.1 Auth Domain

책임:

- 카카오 로그인
- 애플 로그인
- JWT 발급
- Refresh Token 관리
- 로그아웃

## 7.2 User Domain

책임:

- 사용자 정보 관리
- 마이페이지
- 회원 탈퇴

## 7.3 Spot Domain

책임:

- 관광지 조회
- 주변 관광지 조회
- 관광지 상세
- 혼잡도 조회
- 연관 관광지 추천

## 7.4 Stamp Domain

책임:

- GPS 방문 인증
- 스탬프 지급
- 중복 지급 방지
- 스탬프북 조회
- 보상 조건 확인

## 7.5 Potato Domain

책임:

- 감자 캐릭터 관리
- 감자 도감 조회
- 감자 지급
- 희귀도 계산
- 감자 성장

## 7.6 Mission Domain

책임:

- 주변 미션 조회
- 점순이 미션 표시
- 미션 완료 처리
- 미션 보상 지급

## 7.7 Coupon Domain

책임:

- 쿠폰 발급
- 내 쿠폰 조회
- QR 쿠폰
- 쿠폰 사용 처리

## 7.8 Reward Domain

책임:

- 보상 지급 기록
- 보상 히스토리 조회

## 7.9 Visit Domain

책임:

- 방문 로그 저장
- 위치 인증 이력 저장
- 관광객 이동 데이터 분석 기반 마련

## 7.10 Audio Domain

책임:

- 관광지 오디오 가이드 조회
- 캐릭터 대사형 스크립트 조회

---

## 8. 도메인별 패키지 예시

```txt
stamp/
 ├─ api
 │   ├─ StampController.java
 │   ├─ request
 │   │   └─ StampVerifyRequest.java
 │   └─ response
 │       └─ StampVerifyResponse.java
 │
 ├─ application
 │   ├─ StampCommandService.java
 │   ├─ StampQueryService.java
 │   └─ command
 │       └─ StampVerifyCommand.java
 │
 ├─ domain
 │   ├─ Stamp.java
 │   ├─ UserStamp.java
 │   ├─ StampRewardPolicy.java
 │   ├─ repository
 │   │   ├─ StampRepository.java
 │   │   └─ UserStampRepository.java
 │   └─ exception
 │       ├─ StampAlreadyAcquiredException.java
 │       └─ StampNotFoundException.java
 │
 └─ infrastructure
     └─ persistence
         ├─ StampJpaRepository.java
         ├─ UserStampJpaRepository.java
         └─ StampRepositoryImpl.java
```

---

## 9. 협업 규칙

## 9.1 패키지 격리

각 개발자는 담당 도메인 내부에서 개발한다.

예시:

```txt
개발자 A: auth, user, stamp, coupon
개발자 B: spot, potato, mission, audio
```

## 9.2 DTO 공유 금지

- API Request / Response DTO는 각 도메인의 api 패키지 안에 둔다.
- 다른 도메인의 DTO를 참조하지 않는다.
- 도메인 간 데이터 전달은 Command, Result, Domain Entity, VO를 사용한다.

## 9.3 Entity 직접 노출 금지

Controller에서 Entity를 반환하지 않는다.

금지:

```java
@GetMapping("/{id}")
public TouristSpot getSpot(@PathVariable Long id) {
    return spotService.getSpot(id);
}
```

허용:

```java
@GetMapping("/{id}")
public ApiResponse<SpotDetailResponse> getSpot(@PathVariable Long id) {
    return ApiResponse.success(spotService.getSpot(id));
}
```

## 9.4 Transaction 규칙

- 조회 전용 메서드는 `@Transactional(readOnly = true)`
- 상태 변경 메서드는 `@Transactional`
- Controller에 Transaction 선언 금지
- Domain Entity에 Transaction 선언 금지

---

## 10. 공통 응답 구조

```java
public record ApiResponse<T>(
    boolean success,
    String message,
    T data
) {
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(true, "요청이 성공했습니다.", data);
    }
}
```

---

## 11. 예외 처리

모든 예외는 GlobalExceptionHandler에서 처리한다.

```txt
BusinessException
UnauthorizedException
ForbiddenException
NotFoundException
ValidationException
ExternalApiException
```

응답 예시:

```json
{
  "success": false,
  "message": "이미 획득한 스탬프입니다.",
  "code": "STAMP_ALREADY_ACQUIRED"
}
```

---

## 12. 인증 / 인가

- Spring Security 사용
- JWT 기반 인증
- Access Token / Refresh Token 분리
- Refresh Token은 Redis 저장
- Admin API는 ADMIN 권한 필요

---

## 13. 외부 API 연동

## 13.1 한국관광공사 OpenAPI

사용 목적:

- 관광지 데이터 수집
- 오디오 가이드 정보 수집
- 관광지 집중률 데이터 수집
- 연관 관광지 추천 데이터 수집

위치:

```txt
spot/infrastructure/external
audio/infrastructure/external
```

## 13.2 Kakao API

사용 목적:

- 카카오 로그인
- 카카오 지도 / 길찾기 연동
- 카카오내비 연동

위치:

```txt
auth/infrastructure/external
spot/infrastructure/external
```

---

## 14. 향후 MSA 분리 기준

아래 도메인은 향후 독립 서비스로 분리 가능하게 설계한다.

```txt
spot
recommendation
analytics
mission
coupon
audio
```

특히 관광객 이동 데이터 분석, 희귀도 알고리즘, 추천 알고리즘은 추후 별도 worker 또는 AI 분석 서비스로 분리할 수 있다.

---

## 15. Codex 구현 지시사항

Codex는 다음 원칙을 지켜 구현한다.

1. 도메인별 모듈형 모놀리스 구조로 생성한다.
2. 각 도메인마다 api / application / domain / infrastructure 계층을 만든다.
3. Controller는 DTO만 사용한다.
4. Entity를 직접 반환하지 않는다.
5. Java 21 record를 Request / Response DTO에 사용한다.
6. 비즈니스 규칙은 Domain Entity 또는 Domain Service에 둔다.
7. Transaction은 Application Service에서 관리한다.
8. Repository Interface는 Domain Layer에 둔다.
9. Repository 구현체는 Infrastructure Layer에 둔다.
10. Swagger 문서를 자동 생성한다.
