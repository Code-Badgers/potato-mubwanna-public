# 감자무봤나 모바일 UX/UI 제작 가이드

> 목적: Codex가 Flutter 기반 모바일 앱 UI를 일관성 있게 구현할 수 있도록 화면 구조, 사용자 플로우, 디자인 시스템, 컴포넌트 규칙을 정의한다.

---

## 1. 프로젝트 개요

**서비스명:** 감자무봤나

**서비스 한 줄 설명:**
강원특별자치도 18개 시·군 관광지를 스탬프 투어로 연결한 위치 기반 참여형 로컬 관광 서비스

**핵심 컨셉:**
사용자는 강원도 관광지를 방문하며 디지털 스탬프를 수집하고, 지역별 감자 캐릭터를 획득하며, 점순이 미션과 보상을 통해 여행을 게임처럼 즐긴다.

**UX 목표:**
아래 5개 루프를 최대한 짧고 직관적으로 만든다.

1. 지도 탐색
2. 스탬프 수집
3. 감자 캐릭터 수집
4. 점순이 미션
5. 보상 획득

---

## 2. UX 설계 원칙

### 2.1 핵심 원칙

- 앱 실행 후 사용자가 빠르게 **현재 위치 주변 감자 스팟**을 발견할 수 있어야 한다.
- 방문 인증, 스탬프 획득, 감자 획득, 보상 확인까지의 흐름은 3단계 이내로 설계한다.
- 지도는 탐색 중심, 랠리북은 업적 중심, 감자는 성장/컬렉션 중심, 미션은 수행 중심, 마이는 프로필/보상함 중심으로 역할을 분리한다.
- 모든 주요 액션 버튼은 하단에 고정하거나 엄지 손가락이 닿기 쉬운 영역에 배치한다.
- 서비스 톤은 관광 앱보다 **게임형 수집 앱**에 가깝게 설계한다.

### 2.2 UX 키워드

- Pokémon GO 스타일 지도 탐색
- 카카오맵 기반 위치 탐색
- 디지털 스탬프 랠리
- 감자 캐릭터 컬렉션
- 점순이 미션 팝업
- 쿠폰·QR 보상
- SNS 공유 카드

---

## 3. 앱 정보 구조

Bottom Navigation은 `03_information_architecture.md`의 footer와 동일하게 유지한다.

```txt
[지도] [랠리북] [감자] [미션] [마이]
```

### 3.1 탭 역할

| 탭 | 역할 | 핵심 기능 |
|---|---|---|
| 지도 | 탐색과 방문 인증의 시작점 | 카카오맵, 감자 마커, 카테고리 필터, 관광지 상세, 방문 인증 |
| 랠리북 | 스탬프 수집 현황 | 18개 시·군 스탬프, 수집률, 다음 보상 |
| 감자 | 감자 성장과 캐릭터 컬렉션 | 대표 감자, 오늘의 감자걸음, 성장 상태, 감자 도감 |
| 미션 | 점순이 미션 수행 | 지역/관광지/음식/체험 미션, 일일/주간/이벤트 미션 |
| 마이 | 사용자 정보와 보상함 | 프로필, 누적 스탬프, 보상함, 여행 기록, 권한 설정 |

---

## 4. 디자인 시스템

### 4.1 전체 톤앤매너

- 따뜻하고 귀여운 로컬 관광 감성
- 감자 캐릭터 중심의 게임형 UI
- 카드형 레이아웃과 둥근 모서리 사용
- 지도 화면은 실용적으로, 수집 화면은 감성적으로 표현

### 4.2 컬러 팔레트

```txt
Brand Colors
Logo Green         #4E9B46
Potato Yellow      #F5D84E
Mission Orange     #E98A2A
Potato Brown       #7A4A24
Warm Cream         #F3E8D3
Lavender Purple    #CFC1E8
Map Colors

지도 경험의 핵심 컬러는 감자무봤나 브랜드 컬러가 아닌 지도 핀 컬러를 사용한다.

Primary Map Green  #56C787
Dark Map Green     #509B64
Light Map Green    #71BD86

Map Grass          #CDD98F
Map Water          #A1CDD2
Neutral Colors
Text Primary       #222222
Text Secondary     #666666
Line Gray          #E8E2D8
Background         #FFFDF7
Rarity Colors
Normal             #4E9B46
Rare               #CFC1E8
Epic               #E98A2A
Legend             #F6C23E
```

