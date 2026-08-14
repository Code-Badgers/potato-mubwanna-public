package com.gamjamubwatna.legal.application;

import com.gamjamubwatna.legal.domain.LocationUsageLog;
import com.gamjamubwatna.legal.domain.LocationUsageLogRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LocationUsageLogService {

    private final LocationUsageLogRepository repository;
    private final Clock clock;

    @Autowired
    public LocationUsageLogService(LocationUsageLogRepository repository) {
        this(repository, Clock.systemUTC());
    }

    LocationUsageLogService(LocationUsageLogRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordVisitVerification(Long userId, Instant usedAt, boolean accepted) {
        Instant expiresAt = usedAt.atZone(ZoneOffset.UTC).plusMonths(6).toInstant();
        repository.save(new LocationUsageLog(
            userId,
            usedAt,
            accepted ? "SUCCEEDED" : "REJECTED",
            expiresAt
        ));
    }

    @Scheduled(cron = "${legal.audit.location-log-purge-cron:0 15 3 * * *}")
    @Transactional
    public void purgeExpired() {
        repository.deleteByExpiresAtLessThanEqual(Instant.now(clock));
    }
}
