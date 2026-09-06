package com.gamjamubwatna.mission.domain;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MissionRepository extends JpaRepository<Mission, Long> {

    @EntityGraph(attributePaths = "targetSpot")
    List<Mission> findAllByOrderByDisplayOrderAsc();

    @Override
    @EntityGraph(attributePaths = "targetSpot")
    Optional<Mission> findById(Long id);

    @EntityGraph(attributePaths = "targetSpot")
    Optional<Mission> findFirstByTargetSpotIdAndActiveTrueOrderByDisplayOrderAsc(Long spotId);

    Optional<Mission> findFirstBySpotNameAndCityNameAndActiveTrueOrderByDisplayOrderAsc(
        String spotName,
        String cityName
    );

    Optional<Mission> findFirstBySpotNameAndActiveTrueOrderByDisplayOrderAsc(String spotName);
}
