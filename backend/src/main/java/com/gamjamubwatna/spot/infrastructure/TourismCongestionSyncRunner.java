package com.gamjamubwatna.spot.infrastructure;

import com.gamjamubwatna.spot.application.TourismCongestionSyncResult;
import com.gamjamubwatna.spot.application.TourismCongestionSyncService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class TourismCongestionSyncRunner implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(TourismCongestionSyncRunner.class);

    private final TourismCongestionSyncService syncService;
    private final boolean syncOnStartup;

    public TourismCongestionSyncRunner(
        TourismCongestionSyncService syncService,
        @Value("${external.congestion-api.sync-on-startup}") boolean syncOnStartup
    ) {
        this.syncService = syncService;
        this.syncOnStartup = syncOnStartup;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!syncOnStartup) {
            return;
        }

        try {
            TourismCongestionSyncResult result = syncService.syncActiveSpots();
            log.info(
                "Tourism congestion sync completed. targetSpotCount={}, syncedSpotCount={}, savedPredictionCount={}, failedSpotCount={}",
                result.targetSpotCount(),
                result.syncedSpotCount(),
                result.savedPredictionCount(),
                result.failedSpotCount()
            );
        } catch (RuntimeException exception) {
            log.warn("Tourism congestion sync skipped. reason={}", exception.getMessage());
        }
    }
}
