package com.gamjamubwatna.spot;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.spot.infrastructure.RelatedTourismApiClient;
import com.gamjamubwatna.spot.infrastructure.RelatedTourismApiClient.RelatedTourismSpot;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:spot_recommendation_flow;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
@AutoConfigureMockMvc(addFilters = false)
class SpotRecommendationFlowIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TouristSpotRepository touristSpotRepository;

    @MockitoBean
    private RelatedTourismApiClient relatedTourismApiClient;

    @Test
    void returnsTopThreeRelatedSpotsMappedToLocalDatabase() throws Exception {
        TouristSpot current = touristSpotRepository.save(spot("current", "뮤지엄산"));
        touristSpotRepository.save(spot("first", "원주소금산출렁다리"));
        touristSpotRepository.save(spot("second", "간현관광지"));
        touristSpotRepository.save(spot("third", "원주전통시장"));
        touristSpotRepository.save(spot("fourth", "원주감자체험장"));
        when(relatedTourismApiClient.searchRelatedSpots("뮤지엄산", "51130")).thenReturn(List.of(
            item("원주감자체험장", "4"),
            item("간현관광지", "2"),
            item("원주소금산출렁다리", "1"),
            item("원주전통시장", "3")
        ));

        mockMvc.perform(get("/spots/{spotId}/recommendations", current.getId()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.length()").value(3))
            .andExpect(jsonPath("$.data[0].name").value("원주소금산출렁다리"))
            .andExpect(jsonPath("$.data[0].externalRank").value(1))
            .andExpect(jsonPath("$.data[1].name").value("간현관광지"))
            .andExpect(jsonPath("$.data[2].name").value("원주전통시장"));
    }

    private TouristSpot spot(String contentId, String name) {
        return new TouristSpot(
            contentId,
            12,
            name,
            SpotCategory.POTATO_TOUR,
            new BigDecimal("37.3000000"),
            new BigDecimal("127.9000000"),
            "강원특별자치도 원주시",
            "원주시",
            "https://example.com/%s.jpg".formatted(contentId),
            "감자",
            Instant.parse("2026-07-16T00:00:00Z")
        );
    }

    private RelatedTourismSpot item(String relatedName, String rank) {
        return new RelatedTourismSpot(
            "202504",
            "source-code",
            "뮤지엄산",
            "51",
            "강원특별자치도",
            "51130",
            "원주시",
            "related-code",
            relatedName,
            "51",
            "강원특별자치도",
            "51130",
            "원주시",
            "관광지",
            "기타관광",
            "기타관광",
            rank
        );
    }
}
