package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.api.SpotCongestionSyncRequest;
import com.gamjamubwatna.spot.api.SpotCongestionSyncResponse;
import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCongestionPrediction;
import com.gamjamubwatna.spot.domain.SpotCongestionPredictionRepository;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SpotCongestionService {

    private static final String DEFAULT_SOURCE = "TOURISM_CONGESTION_API";

    private final TouristSpotRepository touristSpotRepository;
    private final SpotCongestionPredictionRepository spotCongestionPredictionRepository;
    private final CongestionLevelPolicy congestionLevelPolicy;
    private final Clock clock;

    public SpotCongestionService(
        TouristSpotRepository touristSpotRepository,
        SpotCongestionPredictionRepository spotCongestionPredictionRepository,
        CongestionLevelPolicy congestionLevelPolicy
    ) {
        this(touristSpotRepository, spotCongestionPredictionRepository, congestionLevelPolicy, Clock.systemUTC());
    }

    SpotCongestionService(
        TouristSpotRepository touristSpotRepository,
        SpotCongestionPredictionRepository spotCongestionPredictionRepository,
        CongestionLevelPolicy congestionLevelPolicy,
        Clock clock
    ) {
        this.touristSpotRepository = touristSpotRepository;
        this.spotCongestionPredictionRepository = spotCongestionPredictionRepository;
        this.congestionLevelPolicy = congestionLevelPolicy;
        this.clock = clock;
    }

    @Transactional
    public SpotCongestionSyncResponse syncPrediction(Long spotId, SpotCongestionSyncRequest request) {
        validateRequest(request);
        TouristSpot spot = touristSpotRepository.findByIdAndActiveTrue(spotId)
            .orElseThrow(() -> new SpotCongestionException("감자 스팟을 찾을 수 없습니다."));

        CongestionLevel congestionLevel = congestionLevelPolicy.resolve(
            request.predictedVisitors(),
            request.baselineVisitors()
        );
        Instant now = Instant.now(clock);
        String source = normalizeSource(request.source());

        SpotCongestionPrediction prediction = spotCongestionPredictionRepository
            .findByTouristSpotIdAndPredictionDateAndSource(spotId, request.predictionDate(), source)
            .map(existing -> {
                existing.update(request.predictedVisitors(), request.baselineVisitors(), congestionLevel);
                return existing;
            })
            .orElseGet(() -> new SpotCongestionPrediction(
                spot,
                request.predictionDate(),
                request.predictedVisitors(),
                request.baselineVisitors(),
                congestionLevel,
                source,
                now
            ));

        // 지도 목록은 tourist_spots의 대표 혼잡도만 읽으므로 예측 저장과 현재 노출 값을 함께 갱신한다.
        spot.updateCongestionLevel(congestionLevel, now);
        return SpotCongestionSyncResponse.from(spotCongestionPredictionRepository.save(prediction));
    }

    private void validateRequest(SpotCongestionSyncRequest request) {
        if (request == null || request.predictionDate() == null) {
            throw new SpotCongestionException("혼잡도 예측 날짜를 확인할 수 없습니다.");
        }
        if (request.predictedVisitors() == null || request.predictedVisitors() < 0) {
            throw new SpotCongestionException("예측 방문자 수가 허용 범위를 벗어났습니다.");
        }
        if (request.baselineVisitors() == null || request.baselineVisitors() <= 0) {
            throw new SpotCongestionException("기준 방문자 수가 허용 범위를 벗어났습니다.");
        }
    }

    private String normalizeSource(String source) {
        if (source == null || source.isBlank()) {
            return DEFAULT_SOURCE;
        }
        return source.trim();
    }
}
