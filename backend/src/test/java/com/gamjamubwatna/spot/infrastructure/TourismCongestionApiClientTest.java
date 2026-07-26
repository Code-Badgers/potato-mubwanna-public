package com.gamjamubwatna.spot.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

class TourismCongestionApiClientTest {

    private HttpServer server;

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void fetchesTourismCongestionPredictionsWithOfficialParameters() throws Exception {
        AtomicReference<String> rawQuery = new AtomicReference<>();
        startServer("""
            {
              "response": {
                "header": {"resultCode": "0000", "resultMsg": "OK"},
                "body": {
                  "items": {
                    "item": [
                      {
                        "contentId": "123456",
                        "baseYmd": "20260727",
                        "cnctrRate": "42.7"
                      },
                      {
                        "contentId": "123456",
                        "baseYmd": "20260728",
                        "cnctrRate": "121"
                      }
                    ]
                  }
                }
              }
            }
            """, rawQuery);

        var predictions = client("encoded%2Fservice%2Bkey")
            .fetchPredictions("123456");

        assertThat(predictions).hasSize(2);
        assertThat(predictions.get(0).contentId()).isEqualTo("123456");
        assertThat(predictions.get(0).predictionDate()).isEqualTo(LocalDate.parse("2026-07-27"));
        assertThat(predictions.get(0).concentrationRate()).isEqualTo(43);
        assertThat(rawQuery.get())
            .contains("serviceKey=encoded%2Fservice%2Bkey")
            .contains("MobileOS=ETC")
            .contains("MobileApp=potato-mubwanna")
            .contains("_type=json")
            .contains("contentId=123456")
            .doesNotContain("%252F");
    }

    @Test
    void acceptsSingleItemObjectAndIsoDate() throws Exception {
        startServer("""
            {
              "response": {
                "header": {"resultCode": "00", "resultMsg": "OK"},
                "body": {
                  "items": {
                    "item": {
                      "predictionDate": "2026-07-27",
                      "concentrationRate": 75
                    }
                  }
                }
              }
            }
            """, new AtomicReference<>());

        var predictions = client("service-key").fetchPredictions("fallback-id");

        assertThat(predictions).singleElement().satisfies(prediction -> {
            assertThat(prediction.contentId()).isEqualTo("fallback-id");
            assertThat(prediction.predictionDate()).isEqualTo(LocalDate.parse("2026-07-27"));
            assertThat(prediction.concentrationRate()).isEqualTo(75);
        });
    }

    @Test
    void returnsEmptyListForBlankItemsOrUnusableRows() throws Exception {
        startServer("""
            {
              "response": {
                "header": {"resultCode": "0000", "resultMsg": "OK"},
                "body": {"items": {"item": ""}}
              }
            }
            """, new AtomicReference<>());

        assertThat(client("service-key").fetchPredictions("123456")).isEmpty();
    }

    @Test
    void encodesDecodedServiceKeyAsQueryComponent() throws Exception {
        AtomicReference<String> rawQuery = new AtomicReference<>();
        startServer("""
            {
              "response": {
                "header": {"resultCode": "0000", "resultMsg": "OK"},
                "body": {"items": {"item": []}}
              }
            }
            """, rawQuery);

        client("decoded+service/key==").fetchPredictions("123456");

        assertThat(rawQuery.get())
            .contains("serviceKey=decoded%2Bservice%2Fkey%3D%3D")
            .doesNotContain("serviceKey=decoded+service/key");
    }

    @Test
    void rejectsApiErrorResponse() throws Exception {
        startServer("""
            {
              "response": {
                "header": {"resultCode": "30", "resultMsg": "SERVICE_KEY_IS_NOT_REGISTERED_ERROR"},
                "body": {"items": {"item": []}}
              }
            }
            """, new AtomicReference<>());

        assertThatThrownBy(() -> client("service-key").fetchPredictions("123456"))
            .isInstanceOf(TourismCongestionApiException.class)
            .hasMessageContaining("SERVICE_KEY_IS_NOT_REGISTERED_ERROR");
    }

    @Test
    void rejectsMissingServiceKeyBeforeCallingApi() {
        TourismCongestionApiClient client = new TourismCongestionApiClient(
            RestClient.builder(),
            "https://apis.data.go.kr/B551011/TatsCnctrRateService",
            "/tatsCnctrRateList",
            "",
            "ETC",
            "potato-mubwanna",
            "contentId"
        );

        assertThatThrownBy(() -> client.fetchPredictions("123456"))
            .isInstanceOf(TourismCongestionApiException.class)
            .hasMessageContaining("CONGESTION_API_SERVICE_KEY");
    }

    private TourismCongestionApiClient client(String serviceKey) {
        return new TourismCongestionApiClient(
            RestClient.builder(),
            "http://localhost:%d".formatted(server.getAddress().getPort()),
            "/tatsCnctrRateList",
            serviceKey,
            "ETC",
            "potato-mubwanna",
            "contentId"
        );
    }

    private void startServer(String body, AtomicReference<String> rawQuery) throws IOException {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/tatsCnctrRateList", exchange -> {
            rawQuery.set(exchange.getRequestURI().getRawQuery());
            byte[] response = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json;charset=UTF-8");
            exchange.sendResponseHeaders(200, response.length);
            exchange.getResponseBody().write(response);
            exchange.close();
        });
        server.start();
    }
}
