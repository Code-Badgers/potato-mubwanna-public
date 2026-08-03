package com.gamjamubwatna.audio;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.audio.application.AudioGuideService;
import com.gamjamubwatna.audio.domain.AudioGuideRepository;
import com.gamjamubwatna.audio.infrastructure.external.OdiiApiClient;
import com.gamjamubwatna.audio.infrastructure.external.OdiiApiClient.OdiiStory;
import com.gamjamubwatna.audio.infrastructure.external.OdiiApiException;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
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

    @Autowired
    private AudioGuideService audioGuideService;

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

    @Test
    void concurrentCacheMissesReturnTheSamePersistedGuide() throws Exception {
        TouristSpot spot = touristSpotRepository.save(new TouristSpot(
            "concurrent-audio",
            12,
            "강릉 오죽헌",
            SpotCategory.POTATO_TOUR,
            new BigDecimal("37.7791000"),
            new BigDecimal("128.8762000"),
            "강원특별자치도 강릉시",
            "강릉시",
            null,
            "관광",
            Instant.parse("2026-07-15T00:00:00Z")
        ));
        long guideCountBefore = audioGuideRepository.count();
        CountDownLatch bothSearching = new CountDownLatch(2);
        when(odiiApiClient.searchStories("강릉 오죽헌")).thenAnswer(invocation -> {
            bothSearching.countDown();
            if (!bothSearching.await(5, TimeUnit.SECONDS)) {
                throw new IllegalStateException("두 요청이 모두 캐시 미스에 진입하지 않았습니다.");
            }
            return List.of(new OdiiStory(
                "30",
                "31",
                "32",
                "33",
                "강릉 오죽헌",
                "오죽헌 이야기",
                "오죽헌은...",
                "https://example.com/ojukheon.mp3",
                "ko"
            ));
        });
        Callable<Long> fetchGuide = () -> audioGuideService.getAudioGuide(spot.getId()).id();

        List<Long> guideIds;
        try (ExecutorService executor = Executors.newFixedThreadPool(2)) {
            Future<Long> first = executor.submit(fetchGuide);
            Future<Long> second = executor.submit(fetchGuide);
            guideIds = List.of(
                first.get(10, TimeUnit.SECONDS),
                second.get(10, TimeUnit.SECONDS)
            );
        }

        assertThat(guideIds).doesNotContainNull().containsOnly(guideIds.getFirst());
        assertThat(audioGuideRepository.count()).isEqualTo(guideCountBefore + 1);
        verify(odiiApiClient, times(2)).searchStories("강릉 오죽헌");
    }

    @Test
    void retriesExternalLookupAfterTransientFailure() throws Exception {
        TouristSpot spot = touristSpotRepository.save(new TouristSpot(
            "retry-audio",
            12,
            "평창 효석문화제",
            SpotCategory.POTATO_TOUR,
            new BigDecimal("37.6148000"),
            new BigDecimal("128.3797000"),
            "강원특별자치도 평창군",
            "평창군",
            null,
            "관광",
            Instant.parse("2026-07-15T00:00:00Z")
        ));
        when(odiiApiClient.searchStories("평창 효석문화제"))
            .thenThrow(new OdiiApiException("일시적 외부 오류"))
            .thenReturn(List.of(new OdiiStory(
                "40",
                "41",
                "42",
                "43",
                "평창 효석문화제",
                "효석문화제 이야기",
                "효석문화제는...",
                "https://example.com/hyoseok.mp3",
                "ko"
            )));

        mockMvc.perform(get("/audio-guides/spots/{spotId}", spot.getId()))
            .andExpect(status().isServiceUnavailable());
        mockMvc.perform(get("/audio-guides/spots/{spotId}", spot.getId()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.audioUrl").value(
                "https://example.com/hyoseok.mp3"
            ));

        assertThat(audioGuideRepository.findByTouristSpotIdAndLanguage(spot.getId(), "ko"))
            .isPresent();
        verify(odiiApiClient, times(2)).searchStories("평창 효석문화제");
    }
}
