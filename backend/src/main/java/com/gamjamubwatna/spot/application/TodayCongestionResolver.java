package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.SpotCongestionPrediction;
import com.gamjamubwatna.spot.domain.SpotCongestionPredictionRepository;
import com.gamjamubwatna.spot.domain.TouristSpot;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class TodayCongestionResolver {
    private static final ZoneId KOREA = ZoneId.of("Asia/Seoul");
    private final SpotCongestionPredictionRepository repository;
    private final Clock clock;

    @Autowired
    public TodayCongestionResolver(SpotCongestionPredictionRepository repository) {
        this(repository, Clock.systemUTC());
    }

    TodayCongestionResolver(SpotCongestionPredictionRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    public Map<Long, SpotCongestionPrediction> resolve(List<TouristSpot> spots) {
        if (spots.isEmpty()) return Map.of();
        LocalDate today = LocalDate.now(clock.withZone(KOREA));
        Map<Long, SpotCongestionPrediction> predictions = new HashMap<>();
        // 대표 혼잡도나 과거 예측을 오늘 정보로 재사용하지 않고 목록 전체를 한 번에 조회한다.
        for (SpotCongestionPrediction prediction : repository.findTodayPredictions(
            spots.stream().map(TouristSpot::getId).toList(), today
        )) {
            if (today.equals(prediction.getPredictionDate())) {
                predictions.putIfAbsent(prediction.getTouristSpot().getId(), prediction);
            }
        }
        return predictions;
    }
}
