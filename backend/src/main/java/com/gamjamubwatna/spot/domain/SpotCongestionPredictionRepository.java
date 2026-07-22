package com.gamjamubwatna.spot.domain;

import java.time.LocalDate;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpotCongestionPredictionRepository extends JpaRepository<SpotCongestionPrediction, Long> {

    Optional<SpotCongestionPrediction> findFirstByTouristSpotIdAndPredictionDateLessThanEqualOrderByPredictionDateDesc(
        Long touristSpotId,
        LocalDate predictionDate
    );
}
