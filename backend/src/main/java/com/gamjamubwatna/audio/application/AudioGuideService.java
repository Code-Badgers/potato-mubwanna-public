package com.gamjamubwatna.audio.application;

import com.gamjamubwatna.audio.api.AudioGuideResponse;
import com.gamjamubwatna.audio.domain.AudioGuide;
import com.gamjamubwatna.audio.domain.AudioGuideRepository;
import com.gamjamubwatna.audio.infrastructure.external.OdiiApiClient;
import com.gamjamubwatna.audio.infrastructure.external.OdiiApiClient.OdiiStory;
import com.gamjamubwatna.audio.infrastructure.external.OdiiApiException;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.Comparator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

@Service
public class AudioGuideService {

    private static final String KOREAN = "ko";

    private final TouristSpotRepository touristSpotRepository;
    private final AudioGuideRepository audioGuideRepository;
    private final OdiiApiClient odiiApiClient;
    private final Clock clock;

    @Autowired
    public AudioGuideService(
        TouristSpotRepository touristSpotRepository,
        AudioGuideRepository audioGuideRepository,
        OdiiApiClient odiiApiClient
    ) {
        this(touristSpotRepository, audioGuideRepository, odiiApiClient, Clock.systemUTC());
    }

    public AudioGuideService(
        TouristSpotRepository touristSpotRepository,
        AudioGuideRepository audioGuideRepository,
        OdiiApiClient odiiApiClient,
        Clock clock
    ) {
        this.touristSpotRepository = touristSpotRepository;
        this.audioGuideRepository = audioGuideRepository;
        this.odiiApiClient = odiiApiClient;
        this.clock = clock;
    }

    public AudioGuideResponse getAudioGuide(Long spotId) {
        TouristSpot spot = touristSpotRepository.findByIdAndActiveTrue(spotId)
            .orElseThrow(() -> new AudioGuideNotFoundException("관광지를 찾을 수 없습니다."));

        return audioGuideRepository.findByTouristSpotIdAndLanguage(spotId, KOREAN)
            .map(AudioGuideResponse::from)
            .orElseGet(() -> fetchAndSave(spot));
    }

    private AudioGuideResponse fetchAndSave(TouristSpot spot) {
        try {
            OdiiStory story = odiiApiClient.searchStories(spot.getName()).stream()
                .filter(this::isKorean)
                .filter(item -> item.audioUrl() != null && !item.audioUrl().isBlank())
                .filter(item -> matchScore(item.title(), spot.getName()) < Integer.MAX_VALUE)
                .min(Comparator.comparingInt(item -> matchScore(item.title(), spot.getName())))
                .orElseThrow(() -> new AudioGuideNotFoundException("이 관광지의 오디오 가이드를 찾을 수 없습니다."));

            AudioGuide audioGuide = new AudioGuide(
                spot,
                required(story.stid(), "이야기 ID"),
                preferredTitle(story),
                story.audioUrl(),
                blankToNull(story.script()),
                null,
                KOREAN,
                Instant.now(clock)
            );
            return saveOrReadConcurrentCache(audioGuide, spot.getId());
        } catch (AudioGuideNotFoundException exception) {
            throw exception;
        } catch (OdiiApiException exception) {
            throw new AudioGuideExternalException("오디오 가이드 제공 서비스에 연결할 수 없습니다.", exception);
        }
    }

    private AudioGuideResponse saveOrReadConcurrentCache(
        AudioGuide audioGuide,
        Long spotId
    ) {
        try {
            return AudioGuideResponse.from(audioGuideRepository.saveAndFlush(audioGuide));
        } catch (DataIntegrityViolationException exception) {
            // 다른 요청이 같은 캐시를 먼저 저장했다면 그 결과를 반환하고 중복 row는 남기지 않는다.
            return audioGuideRepository.findByTouristSpotIdAndLanguage(spotId, KOREAN)
                .map(AudioGuideResponse::from)
                .orElseThrow(() -> exception);
        }
    }

    private boolean isKorean(OdiiStory story) {
        return story.langCode() == null || KOREAN.equalsIgnoreCase(story.langCode());
    }

    private String preferredTitle(OdiiStory story) {
        return story.audioTitle() == null || story.audioTitle().isBlank()
            ? story.title()
            : story.audioTitle();
    }

    private String required(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw new AudioGuideExternalException("오디 API의 %s가 비어 있습니다.".formatted(fieldName));
        }
        return value;
    }

    private int matchScore(String storyTitle, String spotName) {
        String normalizedStoryTitle = normalized(storyTitle);
        String normalizedSpotName = normalized(spotName);
        if (normalizedStoryTitle.isEmpty() || normalizedSpotName.length() < 3) {
            return Integer.MAX_VALUE;
        }
        if (normalizedStoryTitle.equals(normalizedSpotName)) {
            return 0;
        }
        if (normalizedStoryTitle.contains(normalizedSpotName)) {
            return 1;
        }
        if (normalizedSpotName.contains(normalizedStoryTitle)) {
            return 2;
        }
        return Integer.MAX_VALUE;
    }

    private String normalized(String value) {
        if (value == null) {
            return "";
        }
        // Odii는 같은 장터를 "5일장"과 "오일장"처럼 다르게 표기하므로 비교 전에 표기만 통일한다.
        return value
            .replace("5일장", "오일장")
            .replaceAll("[^\\p{L}\\p{N}]", "")
            .toLowerCase();
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }
}
