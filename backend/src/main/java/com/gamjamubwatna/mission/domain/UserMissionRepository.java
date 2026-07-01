package com.gamjamubwatna.mission.domain;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserMissionRepository extends JpaRepository<UserMission, Long> {

    @EntityGraph(attributePaths = "mission")
    List<UserMission> findByUserId(Long userId);

    boolean existsByUserIdAndMissionId(Long userId, Long missionId);

    Optional<UserMission> findByUserIdAndMissionId(Long userId, Long missionId);
}
