package com.gamjamubwatna.spot.domain;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TouristSpotRepository extends JpaRepository<TouristSpot, Long> {

    Optional<TouristSpot> findByContentId(String contentId);

    Optional<TouristSpot> findByNameAndAddress(String name, String address);

    Optional<TouristSpot> findByIdAndActiveTrue(Long id);

    @Query("""
        SELECT spot
        FROM TouristSpot spot
        WHERE spot.active = true
          AND spot.name IN :names
        ORDER BY spot.id ASC
        """)
    List<TouristSpot> findActiveSpotsByNames(@Param("names") Set<String> names);

    @Query("""
        SELECT spot
        FROM TouristSpot spot
        WHERE spot.active = true
          AND (:category IS NULL OR spot.category = :category)
          AND (:cityName IS NULL OR spot.cityName = :cityName)
          AND (:congestionLevel IS NULL OR spot.congestionLevel = :congestionLevel)
        ORDER BY spot.id DESC
        """)
    List<TouristSpot> findActiveSpots(
        @Param("category") SpotCategory category,
        @Param("cityName") String cityName,
        @Param("congestionLevel") CongestionLevel congestionLevel
    );
}
