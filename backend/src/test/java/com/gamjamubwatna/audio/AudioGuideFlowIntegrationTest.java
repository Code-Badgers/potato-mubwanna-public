package com.gamjamubwatna.audio;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.audio.domain.AudioGuideRepository;
import com.gamjamubwatna.audio.infrastructure.external.OdiiApiClient;
import com.gamjamubwatna.audio.infrastructure.external.OdiiApiClient.OdiiStory;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
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
    "spring.datasource.url=jdbc:h2:mem:audio_guide_flow;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
@AutoConfigureMockMvc(addFilters = false)
class AudioGuideFlowIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TouristSpotRepository touristSpotRepository;

    @Autowired
    private AudioGuideRepository audioGuideRepository;

    @MockitoBean
    private OdiiApiClient odiiApiClient;

    @Test
    void fetchesPersistsAndReusesAudioGuide() throws Exception {
        TouristSpot spot = touristSpotRepository.save(new TouristSpot(
            "12345",
            12,
            "정선 5일장",
            SpotCategory.POTATO_MARKET,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
            "강원특별자치도 정선군",
            "정선군",
            null,
            "감자",
            Instant.parse("2026-07-15T00:00:00Z")
        ));
        when(odiiApiClient.searchStories("정선 5일장")).thenReturn(List.of(new OdiiStory(
            "10",
            "11",
            "20",
            "21",
            "정선 5일장",
            "정선 5일장 이야기",
            "정선 5일장은...",
            "https://example.com/audio.mp3",
            "ko"
        )));

        mockMvc.perform(get("/audio-guides/spots/{spotId}", spot.getId()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.title").value("정선 5일장 이야기"))
            .andExpect(jsonPath("$.data.audioUrl").value("https://example.com/audio.mp3"));

        mockMvc.perform(get("/audio-guides/spots/{spotId}", spot.getId()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.title").value("정선 5일장 이야기"));

        assertThat(audioGuideRepository.findByTouristSpotIdAndLanguage(spot.getId(), "ko"))
            .isPresent();
        verify(odiiApiClient, times(1)).searchStories("정선 5일장");
    }
}
