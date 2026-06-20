package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.api.SpotDetailResponse;
import com.gamjamubwatna.spot.api.SpotListResponse;
import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SpotService {

    private final TouristSpotRepository touristSpotRepository;

    public SpotService(TouristSpotRepository touristSpotRepository) {
        this.touristSpotRepository = touristSpotRepository;
    }

    @Transactional(readOnly = true)
    public List<SpotListResponse> getSpots(
        SpotCategory category,
        String cityName,
        CongestionLevel congestionLevel
    ) {
        List<TouristSpot> spots = touristSpotRepository.findActiveSpots(
            category,
            blankToNull(cityName),
            congestionLevel
        );

        return spots.stream()
            .map(SpotListResponse::from)
            .toList();
    }

    @Transactional(readOnly = true)
    public SpotDetailResponse getSpot(Long spotId) {
        TouristSpot spot = touristSpotRepository.findByIdAndActiveTrue(spotId)
            .orElseThrow(() -> new IllegalArgumentException("감자 스팟을 찾을 수 없습니다."));
        return SpotDetailResponse.from(spot);
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }
}