### 4.3 폰트 규칙

```txt
Title        24 / Bold
Heading      20 / Bold
Section      18 / SemiBold
Body         14 / Regular
Caption      12 / Regular
Button       15 / SemiBold
```

### 4.4 카드 스타일

```txt
border-radius: 20px
background: #FFFFFF
border: 1px solid #E8E2D8
shadow: soft, low elevation
padding: 16px
```

### 4.5 버튼 스타일

```txt
Primary CTA

앱 전체의 주요 행동 버튼은 최신 권한/방문 CTA 컬러를 사용한다.

Background      #56C787
Pressed         #509B64
Disabled        #BFE5CC

Text            #FFFFFF
Font Weight     600

Height          56px
Radius          16px

Shadow
0 4px 12px rgba(86,199,135,0.25)

사용 예시

방문 인증하기
길찾기
미션 시작
스탬프 획득
보상 받기
다음 장소 추천
Secondary Button
Background      #FFFFFF
Border          #56C787
Text            #56C787

Height          52px
Radius          16px
Reward Button
Background      #F5D84E
Text            #3A260E

Height          52px
Radius          16px
```

---

## 5. 핵심 사용자 플로우

### 5.1 지도 탐색 루프

```txt
지도 진입
→ 현재 위치 확인
→ 감자 마커 탐색
→ 마커 선택
→ Bottom Sheet 확인
→ 상세보기 또는 길찾기
```

### 5.2 스탬프 수집 루프

```txt
관광지 상세
→ 방문 인증하기
→ GPS 인증
→ 스탬프 획득
→ 랠리북 업데이트
→ 다음 장소 추천
```

### 5.3 감자 캐릭터 수집 루프

```txt
방문 인증 성공
→ 감자 획득 조건 확인
→ 감자 캐릭터 지급
→ 감자 탭의 도감 업데이트
→ 감자 상세 확인
```

### 5.4 점순이 미션 루프

```txt
미션 장소 접근
→ 점순이 팝업 등장
→ 도전하기
→ 미션 수행
→ 보상 획득
```

### 5.5 보상 획득 루프

```txt
스탬프 조건 달성
→ 보상 알림
→ 마이 탭의 보상함 이동
→ 쿠폰 확인
→ QR 보기
```

---

## 6. 화면 설계

## 6.1 온보딩

### Screen 01: 서비스 소개

```txt
┌─────────────────────┐
│ 🥔 감자무봤나       │
│                     │
│ 강원도 감자여행     │
│ 스탬프를 모아보세요 │
│                     │
│ [다음]              │
└─────────────────────┘
```

**UI 요구사항**

- 감자 캐릭터를 중앙에 크게 배치한다.
- 배경은 강원도 산과 들판 일러스트를 사용한다.
- CTA는 하단 고정 버튼으로 배치한다.

### Screen 02: 위치 권한 안내

```txt
┌─────────────────────┐
│ 📍 위치권한 필요     │
│                     │
│ 관광지 방문 인증을  │
│ 위해 위치정보 사용  │
│                     │
│ [권한 허용하기]     │
│ 나중에 하기         │
└─────────────────────┘
```

**UI 요구사항**

- 위치 권한 안내 일러스트는 `frontend/assets/onboading_02.png`를 사용한다.
- 위치 권한이 왜 필요한지 명확하게 설명한다.
- 방문 인증, 주변 감자 찾기, 점순이 미션에 위치 권한이 사용됨을 안내한다.

### Screen 03: 알림 설정

```txt
┌─────────────────────┐
│ 🔔 알림 설정        │
│                     │
│ 점순이 미션 알림    │
│ 쿠폰 지급 알림      │
│                     │
│ [허용]              │
└─────────────────────┘
```

### Screen 04: 로그인

```txt
┌─────────────────────┐
│ 로그인              │
│                     │
│ [카카오 로그인]     │
└─────────────────────┘
```

