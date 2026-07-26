package com.gamjamubwatna.spot.infrastructure;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.application.TourismCongestionSyncResult;
import com.gamjamubwatna.spot.application.TourismCongestionSyncService;
import org.junit.jupiter.api.Test;

class TourismCongestionSyncRunnerTest {

    private final TourismCongestionSyncService syncService = mock(TourismCongestionSyncService.class);

    @Test
    void skipsSyncWhenStartupFlagIsDisabled() {
        TourismCongestionSyncRunner runner = new TourismCongestionSyncRunner(syncService, false);

        runner.run(null);

        verify(syncService, never()).syncActiveSpots();
    }

    @Test
    void runsSyncWhenStartupFlagIsEnabled() {
        when(syncService.syncActiveSpots()).thenReturn(new TourismCongestionSyncResult(2, 1, 3, 1));
        TourismCongestionSyncRunner runner = new TourismCongestionSyncRunner(syncService, true);

        runner.run(null);

        verify(syncService).syncActiveSpots();
    }
}
