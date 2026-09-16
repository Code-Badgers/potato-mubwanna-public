package com.gamjamubwatna.spot.infrastructure;

import com.gamjamubwatna.spot.application.TourismCongestionSyncResult;
import com.gamjamubwatna.spot.application.TourismCongestionSyncService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class TourismCongestionSyncRunner implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(TourismCongestionSyncRunner.class);

    private final TourismCongestionSyncService syncService;
    private final boolean syncOnStartup;
    private final boolean syncDaily;

    public TourismCongestionSyncRunner(
        TourismCongestionSyncService syncService,
        @Value("${external.congestion-api.sync-on-startup}") boolean syncOnStartup,
        @Value("${external.congestion-api.sync-daily}") boolean syncDaily
    ) {
        this.syncService = syncService;
        this.syncOnStartup = syncOnStartup;
        this.syncDaily = syncDaily;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!syncOnStartup) {
            return;
        }

        synchronize();
    }

    @Scheduled(
        cron = "${external.congestion-api.sync-cron}", zone = "Asia/Seoul"
    )
    public void runScheduledSync() {
        if (syncDaily) {
            synchronize();
        }
    }

    private void synchronize() {
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
