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
    private final SpotImageResolver spotImageResolver;
    private final SpotTourInfoResolver spotTourInfoResolver;
    private final ExternalPlaceDetailsResolver externalPlaceDetailsResolver;

    public SpotService(
        TouristSpotRepository touristSpotRepository,
        SpotMenuItemRepository spotMenuItemRepository,
        SpotImageResolver spotImageResolver,
        SpotTourInfoResolver spotTourInfoResolver,
        ExternalPlaceDetailsResolver externalPlaceDetailsResolver
    ) {
        this.touristSpotRepository = touristSpotRepository;
        this.spotMenuItemRepository = spotMenuItemRepository;
        this.spotImageResolver = spotImageResolver;
        this.spotTourInfoResolver = spotTourInfoResolver;
        this.externalPlaceDetailsResolver = externalPlaceDetailsResolver;
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
        Map<Long, ExternalPlaceDetails> cachedDetailsBySpotId =
            externalPlaceDetailsResolver.resolveCached(spots);
        return spots.stream()
            .map(spot -> {
                ExternalPlaceDetails externalDetails = cachedDetailsBySpotId.getOrDefault(
                    spot.getId(),
                    ExternalPlaceDetails.empty()
                );
                List<String> imageUrls = resolvedListImageUrls(spot, externalDetails, 3);
                return SpotListResponse.from(
                    spot,
                    imageUrls.isEmpty() ? null : imageUrls.get(0),
                    imageUrls,
                    externalDetails,
                    menuItemsBySpotId.getOrDefault(spot.getId(), List.of())
                );
            })
            .toList();
    }

    private List<String> resolvedListImageUrls(
        TouristSpot spot,
        ExternalPlaceDetails externalDetails,
        int limit
    ) {
        // 목록 조회는 첫 화면을 여는 경로이므로 저장 데이터와 마지막 성공 캐시만 사용한다.
        List<String> imageUrls = new ArrayList<>();
        appendImages(imageUrls, spotImageResolver.resolveStoredImageUrls(spot, limit), limit);
        appendImages(imageUrls, externalDetails.imageUrls(), limit);
        return List.copyOf(imageUrls);
    }

    @Transactional(readOnly = true)
    public SpotDetailResponse getSpot(Long spotId) {
        TouristSpot spot = touristSpotRepository.findByIdAndActiveTrue(spotId)
            .orElseThrow(() -> new IllegalArgumentException("감자 스팟을 찾을 수 없습니다."));
        ExternalPlaceDetails externalDetails = externalPlaceDetailsResolver.resolve(spot);
        List<String> imageUrls = resolvedImageUrls(spot, externalDetails, 3);
        List<SpotMenuItemResponse> menuItems = menuItemsBySpotId(List.of(spot))
            .getOrDefault(spot.getId(), List.of());
        return SpotDetailResponse.from(
            spot,
            imageUrls.isEmpty() ? null : imageUrls.get(0),
            imageUrls,
            spotTourInfoResolver.resolve(spot),
            externalDetails,
            menuItems
        );
    }

    private List<String> resolvedImageUrls(
        TouristSpot spot,
        ExternalPlaceDetails externalDetails,
        int limit
    ) {
        List<String> imageUrls = new ArrayList<>();
        appendImages(imageUrls, spotImageResolver.resolveStoredImageUrls(spot, limit), limit);
        appendImages(imageUrls, externalDetails.imageUrls(), limit);
        appendImages(imageUrls, spotImageResolver.resolveTourApiImageUrls(spot, limit), limit);
        return List.copyOf(imageUrls);
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

    private void appendImages(List<String> target, List<String> source, int limit) {
        if (source == null || source.isEmpty()) {
            return;
        }
        for (String imageUrl : source) {
            if (target.size() >= limit) {
                return;
            }
            if (imageUrl == null || imageUrl.isBlank() || target.contains(imageUrl)) {
                continue;
            }
            target.add(imageUrl);
        }
    }
}
