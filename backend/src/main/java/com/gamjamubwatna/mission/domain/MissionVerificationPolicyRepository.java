package com.gamjamubwatna.mission.domain;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MissionVerificationPolicyRepository
    extends JpaRepository<MissionVerificationPolicy, Long> {

    Optional<MissionVerificationPolicy> findByMissionId(Long missionId);
}
