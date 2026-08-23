package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.time.Instant;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SpotImageCacheWriter {

    private final TouristSpotRepository touristSpotRepository;

    public SpotImageCacheWriter(TouristSpotRepository touristSpotRepository) {
        this.touristSpotRepository = touristSpotRepository;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void cacheResolvedImage(Long spotId, String imageUrl) {
        if (spotId == null || imageUrl == null || imageUrl.isBlank()) {
            return;
        }
        touristSpotRepository.findById(spotId)
            .ifPresent(spot -> cacheIfMissing(spot, imageUrl));
    }

    private void cacheIfMissing(TouristSpot spot, String imageUrl) {
        spot.cacheImageUrl(imageUrl, Instant.now());
    }
}
