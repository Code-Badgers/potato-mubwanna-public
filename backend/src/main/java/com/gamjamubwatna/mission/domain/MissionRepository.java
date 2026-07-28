package com.gamjamubwatna.mission.domain;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MissionRepository extends JpaRepository<Mission, Long> {

    List<Mission> findAllByOrderByDisplayOrderAsc();

    Optional<Mission> findFirstBySpotNameAndCityNameAndActiveTrueOrderByDisplayOrderAsc(
        String spotName,
        String cityName
    );

    Optional<Mission> findFirstBySpotNameAndActiveTrueOrderByDisplayOrderAsc(String spotName);
}
