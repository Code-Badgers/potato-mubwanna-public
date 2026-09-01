<div align="center">

<a href="https://m.onestore.co.kr/v2/ko-kr/app/0001008521" title="원스토어에서 감자무봤나 만나보기">
  <img width="920" alt="감자무봤나 서비스 소개 및 원스토어 바로가기" src="https://github.com/user-attachments/assets/8a320d10-ea22-43b7-8a22-f805db54c3bd" />
</a>

# 감자무봤나

강원특별자치도 18개 시·군을 여행하며 관광지 스탬프와 지역 감자 캐릭터를 모으는 위치 기반 관광 앱입니다.

<p>
  <a href="https://m.onestore.co.kr/v2/ko-kr/app/0001008521"><strong>원스토어에서 다운로드</strong></a>
</p>

[서비스 소개](#서비스-소개) · [주요 기능](#주요-기능) · [기술 스택](#기술-스택)

</div>

---

## 서비스 소개

감자무봤나는 지도 탐색, 방문 인증, 스탬프 수집, 미션과 보상을 하나의 여행 흐름으로 연결합니다.

카카오맵에서 주변 관광지를 찾고 현장에서 방문을 인증하면 디지털 스탬프가 쌓입니다. 걸음과 미션으로 감자 캐릭터를 성장시키고, 여행 기록과 쿠폰 보상을 관리할 수 있습니다.

**서비스 범위** — 강원특별자치도 18개 시·군 · 패스포트 관광지 29곳 · Android `1.0.0+1`

---

## 주요 기능

### 지도 탐색과 오디오 해설

주변 관광지를 지도에서 찾고, 관광지 상세 정보와 한국관광공사 Odii 오디오 해설을 확인합니다.

<table>
  <tr>
    <td align="center" width="50%">
      <img src="artifacts/validation/issue-239/android-arm64-map.png" width="320" alt="강원 관광지 카카오맵 화면" /><br />
      <b>지도</b><br />주변 관광지 탐색과 동선 저장
    </td>
    <td align="center" width="50%">
      <img src="artifacts/validation/issue-447/spot-2-audio-playing.png" width="320" alt="관광지 오디오 가이드 재생 화면" /><br />
      <b>관광지 상세</b><br />관광 정보와 오디오 해설
    </td>
  </tr>
</table>

### 관광지 패스포트

관광지 현장에서 방문을 인증하면 장소별 스탬프가 쌓입니다. 패스포트에서 29개 관광지의 방문 현황을 확인할 수 있습니다.

<table>
  <tr>
    <td align="center" width="50%">
      <img src="artifacts/validation/issue-251/02-rallybook-all-spots.png" width="320" alt="강원 18개 시군 스탬프 랠리북 화면" /><br />
      <b>관광지 목록</b><br />29개 관광지의 방문 현황
    </td>
    <td align="center" width="50%">
      <img src="artifacts/validation/issue-257/stamp_contact_sheet.png" width="430" alt="29개 관광지 패스포트 스탬프" /><br />
      <b>패스포트 스탬프</b><br />관광지별 디지털 스탬프
    </td>
  </tr>
</table>

### 감자 성장과 미션

걸음 수로 대표 감자를 성장시키고, 위치·사진·걸음·퀴즈·QR 미션을 수행합니다.

<table>
  <tr>
    <td align="center" width="50%">
      <img src="artifacts/validation/issue-203/potato-character-assets-preview.png" width="460" alt="지역별 감자 캐릭터 도감" /><br />
      <b>감자 도감</b><br />지역별 감자 캐릭터 수집
    </td>
    <td align="center" width="50%">
      <img src="artifacts/validation/issue-399/photo-mission-success-device.png" width="320" alt="점순이 사진 미션 화면" /><br />
      <b>점순이 미션</b><br />여행지에서 수행하는 미션
    </td>
  </tr>
</table>

### 여행 기록과 보상

방문 인증 사진은 여행 기록으로 모이고, 스탬프와 미션으로 받은 쿠폰은 보상함에서 관리합니다.

<table>
  <tr>
    <td align="center" width="50%">
      <img src="artifacts/validation/issue-255/03-travel-record-photo.png" width="320" alt="강원 여행 기록 화면" /><br />
      <b>여행 기록</b><br />방문 장소와 인증 사진
    </td>
    <td align="center" width="50%">
      <img src="artifacts/validation/issue-185/coupon-list-mobile.png" width="320" alt="여행 보상 쿠폰함 화면" /><br />
      <b>보상함</b><br />쿠폰과 보상 내역 관리
    </td>
  </tr>
</table>

<details>
<summary><b>데이터 및 외부 서비스</b></summary>

- 한국관광공사 관광정보·오디오 가이드·관광객 집중도·연관 관광지 API
- Kakao Login, Kakao Maps, Kakao Local API
- Firebase Cloud Messaging
- Google Places 기반 관광지 상세정보 보강

</details>

---

## 기술 스택

<div align="center">

<img width="920" alt="감자무봤나 기술 스택" src="https://github.com/user-attachments/assets/5868d421-9fb9-4ce2-9c73-4aeb837195e6" />

</div>

---

<div align="center">

**관광지는 보고 · 스탬프는 찍고 · 감자는 모으고**

</div>
