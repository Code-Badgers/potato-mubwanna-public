package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.api.SpotRecommendationResponse;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.spot.infrastructure.RelatedTourismApiClient;
import com.gamjamubwatna.spot.infrastructure.RelatedTourismApiClient.RelatedTourismSpot;
import com.gamjamubwatna.spot.infrastructure.RelatedTourismApiException;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

@Service
public class SpotRecommendationService {

    private static final int MAX_RECOMMENDATIONS = 3;

    private final TouristSpotRepository touristSpotRepository;
    private final RelatedTourismApiClient relatedTourismApiClient;
    private final GangwonSignguCodeResolver signguCodeResolver;

    public SpotRecommendationService(
        TouristSpotRepository touristSpotRepository,
        RelatedTourismApiClient relatedTourismApiClient,
        GangwonSignguCodeResolver signguCodeResolver
    ) {
        this.touristSpotRepository = touristSpotRepository;
        this.relatedTourismApiClient = relatedTourismApiClient;
        this.signguCodeResolver = signguCodeResolver;
    }

    public List<SpotRecommendationResponse> getRecommendations(Long spotId) {
        TouristSpot currentSpot = touristSpotRepository.findByIdAndActiveTrue(spotId)
            .orElseThrow(() -> new SpotRecommendationNotFoundException("관광지를 찾을 수 없습니다."));
        String signguCode = signguCodeResolver.resolve(currentSpot.getCityName())
            .orElseThrow(() -> new SpotRecommendationNotFoundException(
                "이 관광지의 강원 시군구 코드를 찾을 수 없습니다."
            ));

        try {
            List<RankedRelatedSpot> rankedSpots = rankedRelatedSpots(currentSpot, signguCode);
            if (rankedSpots.isEmpty()) {
                return List.of();
            }

            Set<String> relatedNames = rankedSpots.stream()
                .map(RankedRelatedSpot::name)
                .collect(Collectors.toSet());
            Map<String, TouristSpot> localSpotsByName = touristSpotRepository
                .findActiveSpotsByNames(relatedNames)
                .stream()
                .filter(spot -> !spot.getId().equals(currentSpot.getId()))
                .collect(Collectors.toMap(
                    TouristSpot::getName,
                    Function.identity(),
                    (first, ignored) -> first,
                    LinkedHashMap::new
                ));

            return rankedSpots.stream()
                .filter(rankedSpot -> localSpotsByName.containsKey(rankedSpot.name()))
                .map(rankedSpot -> SpotRecommendationResponse.from(
                    localSpotsByName.get(rankedSpot.name()),
                    rankedSpot.rank()
                ))
                .limit(MAX_RECOMMENDATIONS)
                .toList();
        } catch (RelatedTourismApiException exception) {
            throw new SpotRecommendationExternalException(
                "연관 관광지 제공 서비스에 연결할 수 없습니다.",
                exception
            );
        }
    }

    private List<RankedRelatedSpot> rankedRelatedSpots(TouristSpot currentSpot, String signguCode) {
        Map<String, Integer> bestRankByName = new LinkedHashMap<>();
        for (RelatedTourismSpot item : relatedTourismApiClient.searchRelatedSpots(
            currentSpot.getName(),
            signguCode
        )) {
            if (!normalized(item.tAtsNm()).equals(normalized(currentSpot.getName()))
                || !signguCode.equals(item.signguCd())) {
                continue;
            }
            String relatedName = trimmed(item.rlteTatsNm());
            Integer rank = positiveInteger(item.rlteRank());
            if (relatedName == null || rank == null) {
                continue;
            }
            bestRankByName.merge(relatedName, rank, Math::min);
        }

        return bestRankByName.entrySet().stream()
            .map(entry -> new RankedRelatedSpot(entry.getKey(), entry.getValue()))
            .sorted(Comparator.comparingInt(RankedRelatedSpot::rank))
            .toList();
    }

    private String normalized(String value) {
        return value == null ? "" : value.trim().replaceAll("\\s+", " ");
    }

    private String trimmed(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private Integer positiveInteger(String value) {
        try {
            int parsed = Integer.parseInt(value);
            return parsed > 0 ? parsed : null;
        } catch (NumberFormatException | NullPointerException exception) {
            return null;
        }
    }

    private record RankedRelatedSpot(String name, int rank) {
    }
}
