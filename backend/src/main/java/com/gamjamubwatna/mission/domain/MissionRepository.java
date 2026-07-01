package com.gamjamubwatna.mission.domain;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MissionRepository extends JpaRepository<Mission, Long> {

    List<Mission> findAllByOrderByDisplayOrderAsc();
}
