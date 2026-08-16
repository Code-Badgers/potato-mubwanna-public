package com.gamjamubwatna.spot.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

@AutoConfigureMockMvc
@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:tourist_spot_migration;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class TouristSpotMigrationTest {

    private static final Map<String, String> OFFICIAL_ATTRACTIONS = Map.ofEntries(
        Map.entry("남이섬", "128019"),
        Map.entry("소양강 스카이워크", "2396037"),
        Map.entry("뮤지엄 산", "2633832"),
        Map.entry("안목해변", "127722"),
        Map.entry("경포대", "125790"),
        Map.entry("묵호등대", "129176"),
        Map.entry("논골담길", "1223212"),
        Map.entry("황지연못", "125740"),
        Map.entry("속초관광수산시장", "1260275"),
        Map.entry("영금정", "125779"),
        Map.entry("환선굴", "126729"),
        Map.entry("장호항", "125711"),
        Map.entry("수타사", "125764"),
        Map.entry("비발디파크", "131301"),
        Map.entry("횡성호수길", "2774026"),
        Map.entry("청령포", "125785"),
        Map.entry("장릉", "125794"),
        Map.entry("대관령 양떼목장", "129263"),
        Map.entry("이효석문학관", "130415"),
        Map.entry("정선 5일장", "132003"),
        Map.entry("고석정", "2615225"),
        Map.entry("산천어축제장", "507599"),
        Map.entry("박수근미술관", "130493"),
        Map.entry("두타연", "126603"),
        Map.entry("원대리 자작나무숲", "1818945"),
        Map.entry("통일전망대", "128171"),
        Map.entry("화진포", "125706"),
        Map.entry("서피비치", "2501905"),
        Map.entry("낙산사", "125773")
    );

    private static final Set<String> GANGWON_CITIES = Set.of(
        "춘천시", "원주시", "강릉시", "동해시", "태백시", "속초시", "삼척시",
        "홍천군", "횡성군", "영월군", "평창군", "정선군", "철원군", "화천군",
        "양구군", "인제군", "고성군", "양양군"
    );

    @Autowired
    private TouristSpotRepository touristSpotRepository;

    @Autowired
    private SpotMenuItemRepository spotMenuItemRepository;

    @Autowired
    private MockMvc mockMvc;

    @Test
    void seedsCuratedSpotsForFreshDatabase() {
        List<TouristSpot> spots = curatedSpots();

        assertThat(spots)
            .hasSizeGreaterThanOrEqualTo(24)
            .extracting(TouristSpot::getName)
            .contains(
                "감자밭",
                "감자적1번지",
                "강릉 길감자",
                "바회마을",
                "감자아일랜드 춘천",
                "대관령원예농협 바우파머스",
                "감자유원지",
                "대관령감자빵",
                "속초불탄감자빵 본점 아궁이카페",
                "만낭포감자떡 본점",
                "옹심이장칼국수 감자바우",
                "감자아일랜드 온의점",
                "삶은감자",
                "감자네",
                "강릉감자천국",
                "감자뭉팅이",
                "감자꽃스튜디오",
                "늘햇살 만우농촌체험마을",
                "대관령감자옹심이"
            );
    }

    @Test
    void seedsOfficialAttractionsForEveryGangwonCity() {
        List<TouristSpot> spots = officialAttractions();

        assertThat(spots)
            .hasSize(OFFICIAL_ATTRACTIONS.size())
            .allSatisfy(spot -> {
                assertThat(spot.getContentId()).isEqualTo(OFFICIAL_ATTRACTIONS.get(spot.getName()));
                assertThat(spot.getLatitude())
                    .isBetween(new BigDecimal("37.0"), new BigDecimal("38.7"));
                assertThat(spot.getLongitude())
                    .isBetween(new BigDecimal("127.0"), new BigDecimal("129.5"));
                assertThat(spot.getImageUrl()).startsWith("https://tong.visitkorea.or.kr/");
                assertThat(spot.getStampEnabled()).isTrue();
                assertThat(spot.getRallybookFeatured()).isTrue();
            });

        assertThat(spots.stream().map(TouristSpot::getCityName).collect(Collectors.toSet()))
            .containsExactlyInAnyOrderElementsOf(GANGWON_CITIES);
    }

    @Test
    void selectsOnlyTheOfficialAttractionsForTheRallybook() {
        List<TouristSpot> spots = touristSpotRepository.findActiveRallybookSpots();

        assertThat(spots)
            .hasSize(OFFICIAL_ATTRACTIONS.size())
            .extracting(TouristSpot::getContentId)
            .containsExactlyInAnyOrderElementsOf(OFFICIAL_ATTRACTIONS.values());
    }

    @Test
    void replacesHandWrittenCoordinatesWithTourApiCoordinates() {
        Map<String, TouristSpot> spotsByName = officialAttractions().stream()
            .collect(Collectors.toMap(TouristSpot::getName, spot -> spot));

        TouristSpot namiIsland = spotsByName.get("남이섬");
        assertThat(namiIsland.getLatitude()).isEqualByComparingTo("37.7962651");
        assertThat(namiIsland.getLongitude()).isEqualByComparingTo("127.5254892");

        TouristSpot jeongseonMarket = spotsByName.get("정선 5일장");
        assertThat(jeongseonMarket.getLatitude()).isEqualByComparingTo("37.3805311");
        assertThat(jeongseonMarket.getLongitude()).isEqualByComparingTo("128.6647911");
    }

    @Test
    void seedsMissionLinkedSpotsWithValidMapData() {
        List<TouristSpot> spots = touristSpotRepository.findActiveSpots(null, null, null);

        assertThat(spots)
            .filteredOn(spot -> List.of("정선 5일장", "남이섬").contains(spot.getName()))
            .hasSize(2)
            .allSatisfy(spot -> {
                assertThat(spot.getLatitude())
                    .isBetween(new BigDecimal("37.0"), new BigDecimal("38.7"));
                assertThat(spot.getLongitude())
                    .isBetween(new BigDecimal("127.0"), new BigDecimal("129.5"));
                assertThat(spot.getCityName()).isNotBlank();
                assertThat(spot.getStampEnabled()).isTrue();
            });
    }

    @Test
    void seedsMapCategoriesUsedByTheMvp() {
        List<TouristSpot> spots = touristSpotRepository.findActiveSpots(null, null, null);

        assertThat(spots)
            .extracting(TouristSpot::getCategory)
            .contains(
                SpotCategory.POTATO_MARKET,
                SpotCategory.POTATO_TOUR,
                SpotCategory.POTATO_CAFE,
                SpotCategory.POTATO_RESTAURANT,
                SpotCategory.POTATO_SNACK,
                SpotCategory.POTATO_EXPERIENCE,
                SpotCategory.POTATO_BREWERY,
                SpotCategory.POTATO_SHOP
            );
    }

    @Test
    void seedsCuratedContentIdsWithoutDuplicates() {
        List<TouristSpot> spots = curatedSpots();

        assertThat(spots)
            .extracting(TouristSpot::getContentId)
            .allSatisfy(contentId -> assertThat(contentId).startsWith("CURATED:"))
            .doesNotHaveDuplicates();
    }

    @Test
    void seedsOfficiallySourcedMenusOnlyForSupportedCuratedSpots() {
        Map<String, TouristSpot> spotsByName = curatedSpots().stream()
            .collect(Collectors.toMap(TouristSpot::getName, spot -> spot));
        List<Long> curatedSpotIds = spotsByName.values().stream()
            .map(TouristSpot::getId)
            .toList();

        List<SpotMenuItem> menuItems = spotMenuItemRepository
            .findActiveByTouristSpotIds(curatedSpotIds);

        assertThat(menuItems)
            .hasSizeGreaterThanOrEqualTo(21)
            .allSatisfy(item -> {
                assertThat(item.getVerifiedOn())
                    .isIn(LocalDate.of(2026, 8, 4), LocalDate.of(2026, 8, 16));
                assertThat(item.getSourceUrl())
                    .doesNotStartWith("https://place.map.kakao.com/");
            });
        assertThat(menuItems)
            .extracting(
                SpotMenuItem::getName,
                SpotMenuItem::getPriceWon,
                SpotMenuItem::getPriceNote
            )
            .contains(
                tuple("원조 감자빵 10개입 (공식몰)", 33000, null),
                tuple("감자적", 6000, null),
                tuple("컵길감자", 3100, null),
                tuple("감자둥둥섬", null, "매장 가격 확인"),
                tuple("감자전", 10000, null),
                tuple("꿀치즈감자채전", 15000, null),
                tuple("감자 둥글레 6알", 4500, null),
                tuple("감자뭉팅이", 5000, null),
                tuple("사골옹심이국수", 10000, null),
                tuple("감자라떼", 6000, null),
                tuple("치즈말이 감자전", 9000, null)
            );
        assertThat(menuItems)
            .extracting(SpotMenuItem::getName)
            .doesNotContain("감자 선장의 해물 보따리", "아메리카노");
        assertThat(menuItems)
            .extracting(SpotMenuItem::getSourceUrl)
            .containsOnly(
                "https://gamzabatt.com/all/?idx=1",
                "https://app.catchtable.co.kr/ct/shop/gamjageok1",
                "https://www.instagram.com/gil_potato/reel/DQJBIyqkYU8/",
                "https://pf.kakao.com/_xbxfxgAs",
                "https://app.notion.com/p/3be51ca118cf803cb1aacbe1cb448423"
            );
        assertThat(menuItems)
            .extracting(SpotMenuItem::getTouristSpotId)
            .doesNotContain(
                spotsByName.get("바회마을").getId(),
                spotsByName.get("대관령원예농협 바우파머스").getId()
            );
    }

    @Test
    void exposesCuratedSpotsThroughPublicApi() throws Exception {
        mockMvc.perform(get("/spots"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data[?(@.name == '정선 5일장')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '남이섬')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '감자밭')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '감자적1번지')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '강릉 길감자')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '바회마을')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '감자아일랜드 춘천')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '대관령원예농협 바우파머스')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '감자유원지')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '대관령감자빵')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '속초불탄감자빵 본점 아궁이카페')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '만낭포감자떡 본점')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '옹심이장칼국수 감자바우')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '삶은감자')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '감자네')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '감자뭉팅이')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '늘햇살 만우농촌체험마을')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '소양강 스카이워크')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '뮤지엄 산')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '통일전망대')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '낙산사')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.category == 'POTATO_SNACK')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.category == 'POTATO_BREWERY')]").isNotEmpty());
    }

    private List<TouristSpot> curatedSpots() {
        return touristSpotRepository.findActiveSpots(null, null, null).stream()
            .filter(spot -> spot.getContentId() != null)
            .filter(spot -> spot.getContentId().startsWith("CURATED:"))
            .toList();
    }

    private List<TouristSpot> officialAttractions() {
        return touristSpotRepository.findActiveSpots(null, null, null).stream()
            .filter(spot -> OFFICIAL_ATTRACTIONS.containsKey(spot.getName()))
            .toList();
    }
}
