package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import com.gamjamubwatna.spot.infrastructure.TourApiClient.TourApiSpotItem;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TourApiSpotImportService {

    private final TourApiClient tourApiClient;
    private final PotatoSpotClassifier potatoSpotClassifier;
    private final TouristSpotRepository touristSpotRepository;
    private final Clock clock;

    @Autowired
    public TourApiSpotImportService(
        TourApiClient tourApiClient,
        PotatoSpotClassifier potatoSpotClassifier,
        TouristSpotRepository touristSpotRepository
    ) {
        this(tourApiClient, potatoSpotClassifier, touristSpotRepository, Clock.systemUTC());
    }

    public TourApiSpotImportService(
        TourApiClient tourApiClient,
        PotatoSpotClassifier potatoSpotClassifier,
        TouristSpotRepository touristSpotRepository,
        Clock clock
    ) {
        this.tourApiClient = tourApiClient;
        this.potatoSpotClassifier = potatoSpotClassifier;
        this.touristSpotRepository = touristSpotRepository;
        this.clock = clock;
    }

    @Transactional
    public int importPotatoSpots(int pageNo, int numOfRows) {
        List<TourApiSpotItem> items = tourApiClient.searchPotatoSpots(pageNo, numOfRows);
        int savedCount = 0;
        for (TourApiSpotItem item : items) {
            if (isMissingRequiredCoordinate(item)) {
                continue;
            }
            savedCount += upsert(item);
        }
        return savedCount;
    }

    @Transactional
    public int importPotatoSpotPages(int maxPages, int numOfRows) {
        int totalSavedCount = 0;
        for (int pageNo = 1; pageNo <= maxPages; pageNo++) {
            totalSavedCount += importPotatoSpots(pageNo, numOfRows);
        }
        return totalSavedCount;
    }

    private int upsert(TourApiSpotItem item) {
        return potatoSpotClassifier.classifyKeywordSearchResult(
                item.contentTypeId(),
                item.title(),
                item.address()
            )
            .map(classification -> {
                Instant now = Instant.now(clock);
                touristSpotRepository.findByContentId(item.contentId())
                    .ifPresentOrElse(
                        spot -> spot.updateFromTourApi(
                            item.title(),
                            classification.category(),
                            item.latitude(),
                            item.longitude(),
                            item.address(),
                            extractCityName(item.address()),
                            blankToNull(item.imageUrl()),
                            classification.tags(),
                            now
                        ),
                        () -> touristSpotRepository.save(new TouristSpot(
                            item.contentId(),
                            item.contentTypeId(),
                            item.title(),
                            classification.category(),
                            item.latitude(),
                            item.longitude(),
                            item.address(),
                            extractCityName(item.address()),
                            blankToNull(item.imageUrl()),
                            classification.tags(),
                            now
                        ))
                    );
                return 1;
            })
            .orElse(0);
    }

    private boolean isMissingRequiredCoordinate(TourApiSpotItem item) {
        return item.contentId() == null || item.contentId().isBlank()
            || item.contentTypeId() == null
            || item.title() == null || item.title().isBlank()
            || item.latitude() == null
            || item.longitude() == null;
    }

    private String extractCityName(String address) {
        if (address == null || address.isBlank()) {
            return null;
        }

        String[] parts = address.split("\\s+");
        if (parts.length < 2) {
            return parts[0];
        }
        return parts[1];
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }
}
