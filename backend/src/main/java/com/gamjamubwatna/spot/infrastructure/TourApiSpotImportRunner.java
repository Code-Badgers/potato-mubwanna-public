package com.gamjamubwatna.spot.infrastructure;

import com.gamjamubwatna.spot.application.TourApiSpotImportService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class TourApiSpotImportRunner implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(TourApiSpotImportRunner.class);

    private final TourApiSpotImportService importService;
    private final boolean importOnStartup;
    private final int pageSize;
    private final int maxPages;

    public TourApiSpotImportRunner(
        TourApiSpotImportService importService,
        @Value("${external.tour-api.import-on-startup}") boolean importOnStartup,
        @Value("${external.tour-api.import-page-size}") int pageSize,
        @Value("${external.tour-api.import-max-pages}") int maxPages
    ) {
        this.importService = importService;
        this.importOnStartup = importOnStartup;
        this.pageSize = pageSize;
        this.maxPages = maxPages;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!importOnStartup) {
            return;
        }

        try {
            int savedCount = importService.importPotatoSpotPages(maxPages, pageSize);
            log.info("TourAPI potato spot import completed. savedCount={}", savedCount);
        } catch (RuntimeException exception) {
            log.warn("TourAPI potato spot import skipped. reason={}", exception.getMessage());
        }
    }
}
