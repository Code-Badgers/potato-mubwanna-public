package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.api.SpotDetailResponse;
import com.gamjamubwatna.spot.api.SpotListResponse;
import com.gamjamubwatna.spot.api.SpotMenuItemResponse;
import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.SpotMenuItem;
import com.gamjamubwatna.spot.domain.SpotMenuItemRepository;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SpotService {

    private final TouristSpotRepository touristSpotRepository;
    private final SpotMenuItemRepository spotMenuItemRepository;

    public SpotService(
        TouristSpotRepository touristSpotRepository,
        SpotMenuItemRepository spotMenuItemRepository
    ) {
        this.touristSpotRepository = touristSpotRepository;
        this.spotMenuItemRepository = spotMenuItemRepository;
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

        Map<Long, List<SpotMenuItemResponse>> menuItemsBySpotId = menuItemsBySpotId(spots);
        return spots.stream()
            .map(spot -> SpotListResponse.from(
                spot,
                menuItemsBySpotId.getOrDefault(spot.getId(), List.of())
            ))
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

    private Map<Long, List<SpotMenuItemResponse>> menuItemsBySpotId(
        List<TouristSpot> spots
    ) {
        if (spots.isEmpty()) {
            return Map.of();
        }
        List<Long> spotIds = spots.stream().map(TouristSpot::getId).toList();
        Map<Long, List<SpotMenuItemResponse>> menuItemsBySpotId = new HashMap<>();
        for (SpotMenuItem item : spotMenuItemRepository.findActiveByTouristSpotIds(spotIds)) {
            List<SpotMenuItemResponse> menuItems = menuItemsBySpotId.computeIfAbsent(
                item.getTouristSpotId(),
                ignored -> new ArrayList<>()
            );
            // 지도 카드가 과도하게 커지지 않도록 정렬된 대표 메뉴 세 개만 노출한다.
            if (menuItems.size() < 3) {
                menuItems.add(SpotMenuItemResponse.from(item));
            }
        }
        return menuItemsBySpotId;
    }
}
