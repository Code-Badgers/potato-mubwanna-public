package com.gamjamubwatna.spot.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.util.List;
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

    @Autowired
    private TouristSpotRepository touristSpotRepository;

    @Autowired
    private MockMvc mockMvc;

    @Test
    void seedsCuratedSpotsForFreshDatabase() {
        List<TouristSpot> spots = curatedSpots();

        assertThat(spots)
            .hasSize(8)
            .extracting(TouristSpot::getName)
            .containsExactlyInAnyOrder(
                "정선 5일장",
                "남이섬",
                "감자밭",
                "감자적1번지",
                "강릉 길감자",
                "바회마을",
                "감자아일랜드 춘천",
                "대관령원예농협 바우파머스"
            );
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
        List<TouristSpot> spots = curatedSpots();

        assertThat(spots)
            .extracting(TouristSpot::getCategory)
            .containsExactlyInAnyOrder(
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
            .andExpect(jsonPath("$.data[?(@.category == 'POTATO_SNACK')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.category == 'POTATO_BREWERY')]").isNotEmpty());
    }

    private List<TouristSpot> curatedSpots() {
        return touristSpotRepository.findActiveSpots(null, null, null).stream()
            .filter(spot -> spot.getContentId() != null)
            .filter(spot -> spot.getContentId().startsWith("CURATED:"))
            .toList();
    }
}
