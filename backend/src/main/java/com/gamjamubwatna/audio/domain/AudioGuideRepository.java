package com.gamjamubwatna.audio.domain;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AudioGuideRepository extends JpaRepository<AudioGuide, Long> {

    Optional<AudioGuide> findByTouristSpotIdAndLanguage(Long touristSpotId, String language);
}
