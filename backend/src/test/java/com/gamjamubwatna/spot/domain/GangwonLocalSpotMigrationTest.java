package com.gamjamubwatna.spot.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@AutoConfigureMockMvc
@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:gangwon_local_spots;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough",
    "external.tour-api.service-key=",
    "external.google-places.api-key="
})
class GangwonLocalSpotMigrationTest {

    private static final Set<String> CONTENT_IDS = Set.of(
        "1828984", "2876420", "133817", "2790029", "2779972", "2815461", "4093743", "3041240"
    );

    @Autowired private TouristSpotRepository spots;
    @Autowired private SpotMenuItemRepository menus;
    @Autowired private MockMvc mvc;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void storesSharedMapPlacesWithOfficialReferencesWithoutChangingPassport() {
        List<TouristSpot> added = addedSpots();
        assertThat(added).hasSize(8).allSatisfy(spot -> {
            assertThat(spot.getLatitude()).isBetween(new BigDecimal("37.0"), new BigDecimal("38.7"));
            assertThat(spot.getLongitude()).isBetween(new BigDecimal("127.0"), new BigDecimal("129.6"));
            assertThat(spot.getAddress()).startsWith("강원특별자치도 ");
            assertThat(spot.getStampEnabled()).isFalse();
            assertThat(spot.getRallybookFeatured()).isFalse();
        });
        assertThat(added.stream().filter(spot -> spot.getImageUrl() != null)).hasSize(4);
        assertThat(added.stream().filter(spot -> spot.getCategory() == SpotCategory.POTATO_SHOP))
            .extracting(TouristSpot::getName).containsExactlyInAnyOrder("유리알유희", "동그란책");
        assertThat(spots.findActiveRallybookSpots()).hasSize(29);
        assertThat(spots.findActiveSpots(null, "속초시", null))
            .extracting(TouristSpot::getName).contains("칠성조선소", "동그란책");
    }

    @Test
    void storesConfirmedMenusWithoutInventingPricesOrFoodForSouvenirShops() {
        List<Long> ids = addedSpots().stream().map(TouristSpot::getId).toList();
        assertThat(menus.findActiveByTouristSpotIds(ids)).hasSize(12).allSatisfy(menu -> {
            assertThat(menu.getPriceWon()).isNull();
            assertThat(menu.getPriceNote()).isEqualTo("매장 가격 확인");
            assertThat(menu.getSourceUrl()).startsWith("https://apis.data.go.kr/B551011/KorService2/detailIntro2?");
            assertThat(menu.getSourceUrl()).doesNotContain("serviceKey");
            assertThat(menu.getVerifiedOn()).isEqualTo(LocalDate.of(2026, 9, 10));
        });
        List<Long> shopIds = addedSpots().stream()
            .filter(spot -> spot.getCategory() == SpotCategory.POTATO_SHOP)
            .map(TouristSpot::getId).toList();
        assertThat(menus.findActiveByTouristSpotIds(shopIds)).isEmpty();
    }

    @Test
    void exposesStoredPlacesAndMenusWithoutExternalKeys() throws Exception {
        mvc.perform(get("/spots").param("category", "POTATO_SHOP"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data[?(@.name == '유리알유희')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '동그란책')]").isNotEmpty());
        mvc.perform(get("/spots").param("category", "POTATO_CAFE").param("cityName", "원주시"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data[?(@.name == '한입감자')]").isNotEmpty());
        long id = spots.findByContentId("2815461").orElseThrow().getId();
        mvc.perform(get("/spots/{id}", id))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.name").value("한입감자"))
            .andExpect(jsonPath("$.data.menuItems[0].name").value("한입감자빵"))
            .andExpect(jsonPath("$.data.menuItems[0].priceWon").isEmpty());
    }

    @Test
    @Transactional
    void replayDoesNotDuplicateDataOrOverwriteOperatorImage() {
        jdbc.update("UPDATE tourist_spots SET image_url = ? WHERE content_id = ?",
            "https://example.com/operator.jpg", "4093743");
        int placeCount = jdbc.queryForObject("SELECT COUNT(*) FROM tourist_spots", Integer.class);
        int menuCount = jdbc.queryForObject("SELECT COUNT(*) FROM tourist_spot_menu_items", Integer.class);
        new ResourceDatabasePopulator(new ClassPathResource(
            "db/migration/V49__seed_verified_gangwon_food_and_shops.sql"
        )).execute(jdbc.getDataSource());
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM tourist_spots", Integer.class)).isEqualTo(placeCount);
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM tourist_spot_menu_items", Integer.class)).isEqualTo(menuCount);
        assertThat(jdbc.queryForObject("SELECT image_url FROM tourist_spots WHERE content_id = '4093743'", String.class))
            .isEqualTo("https://example.com/operator.jpg");
    }

    private List<TouristSpot> addedSpots() {
        return spots.findActiveSpots(null, null, null).stream()
            .filter(spot -> CONTENT_IDS.contains(spot.getContentId())).toList();
    }
}
