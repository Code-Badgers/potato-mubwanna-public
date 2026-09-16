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
import java.util.Set;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class HistoricalCongestionReferenceResolver {
    private static final ZoneId KOREA = ZoneId.of("Asia/Seoul");
    private final SpotCongestionPredictionRepository repository;
    private final Clock clock;

    @Autowired
    public HistoricalCongestionReferenceResolver(SpotCongestionPredictionRepository repository) {
        this(repository, Clock.systemUTC());
    }

    HistoricalCongestionReferenceResolver(SpotCongestionPredictionRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    public Map<Long, SpotCongestionPrediction> resolve(
        List<TouristSpot> spots, Set<Long> spotsWithTodayPrediction
    ) {
        List<Long> missingSpotIds = spots.stream().map(TouristSpot::getId)
            .filter(id -> !spotsWithTodayPrediction.contains(id)).toList();
        if (missingSpotIds.isEmpty()) return Map.of();

        LocalDate today = LocalDate.now(clock.withZone(KOREA));
        LocalDate yesterday = today.minusDays(1);
        LocalDate sameWeekdayLastWeek = today.minusDays(7);
        Map<Long, SpotCongestionPrediction> references = new HashMap<>();
        // 날짜 우선 정렬된 저장 예측만 참고한다. 과거 실측이나 오늘 예측으로 해석하지 않는다.
        for (SpotCongestionPrediction prediction : repository.findReferencePredictions(
            missingSpotIds, List.of(yesterday, sameWeekdayLastWeek)
        )) {
            if ((yesterday.equals(prediction.getPredictionDate())
                || sameWeekdayLastWeek.equals(prediction.getPredictionDate()))
                && missingSpotIds.contains(prediction.getTouristSpot().getId())) {
                references.merge(prediction.getTouristSpot().getId(), prediction,
                    (stored, candidate) -> candidate.getPredictionDate().isAfter(stored.getPredictionDate())
                        ? candidate : stored);
            }
        }
        return references;
    }
}