**UI 요구사항**

- 카카오 로그인 버튼을 가장 강조한다.
- 애플 로그인은 선택 옵션으로 둘 수 있다.

---

## 6.2 지도 탭

### Main Map Screen

```txt
┌─────────────────────┐
│ 🔍 감자 찾기        │
├─────────────────────┤
│                     │
│     카카오맵        │
│                     │
│     🥔 🥔 🥔       │
│         📍          │
│                     │
│  🥔      ⭐         │
│                     │
├─────────────────────┤
│ 관광 │카페│체험│맛집│
└─────────────────────┘
```

**UI 요구사항**

- 카카오맵을 전체 화면 중심으로 표시한다.
- 감자 아이콘이 관광지 마커 역할을 한다.
- 희귀 감자 출현 가능 장소는 별 아이콘 또는 골드 감자 마커로 강조한다.
- 상단에는 검색/지역 선택 영역을 둔다.
- 하단에는 카테고리 필터 칩을 배치한다.

### Marker Bottom Sheet

```txt
┌─────────────────────┐
│ 정선 5일장          │
│ ⭐ 희귀 감자 출현   │
│                     │
│ 혼잡도 : 여유       │
│                     │
│ [길찾기]            │
│ [상세보기]          │
└─────────────────────┘
```

**UI 요구사항**

- 마커 선택 시 Bottom Sheet가 열린다.
- 장소명, 희귀 감자 출현 여부, 혼잡도, CTA를 한눈에 보여준다.
- CTA 우선순위는 `상세보기 > 길찾기`이다.

---

## 6.3 관광지 상세

### Spot Detail Screen

```txt
┌─────────────────────┐
│ ← 정선 5일장       │
├─────────────────────┤
│ [대표 이미지]       │
│                     │
│ 정선 대표 전통시장  │
│                     │
│ 🟢 혼잡도 낮음      │
│ 🎧 점순이 오디오    │
│                     │
│ ─────────────────   │
│ 🎁 획득 가능        │
│ 정선 곤드레감자     │
│ ⭐ 희귀도 : Rare    │
│ ─────────────────   │
│ [방문 인증하기]     │
└─────────────────────┘
```

**UI 요구사항**

- 대표 이미지, 설명, 혼잡도, 오디오 가이드, 획득 가능 감자를 순서대로 배치한다.
- `방문 인증하기` 버튼은 하단 sticky CTA로 고정한다.
- 인증 가능 거리 밖이면 버튼을 비활성화하고 `100m 이내에서 인증 가능` 문구를 표시한다.

### Visit Verification Success Modal

```txt
┌─────────────────────┐
│ 🎉 인증 성공        │
│                     │
│ 정선 스탬프 획득    │
│                     │
│ + 곤드레감자 획득   │
│                     │
│ [도감 보기]         │
│ [다음 장소 추천]    │
└─────────────────────┘
```

**UI 요구사항**

- 성공 애니메이션 또는 스탬프 찍힘 효과를 사용한다.
- 감자 획득 시 감자 카드가 등장하는 연출을 넣는다.
- 다음 행동은 `도감 보기`와 `다음 장소 추천` 두 개만 제공한다.

---

## 6.4 랠리북 탭

### Stamp Rally Book Screen

```txt
┌─────────────────────┐
│ 🏆 랠리북           │
│                     │
│ 수집률 8 / 18       │
│ ███████░░░          │
│                     │
├─────────────────────┤
│ 강릉  ✔             │
│ 정선  ✔             │
│ 평창  ✔             │
│ 춘천  ○             │
│ 속초  ○             │
├─────────────────────┤
│ 🎁 다음 보상        │
│ 10개 달성 시        │
│ 지역쿠폰 지급       │
└─────────────────────┘
```

**UI 요구사항**

- 게임 업적 화면처럼 설계한다.
- 18개 시·군 스탬프를 그리드 또는 카드 리스트로 보여준다.
- 수집률은 상단에 가장 크게 표시한다.
- 다음 보상 조건을 항상 노출한다.

---

## 6.5 감자 탭

### Potato Screen

