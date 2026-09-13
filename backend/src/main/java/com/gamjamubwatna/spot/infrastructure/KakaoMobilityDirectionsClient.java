package com.gamjamubwatna.spot.infrastructure;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.gamjamubwatna.spot.application.SpotRouteEstimateExternalException;
import com.gamjamubwatna.spot.domain.TouristSpot;
import java.net.URI;
import java.time.Duration;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.util.UriComponentsBuilder;

@Component
public class KakaoMobilityDirectionsClient {

    private static final String SOURCE = "KAKAO_MOBILITY";

    private final RestClient restClient;
    private final String directionsUrl;
    private final String restApiKey;

    public KakaoMobilityDirectionsClient(
        RestClient.Builder restClientBuilder,
        @Value("${external.kakao-mobility.directions-url}") String directionsUrl,
        @Value("${external.kakao-mobility.rest-api-key}") String restApiKey
    ) {
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(Duration.ofSeconds(2));
        requestFactory.setReadTimeout(Duration.ofSeconds(4));
        this.restClient = restClientBuilder.clone().requestFactory(requestFactory).build();
        this.directionsUrl = directionsUrl;
        this.restApiKey = restApiKey;
    }

    public RouteEstimate estimate(List<TouristSpot> spots) {
        if (restApiKey == null || restApiKey.isBlank()) {
            throw new SpotRouteEstimateExternalException(
                "KAKAO_REST_API_KEY가 설정되지 않아 차량 이동시간을 계산할 수 없습니다."
            );
        }

        try {
            KakaoDirectionsResponse response = restClient.get()
                .uri(directionsUri(spots))
                .header("Authorization", "KakaoAK %s".formatted(restApiKey))
                .retrieve()
                .body(KakaoDirectionsResponse.class);
            return routeEstimate(response);
        } catch (SpotRouteEstimateExternalException exception) {
            throw exception;
        } catch (RestClientException exception) {
            throw new SpotRouteEstimateExternalException(
                "차량 경로 정보를 불러오지 못했습니다.",
                exception
            );
        }
    }

    private URI directionsUri(List<TouristSpot> spots) {
        TouristSpot origin = spots.getFirst();
        TouristSpot destination = spots.getLast();
        UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(directionsUrl)
            .queryParam("origin", coordinate(origin))
            .queryParam("destination", coordinate(destination))
            .queryParam("priority", "RECOMMEND")
            .queryParam("summary", true);
        if (spots.size() > 2) {
            String waypoints = spots.subList(1, spots.size() - 1).stream()
                .map(this::coordinate)
                .reduce((left, right) -> "%s|%s".formatted(left, right))
                .orElseThrow();
            builder.queryParam("waypoints", waypoints);
        }
        return builder.build().encode().toUri();
    }

    private String coordinate(TouristSpot spot) {
        return "%s,%s".formatted(spot.getLongitude(), spot.getLatitude());
    }

    private RouteEstimate routeEstimate(KakaoDirectionsResponse response) {
        if (response == null || response.routes() == null || response.routes().isEmpty()) {
            throw new SpotRouteEstimateExternalException("검색된 차량 경로가 없습니다.");
        }
        KakaoRoute route = response.routes().getFirst();
        if (route.resultCode() == null || route.resultCode() != 0 || route.summary() == null) {
            throw new SpotRouteEstimateExternalException("검색된 차량 경로가 없습니다.");
        }
        Integer distance = route.summary().distance();
        Integer duration = route.summary().duration();
        if (distance == null || duration == null || distance < 0 || duration < 0) {
            throw new SpotRouteEstimateExternalException("차량 경로 응답이 올바르지 않습니다.");
        }
        return new RouteEstimate(distance, duration, SOURCE);
    }

    public record RouteEstimate(int distanceMeters, int durationSeconds, String source) {
    }

    private record KakaoDirectionsResponse(List<KakaoRoute> routes) {
    }

    private record KakaoRoute(
        @JsonProperty("result_code") Integer resultCode,
        KakaoRouteSummary summary
    ) {
    }

    private record KakaoRouteSummary(Integer distance, Integer duration) {
    }
}
