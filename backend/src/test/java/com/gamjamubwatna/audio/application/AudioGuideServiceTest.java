package com.gamjamubwatna.audio.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.audio.domain.AudioGuide;
import com.gamjamubwatna.audio.domain.AudioGuideRepository;
import com.gamjamubwatna.audio.infrastructure.external.OdiiApiClient;
import com.gamjamubwatna.audio.infrastructure.external.OdiiApiClient.OdiiStory;
import com.gamjamubwatna.audio.infrastructure.external.OdiiApiException;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class AudioGuideServiceTest {

    private static final Instant NOW = Instant.parse("2026-07-15T00:00:00Z");

    @Mock
    private TouristSpotRepository touristSpotRepository;

    @Mock
    private AudioGuideRepository audioGuideRepository;

    @Mock
    private OdiiApiClient odiiApiClient;

    private AudioGuideService audioGuideService;

    @BeforeEach
    void setUp() {
        audioGuideService = new AudioGuideService(
            touristSpotRepository,
            audioGuideRepository,
            odiiApiClient,
            Clock.fixed(NOW, ZoneOffset.UTC)
        );
    }

    @Test
    void returnsCachedGuideWithoutCallingExternalApi() {
        TouristSpot spot = spot("정선 5일장");
        AudioGuide cached = guide(spot);
        ReflectionTestUtils.setField(cached, "id", 7L);
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(audioGuideRepository.findByTouristSpotIdAndLanguage(1L, "ko"))
            .thenReturn(Optional.of(cached));

        var response = audioGuideService.getAudioGuide(1L);

        assertThat(response.id()).isEqualTo(7L);
        assertThat(response.title()).isEqualTo("정선 5일장 이야기");
        verify(odiiApiClient, never()).searchStories(any());
    }

    @Test
    void selectsExactKoreanTitleAndCachesGuide() {
        TouristSpot spot = spot("정선 5일장");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(audioGuideRepository.findByTouristSpotIdAndLanguage(1L, "ko"))
            .thenReturn(Optional.empty());
        when(odiiApiClient.searchStories("정선 5일장")).thenReturn(List.of(
            story("21", "정선 5일장 주변", "ko", "https://example.com/wrong.mp3"),
            story("22", "정선   5일장", "ko", "https://example.com/right.mp3"),
            story("23", "정선 5일장", "en", "https://example.com/english.mp3")
        ));
        when(audioGuideRepository.saveAndFlush(any(AudioGuide.class))).thenAnswer(invocation -> {
            AudioGuide guide = invocation.getArgument(0);
            ReflectionTestUtils.setField(guide, "id", 8L);
            return guide;
        });

        var response = audioGuideService.getAudioGuide(1L);

        assertThat(response.id()).isEqualTo(8L);
        assertThat(response.audioUrl()).isEqualTo("https://example.com/right.mp3");
        assertThat(response.script()).isEqualTo("정선 5일장은...");
        assertThat(response.characterScript()).isNull();
        verify(audioGuideRepository).saveAndFlush(any(AudioGuide.class));
    }

    @Test
    void selectsQualifiedOdiiTitleContainingSpotName() {
        TouristSpot spot = spot("오죽헌", "강릉시");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(audioGuideRepository.findByTouristSpotIdAndLanguage(1L, "ko"))
            .thenReturn(Optional.empty());
        when(odiiApiClient.searchStories("오죽헌")).thenReturn(List.of(
            story("21", "강릉 오죽헌(초등 교과연계)", "ko", "https://example.com/audio.mp3")
        ));
        when(audioGuideRepository.saveAndFlush(any(AudioGuide.class))).thenAnswer(invocation -> {
            AudioGuide guide = invocation.getArgument(0);
            ReflectionTestUtils.setField(guide, "id", 9L);
            return guide;
        });

        var response = audioGuideService.getAudioGuide(1L);

        assertThat(response.id()).isEqualTo(9L);
        assertThat(response.audioUrl()).isEqualTo("https://example.com/audio.mp3");
    }

    @Test
    void rejectsSameNameAudioGuideFromAnotherRegion() {
        TouristSpot spot = spot("통일전망대", "고성군");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(audioGuideRepository.findByTouristSpotIdAndLanguage(1L, "ko"))
            .thenReturn(Optional.empty());
        when(odiiApiClient.searchStories("통일전망대")).thenReturn(List.of(
            story("21", "오두산 통일전망대", "ko", "https://example.com/paju.mp3")
        ));

        assertThatThrownBy(() -> audioGuideService.getAudioGuide(1L))
            .isInstanceOf(AudioGuideNotFoundException.class)
            .hasMessage("이 관광지의 오디오 가이드를 찾을 수 없습니다.");
        verify(audioGuideRepository, never()).saveAndFlush(any(AudioGuide.class));
    }

    @Test
    void selectsRegionalAudioGuideAmongAmbiguousPartialMatches() {
        TouristSpot spot = spot("낙산사", "양양군");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(audioGuideRepository.findByTouristSpotIdAndLanguage(1L, "ko"))
            .thenReturn(Optional.empty());
        when(odiiApiClient.searchStories("낙산사")).thenReturn(List.of(
            story("21", "낙산사권역_낙산해수욕장", "ko", "https://example.com/beach.mp3"),
            story("22", "양양, 낙산사 (나레이션 - 김윤주)", "ko", "https://example.com/temple.mp3")
        ));
        when(audioGuideRepository.saveAndFlush(any(AudioGuide.class))).thenAnswer(invocation -> {
            AudioGuide guide = invocation.getArgument(0);
            ReflectionTestUtils.setField(guide, "id", 12L);
            return guide;
        });

        var response = audioGuideService.getAudioGuide(1L);

        assertThat(response.id()).isEqualTo(12L);
        assertThat(response.audioUrl()).isEqualTo("https://example.com/temple.mp3");
    }

    @Test
    void treatsFiveDayMarketAndKoreanNumberAsSameName() {
        TouristSpot spot = spot("정선 5일장");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(audioGuideRepository.findByTouristSpotIdAndLanguage(1L, "ko"))
            .thenReturn(Optional.empty());
        when(odiiApiClient.searchStories("정선 5일장")).thenReturn(List.of(
            story("21", "정선오일장", "ko", "https://example.com/audio.mp3")
        ));
        when(audioGuideRepository.saveAndFlush(any(AudioGuide.class))).thenAnswer(invocation -> {
            AudioGuide guide = invocation.getArgument(0);
            ReflectionTestUtils.setField(guide, "id", 10L);
            return guide;
        });

        var response = audioGuideService.getAudioGuide(1L);

        assertThat(response.id()).isEqualTo(10L);
        assertThat(response.audioUrl()).isEqualTo("https://example.com/audio.mp3");
    }

    @Test
    void returnsCacheSavedByConcurrentWinnerAfterDuplicateSave() {
        TouristSpot spot = spot("정선 5일장");
        AudioGuide winner = guide(spot);
        ReflectionTestUtils.setField(winner, "id", 11L);
        DataIntegrityViolationException duplicate = new DataIntegrityViolationException(
            "duplicate audio cache"
        );
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(audioGuideRepository.findByTouristSpotIdAndLanguage(1L, "ko"))
            .thenReturn(Optional.empty())
            .thenReturn(Optional.of(winner));
        when(odiiApiClient.searchStories("정선 5일장")).thenReturn(List.of(
            story("21", "정선 5일장", "ko", "https://example.com/audio.mp3")
        ));
        when(audioGuideRepository.saveAndFlush(any(AudioGuide.class))).thenThrow(duplicate);

        var response = audioGuideService.getAudioGuide(1L);

        assertThat(response.id()).isEqualTo(11L);
        assertThat(response.audioUrl()).isEqualTo("https://example.com/audio.mp3");
    }

    @Test
    void rethrowsSaveFailureWhenConcurrentCacheDoesNotExist() {
        TouristSpot spot = spot("정선 5일장");
        DataIntegrityViolationException failure = new DataIntegrityViolationException(
            "audio cache insert failed"
        );
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(audioGuideRepository.findByTouristSpotIdAndLanguage(1L, "ko"))
            .thenReturn(Optional.empty());
        when(odiiApiClient.searchStories("정선 5일장")).thenReturn(List.of(
            story("21", "정선 5일장", "ko", "https://example.com/audio.mp3")
        ));
        when(audioGuideRepository.saveAndFlush(any(AudioGuide.class))).thenThrow(failure);

        assertThatThrownBy(() -> audioGuideService.getAudioGuide(1L))
            .isSameAs(failure);
    }

    @Test
    void rejectsUnknownSpot() {
        when(touristSpotRepository.findByIdAndActiveTrue(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> audioGuideService.getAudioGuide(99L))
            .isInstanceOf(AudioGuideNotFoundException.class)
            .hasMessage("관광지를 찾을 수 없습니다.");
    }

    @Test
    void rejectsWhenNoExactAudioGuideExists() {
        TouristSpot spot = spot("정선 5일장");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(audioGuideRepository.findByTouristSpotIdAndLanguage(1L, "ko"))
            .thenReturn(Optional.empty());
        when(odiiApiClient.searchStories("정선 5일장"))
            .thenReturn(List.of(story("21", "정선 아리랑시장", "ko", "https://example.com/a.mp3")));

        assertThatThrownBy(() -> audioGuideService.getAudioGuide(1L))
            .isInstanceOf(AudioGuideNotFoundException.class)
            .hasMessage("이 관광지의 오디오 가이드를 찾을 수 없습니다.");
    }

    @Test
    void convertsExternalApiFailureToServiceUnavailableError() {
        TouristSpot spot = spot("정선 5일장");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(audioGuideRepository.findByTouristSpotIdAndLanguage(1L, "ko"))
            .thenReturn(Optional.empty());
        when(odiiApiClient.searchStories("정선 5일장"))
            .thenThrow(new OdiiApiException("인증키 오류"));

        assertThatThrownBy(() -> audioGuideService.getAudioGuide(1L))
            .isInstanceOf(AudioGuideExternalException.class)
            .hasMessage("오디오 가이드 제공 서비스에 연결할 수 없습니다.");
    }

    private TouristSpot spot(String name) {
        return spot(name, "정선군");
    }

    private TouristSpot spot(String name, String cityName) {
        TouristSpot spot = new TouristSpot(
            "12345",
            12,
            name,
            SpotCategory.POTATO_MARKET,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
            "강원특별자치도 정선군",
            cityName,
            null,
            "감자",
            NOW
        );
        ReflectionTestUtils.setField(spot, "id", 1L);
        return spot;
    }

    private AudioGuide guide(TouristSpot spot) {
        return new AudioGuide(
            spot,
            "20",
            "정선 5일장 이야기",
            "https://example.com/audio.mp3",
            "정선 5일장은...",
            null,
            "ko",
            NOW
        );
    }

    private OdiiStory story(String id, String title, String language, String audioUrl) {
        return new OdiiStory(
            "10",
            "11",
            id,
            "31",
            title,
            "정선 5일장 이야기",
            "정선 5일장은...",
            audioUrl,
            language
        );
    }
}
