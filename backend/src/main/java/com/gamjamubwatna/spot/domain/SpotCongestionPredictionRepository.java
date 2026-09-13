package com.gamjamubwatna.spot.domain;

import java.time.LocalDate;
import java.util.Optional;
import java.util.List;
import java.util.Collection;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpotCongestionPredictionRepository extends JpaRepository<SpotCongestionPrediction, Long> {

    @Query("""
        select prediction from SpotCongestionPrediction prediction
        join fetch prediction.touristSpot spot
        where spot.id in :spotIds and prediction.predictionDate = :today
        order by prediction.createdAt desc, prediction.id desc
        """)
    List<SpotCongestionPrediction> findTodayPredictions(
        @Param("spotIds") Collection<Long> spotIds,
        @Param("today") LocalDate today
    );

    Optional<SpotCongestionPrediction> findByTouristSpotIdAndPredictionDateAndSource(
        Long touristSpotId,
        LocalDate predictionDate,
        String source
    );

    Optional<SpotCongestionPrediction> findFirstByTouristSpotIdAndPredictionDateLessThanEqualOrderByPredictionDateDesc(
        Long touristSpotId,
        LocalDate predictionDate
    );
}
