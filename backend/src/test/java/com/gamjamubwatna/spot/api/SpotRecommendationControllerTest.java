package com.gamjamubwatna.spot.api;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.spot.application.SpotRecommendationExternalException;
import com.gamjamubwatna.spot.application.SpotRecommendationNotFoundException;
import com.gamjamubwatna.spot.application.SpotRecommendationService;
import com.gamjamubwatna.spot.domain.SpotCategory;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(SpotRecommendationController.class)
@AutoConfigureMockMvc(addFilters = false)
class SpotRecommendationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private SpotRecommendationService spotRecommendationService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsRelatedSpotRecommendations() throws Exception {
        when(spotRecommendationService.getRecommendations(1L)).thenReturn(List.of(
            new SpotRecommendationResponse(
                2L,
                "원주소금산출렁다리",
                SpotCategory.POTATO_TOUR,
                new BigDecimal("37.3681000"),
                new BigDecimal("127.8330000"),
                "강원특별자치도 원주시",
                "원주시",
                "https://example.com/spot.jpg",
                List.of("https://example.com/spot.jpg"),
                2
            )
        ));

        mockMvc.perform(get("/spots/1/recommendations"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data[0].spotId").value(2))
            .andExpect(jsonPath("$.data[0].name").value("원주소금산출렁다리"))
            .andExpect(jsonPath("$.data[0].imageUrl").value("https://example.com/spot.jpg"))
            .andExpect(jsonPath("$.data[0].imageUrls[0]").value("https://example.com/spot.jpg"))
            .andExpect(jsonPath("$.data[0].externalRank").value(2));
    }

    @Test
    void returnsNotFoundForUnknownSpot() throws Exception {
        when(spotRecommendationService.getRecommendations(99L))
            .thenThrow(new SpotRecommendationNotFoundException("관광지를 찾을 수 없습니다."));

        mockMvc.perform(get("/spots/99/recommendations"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("관광지를 찾을 수 없습니다."));
    }

    @Test
    void returnsServiceUnavailableWhenExternalApiFails() throws Exception {
        when(spotRecommendationService.getRecommendations(1L))
            .thenThrow(new SpotRecommendationExternalException("외부 API 오류", null));

        mockMvc.perform(get("/spots/1/recommendations"))
            .andExpect(status().isServiceUnavailable())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("외부 API 오류"));
    }
}