```txt
┌─────────────────────┐
│ 🥔 감자             │
├─────────────────────┤
│ 대표 감자           │
│ 오늘의 감자걸음     │
│ 성장까지 1.8km      │
├─────────────────────┤
│ [🥔] [🥔] [❓]      │
│ 하지감자 곤드레감자 평화감자 │
│                     │
│ [🥔] [❓] [❓]      │
│ 자주감자 미획득 미획득 │
└─────────────────────┘
```

**UI 요구사항**

- 감자 캐릭터는 카드 컬렉션 형태로 보여준다.
- 미획득 감자는 실루엣 처리한다.
- 희귀도 필터를 제공한다.

### Potato Detail Screen

```txt
┌─────────────────────┐
│ 곤드레감자          │
├─────────────────────┤
│        🥔           │
│ 희귀도 : Rare       │
│ 지역 : 정선군       │
│ 성장 Lv.3           │
│ 이동거리 4.2km      │
│ [성장시키기]        │
└─────────────────────┘
```

**UI 요구사항**

- 캐릭터 이미지를 중앙에 크게 배치한다.
- 희귀도, 지역, 성장 레벨, 이동거리를 카드 형태로 표시한다.
- 성장 가능 조건을 명확하게 보여준다.

---

## 6.6 미션 탭

### Mission Popup

```txt
┌─────────────────────┐
│ 🌸 점순이 등장!     │
│                     │
│ "여기까지 왔네?"    │
│                     │
│ 미션                │
│ 시장 입구 찾기      │
│                     │
│ 보상                │
│ 황금감자 x1         │
│                     │
│ [도전하기]          │
└─────────────────────┘
```

**UI 요구사항**

- 관광지 접근 시 자동 팝업으로 등장한다.
- 점순이 캐릭터와 말풍선을 사용한다.
- 닫기 버튼은 제공하되, 도전하기 버튼을 더 강조한다.

### Mission Detail Screen

```txt
┌─────────────────────┐
│ 점순이 미션         │
├─────────────────────┤
│ 미션명              │
│ 시장 입구 찾기      │
│                     │
│ 수행 방법           │
│ 지정 장소에서 인증  │
│                     │
│ 보상                │
│ 100P + 황금감자     │
│                     │
│ [미션 시작]         │
└─────────────────────┘
```

---

## 6.7 마이 탭 > 보상함

### Reward Box Screen

```txt
┌─────────────────────┐
│ 🎁 보상함           │
├─────────────────────┤
│ [사용가능]          │
│                     │
│ 강원상품권          │
│ 5,000원             │
│ [QR 보기]           │
│                     │
│ ─────────────────   │
│ 감자전 할인쿠폰     │
│ [QR 보기]           │
└─────────────────────┘
```

**UI 요구사항**

- 사용 가능한 쿠폰을 우선 노출한다.
- QR 보기 버튼을 명확하게 배치한다.
- 사용 완료 쿠폰은 별도 탭 또는 히스토리 영역에 표시한다.

---

## 6.8 마이 탭

### My Page Screen

```txt
┌─────────────────────┐
│ 👤 감자러버         │
├─────────────────────┤
│ 스탬프 8 / 18       │
│ 감자 5 / 24         │
│ 쿠폰 2              │
├─────────────────────┤
│ 여행 기록           │
│ 위치 권한 설정      │
│ 알림 설정           │
│ 이용 약관           │
│ 로그아웃            │
└─────────────────────┘
```

---

## 7. 추가 UX 개선안

### 7.1 홈 대시보드 추가

지도 탭 진입 시 지도 바로 진입 대신 상단에 미니 홈 대시보드를 추가한다.

```txt
오늘의 감자
오늘의 미션
내 수집률
추천 여행코스
```

지도 탐색을 방해하지 않도록 접을 수 있는 카드 형태로 제공한다.

### 7.2 감자 희귀도 카드 UI

감자 도감에는 4단계 희귀도를 명확하게 표현한다.

```txt
일반 Normal
희귀 Rare
황금 Gold
전설 Legend
```

희귀도별 카드 테두리, 뱃지, 배경 효과를 다르게 적용한다.

