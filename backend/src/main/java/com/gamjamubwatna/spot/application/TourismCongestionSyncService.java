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
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
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
    private static final ZoneId KOREA = ZoneId.of("Asia/Seoul");
    // 한국관광공사 집중률 API는 TourAPI contentId가 아닌 강원도 5자리 시군구 코드를 받는다.
    private static final Map<String, String> GANGWON_DISTRICT_CODES = Map.ofEntries(
        Map.entry("춘천시", "51110"), Map.entry("원주시", "51130"),
        Map.entry("강릉시", "51150"), Map.entry("동해시", "51170"),
        Map.entry("태백시", "51190"), Map.entry("속초시", "51210"),
        Map.entry("삼척시", "51230"), Map.entry("홍천군", "51720"),
        Map.entry("횡성군", "51730"), Map.entry("영월군", "51750"),
        Map.entry("평창군", "51760"), Map.entry("정선군", "51770"),
        Map.entry("철원군", "51780"), Map.entry("화천군", "51790"),
        Map.entry("양구군", "51800"), Map.entry("인제군", "51810"),
        Map.entry("고성군", "51820"), Map.entry("양양군", "51830")
    );

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
        List<TouristSpot> spots = touristSpotRepository.findAllByActiveTrueOrderByIdAsc();
        if (!spots.isEmpty()) {
            // 키가 없으면 장소마다 실패를 반복하지 않고 수집 시작 전에 한 번만 알린다.
            tourismCongestionApiClient.validateConfiguration();
        }
        int syncedSpotCount = 0;
        int savedPredictionCount = 0;
        int failedSpotCount = 0;

        for (TouristSpot spot : spots) {
            String districtCode = GANGWON_DISTRICT_CODES.get(spot.getCityName());
            if (districtCode == null) {
                continue;
            }
            try {
                List<TourismCongestionPrediction> predictions =
                    tourismCongestionApiClient.fetchPredictions(districtCode, spot.getName());
                if (predictions.isEmpty()) {
                    continue;
                }
                savedPredictionCount += upsertPredictions(spot, predictions);
                updateRepresentativeCongestion(spot, predictions);
                syncedSpotCount++;
            } catch (TourismCongestionApiException exception) {
                failedSpotCount++;
                log.warn(
                    "관광지 혼잡도 예측 수집 실패: spotId={}, cityName={}, message={}",
                    spot.getId(),
                    spot.getCityName(),
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
        // 실행 환경의 시스템 날짜가 아니라 주입된 Clock을 기준으로 예측 시점을 선택한다.
        LocalDate today = LocalDate.now(clock.withZone(KOREA));
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
