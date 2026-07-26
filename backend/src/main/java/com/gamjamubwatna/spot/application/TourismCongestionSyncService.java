package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCongestionPrediction;
import com.gamjamubwatna.spot.domain.SpotCongestionPredictionRepository;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.spot.infrastructure.TourismCongestionApiClient;
import com.gamjamubwatna.spot.infrastructure.TourismCongestionApiClient.TourismCongestionPrediction;
import com.gamjamubwatna.spot.infrastructure.TourismCongestionApiException;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TourismCongestionSyncService {

    private static final Logger log = LoggerFactory.getLogger(TourismCongestionSyncService.class);
    private static final String SOURCE = "TOURISM_CONGESTION_API";
    private static final int BASELINE_CONCENTRATION_RATE = 100;

    private final TouristSpotRepository touristSpotRepository;
    private final SpotCongestionPredictionRepository spotCongestionPredictionRepository;
    private final TourismCongestionApiClient tourismCongestionApiClient;
    private final CongestionLevelPolicy congestionLevelPolicy;
    private final Clock clock;

    @Autowired
    public TourismCongestionSyncService(
        TouristSpotRepository touristSpotRepository,
        SpotCongestionPredictionRepository spotCongestionPredictionRepository,
        TourismCongestionApiClient tourismCongestionApiClient,
        CongestionLevelPolicy congestionLevelPolicy
    ) {
        this(
            touristSpotRepository,
            spotCongestionPredictionRepository,
            tourismCongestionApiClient,
            congestionLevelPolicy,
            Clock.systemDefaultZone()
        );
    }

    TourismCongestionSyncService(
        TouristSpotRepository touristSpotRepository,
        SpotCongestionPredictionRepository spotCongestionPredictionRepository,
        TourismCongestionApiClient tourismCongestionApiClient,
        CongestionLevelPolicy congestionLevelPolicy,
        Clock clock
    ) {
        this.touristSpotRepository = touristSpotRepository;
        this.spotCongestionPredictionRepository = spotCongestionPredictionRepository;
        this.tourismCongestionApiClient = tourismCongestionApiClient;
        this.congestionLevelPolicy = congestionLevelPolicy;
        this.clock = clock;
    }

    @Transactional
    public TourismCongestionSyncResult syncActiveSpots() {
        List<TouristSpot> spots = touristSpotRepository.findActiveSpotsWithContentId();
        int syncedSpotCount = 0;
        int savedPredictionCount = 0;
        int failedSpotCount = 0;

        for (TouristSpot spot : spots) {
            try {
                List<TourismCongestionPrediction> predictions =
                    tourismCongestionApiClient.fetchPredictions(spot.getContentId());
                if (predictions.isEmpty()) {
                    continue;
                }
                savedPredictionCount += upsertPredictions(spot, predictions);
                updateRepresentativeCongestion(spot, predictions);
                syncedSpotCount++;
            } catch (TourismCongestionApiException exception) {
                failedSpotCount++;
                log.warn(
                    "관광지 혼잡도 예측 수집 실패: spotId={}, contentId={}, message={}",
                    spot.getId(),
                    spot.getContentId(),
                    exception.getMessage()
                );
            }
        }

        return new TourismCongestionSyncResult(
            spots.size(),
            syncedSpotCount,
            savedPredictionCount,
            failedSpotCount
        );
    }

    private int upsertPredictions(TouristSpot spot, List<TourismCongestionPrediction> predictions) {
        int savedCount = 0;
        Instant now = Instant.now(clock);
        for (TourismCongestionPrediction prediction : predictions) {
            CongestionLevel congestionLevel = congestionLevel(prediction);
            SpotCongestionPrediction entity = spotCongestionPredictionRepository
                .findByTouristSpotIdAndPredictionDateAndSource(
                    spot.getId(),
                    prediction.predictionDate(),
                    SOURCE
                )
                .map(existing -> {
                    existing.update(
                        prediction.concentrationRate(),
                        BASELINE_CONCENTRATION_RATE,
                        congestionLevel
                    );
                    return existing;
                })
                .orElseGet(() -> new SpotCongestionPrediction(
                    spot,
                    prediction.predictionDate(),
                    prediction.concentrationRate(),
                    BASELINE_CONCENTRATION_RATE,
                    congestionLevel,
                    SOURCE,
                    now
                ));
            spotCongestionPredictionRepository.save(entity);
            savedCount++;
        }
        return savedCount;
    }

    private void updateRepresentativeCongestion(
        TouristSpot spot,
        List<TourismCongestionPrediction> predictions
    ) {
        LocalDate today = LocalDate.now(clock.getZone());
        predictions.stream()
            .filter(prediction -> !prediction.predictionDate().isBefore(today))
            .min(Comparator.comparing(TourismCongestionPrediction::predictionDate))
            .or(() -> predictions.stream().min(Comparator.comparing(TourismCongestionPrediction::predictionDate)))
            .ifPresent(prediction -> spot.updateCongestionLevel(congestionLevel(prediction), Instant.now(clock)));
    }

    private CongestionLevel congestionLevel(TourismCongestionPrediction prediction) {
        return congestionLevelPolicy.resolve(
            prediction.concentrationRate(),
            BASELINE_CONCENTRATION_RATE
        );
    }
}
