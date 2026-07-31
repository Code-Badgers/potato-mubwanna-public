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
        List<TouristSpot> spots = touristSpotRepository.findActiveSpots(null, null, null);

        assertThat(spots)
            .hasSize(3)
            .extracting(TouristSpot::getName)
            .containsExactlyInAnyOrder("정선 5일장", "남이섬", "감자밭");
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
            .containsExactlyInAnyOrder(
                SpotCategory.POTATO_MARKET,
                SpotCategory.POTATO_TOUR,
                SpotCategory.POTATO_CAFE
            );
    }

    @Test
    void exposesCuratedSpotsThroughPublicApi() throws Exception {
        mockMvc.perform(get("/spots"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.length()").value(3))
            .andExpect(jsonPath("$.data[?(@.name == '정선 5일장')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '남이섬')]").isNotEmpty())
            .andExpect(jsonPath("$.data[?(@.name == '감자밭')]").isNotEmpty());
    }
}