### 7.3 SNS 공유 카드

스탬프 또는 감자 획득 시 공유 가능한 이미지를 자동 생성한다.

```txt
정선 곤드레감자 획득!
수집률 55%
감자무봤나에서 강원도 감자여행 중
```

**UI 요구사항**

- 공유 카드는 1:1 정사각형 비율로 생성한다.
- 캐릭터, 지역명, 획득일, 수집률을 포함한다.
- 인스타그램 스토리 공유를 고려해 9:16 버전도 확장 가능하게 설계한다.

---

## 8. 컴포넌트 정의

### 8.1 공통 컴포넌트

```txt
AppHeader
BottomNavigation
PrimaryButton
SecondaryButton
RewardButton
PotatoMarker
CategoryFilterChip
SpotBottomSheet
StampCard
PotatoCard
RewardCouponCard
MissionPopup
ProgressBar
RarityBadge
CongestionBadge
```

### 8.2 RarityBadge

```txt
NORMAL  = 일반 / Brown
RARE    = 희귀 / Purple
GOLD    = 황금 / Gold
LEGEND  = 전설 / Gradient Gold
```

### 8.3 CongestionBadge

```txt
LOW     = 여유 / Green
NORMAL  = 보통 / Orange
HIGH    = 혼잡 / Red
```

---

## 9. Flutter 구현 기준

### 9.1 라우팅

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

### 9.2 화면 파일 예시

```txt
lib/features/onboarding/presentation/screen/onboarding_screen.dart
lib/features/auth/presentation/screen/login_screen.dart
lib/features/map/presentation/screen/map_screen.dart
lib/features/spot/presentation/screen/spot_detail_screen.dart
lib/features/stamp/presentation/screen/stamp_book_screen.dart
lib/features/potato/presentation/screen/potato_collection_screen.dart
lib/features/potato/presentation/screen/potato_detail_screen.dart
lib/features/mission/presentation/screen/mission_screen.dart
lib/features/mission/presentation/screen/mission_detail_screen.dart
lib/features/mypage/presentation/screen/my_page_screen.dart
```

### 9.3 상태관리 Provider

```txt
AuthProvider
LocationProvider
SpotProvider
StampProvider
PotatoProvider
MissionProvider
MyPageProvider
```

### 9.4 API 연결 기준

- 관광지 목록: `GET /api/spots`
- 주변 관광지: `GET /api/spots/nearby`
- 관광지 상세: `GET /api/spots/{spotId}`
- 방문 인증: `POST /api/stamps/verify`
- 내 스탬프: `GET /api/stamps/me`
- 내 감자 도감: `GET /api/potatoes/me`
- 주변 미션: `GET /api/missions/nearby`
- 미션 완료: `POST /api/missions/{missionId}/complete`
- 내 쿠폰: `GET /api/coupons/me`

---

## 10. Codex 작업 지시문

아래 기준에 맞춰 Flutter UI를 구현한다.

1. Bottom Navigation은 `[지도] [랠리북] [감자] [미션] [마이]` 5개 탭으로 구성한다.
2. 지도 탭은 카카오맵 기반 화면을 전제로 하되, 실제 지도 연동 전에는 placeholder map UI를 구현한다.
3. 감자 마커, 점순이 미션, 감자 탭, 랠리북은 게임형 수집 UX로 구현한다.
4. 모든 화면은 `Warm Cream` 배경과 `Primary Map Green(#56C787)` CTA를 기본으로 사용한다.
5. 감자 캐릭터 이미지는 실제 리소스가 없을 경우 임시 이모지 또는 placeholder asset으로 대체한다.
6. API 연결 전에는 mock data를 사용한다.
7. UI 컴포넌트는 재사용 가능한 widget으로 분리한다.
8. 화면 간 이동은 GoRouter 기준 라우팅 경로를 따른다.
9. Riverpod Provider 구조와 연결 가능한 형태로 screen/widget을 작성한다.
10. MVP 우선순위는 `온보딩 → 로그인 → 지도 → 관광지 상세 → 방문 인증 → 랠리북 → 감자 → 미션 → 마이/보상함` 순서로 한다.
