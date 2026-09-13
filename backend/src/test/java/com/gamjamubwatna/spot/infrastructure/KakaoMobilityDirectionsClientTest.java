package com.gamjamubwatna.spot.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.application.SpotRouteEstimateExternalException;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.math.BigDecimal;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

class KakaoMobilityDirectionsClientTest {

    private HttpServer server;

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void requestsRecommendedRoadRouteInSpotOrder() throws Exception {
        AtomicReference<String> query = new AtomicReference<>();
        AtomicReference<String> authorization = new AtomicReference<>();
        startServer("""
            {
              "routes": [{
                "result_code": 0,
                "summary": {"distance": 18400, "duration": 2760}
              }]
            }
            """, query, authorization);

        KakaoMobilityDirectionsClient.RouteEstimate estimate = client("test-key").estimate(List.of(
            spot("128.6609000", "37.3801000"),
            spot("128.9000000", "37.7600000"),
            spot("128.9500000", "37.7700000")
        ));

        assertThat(estimate.distanceMeters()).isEqualTo(18400);
        assertThat(estimate.durationSeconds()).isEqualTo(2760);
        assertThat(estimate.source()).isEqualTo("KAKAO_MOBILITY");
        assertThat(authorization.get()).isEqualTo("KakaoAK test-key");
        assertThat(query.get())
            .contains("origin=128.6609000,37.3801000")
            .contains("destination=128.9500000,37.7700000")
            .contains("waypoints=128.9000000,37.7600000")
            .contains("priority=RECOMMEND")
            .contains("summary=true");
    }

    @Test
    void rejectsMissingApiKeyWithoutCallingServer() {
        assertThatThrownBy(() -> client("").estimate(List.of(
            spot("128.6609000", "37.3801000"),
            spot("128.9500000", "37.7700000")
        )))
            .isInstanceOf(SpotRouteEstimateExternalException.class)
            .hasMessageContaining("KAKAO_REST_API_KEY");
    }

    @Test
    void rejectsRouteFailureResponse() throws Exception {
        startServer("""
            {"routes": [{"result_code": 104, "result_msg": "경로를 찾을 수 없음"}]}
            """, new AtomicReference<>(), new AtomicReference<>());

        assertThatThrownBy(() -> client("test-key").estimate(List.of(
            spot("128.6609000", "37.3801000"),
            spot("128.9500000", "37.7700000")
        )))
            .isInstanceOf(SpotRouteEstimateExternalException.class)
            .hasMessageContaining("검색된 차량 경로가 없습니다");
    }

    private KakaoMobilityDirectionsClient client(String apiKey) {
        String url = server == null
            ? "http://localhost:1/v1/directions"
            : "http://localhost:%d/v1/directions".formatted(server.getAddress().getPort());
        return new KakaoMobilityDirectionsClient(RestClient.builder(), url, apiKey);
    }

    private TouristSpot spot(String longitude, String latitude) {
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getLongitude()).thenReturn(new BigDecimal(longitude));
        when(spot.getLatitude()).thenReturn(new BigDecimal(latitude));
        return spot;
    }

    private void startServer(
        String body,
        AtomicReference<String> query,
        AtomicReference<String> authorization
    ) throws IOException {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/v1/directions", exchange -> {
            query.set(exchange.getRequestURI().getRawQuery());
            authorization.set(exchange.getRequestHeaders().getFirst("Authorization"));
            byte[] response = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json;charset=UTF-8");
            exchange.sendResponseHeaders(200, response.length);
            exchange.getResponseBody().write(response);
            exchange.close();
        });
        server.start();
    }
}
