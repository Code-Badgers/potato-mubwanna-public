package com.gamjamubwatna.legal.domain;

import java.time.Instant;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LocationUsageLogRepository extends JpaRepository<LocationUsageLog, Long> {

    long deleteByExpiresAtLessThanEqual(Instant expiresAt);
}
