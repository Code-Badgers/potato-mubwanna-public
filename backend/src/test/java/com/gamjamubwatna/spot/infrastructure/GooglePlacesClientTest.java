package com.gamjamubwatna.spot.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamjamubwatna.spot.application.ExternalPlaceDetails;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

class GooglePlacesClientTest {

    private HttpServer server;
    private String lastFieldMask;
    private String lastApiKey;
    private String lastTextSearchBody;

    @BeforeEach
    void setUp() throws IOException {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.start();
    }

    @AfterEach
    void tearDown() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void searchesTextWithKoreanLanguageRegionAndFieldMask() {
        server.createContext("/places:searchText", exchange -> {
            lastFieldMask = exchange.getRequestHeaders().getFirst("X-Goog-FieldMask");
            lastApiKey = exchange.getRequestHeaders().getFirst("X-Goog-Api-Key");
            lastTextSearchBody = new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            writeJson(exchange, """
                {
                  "places": [
                    {
                      "id": "google-place-id",
                      "displayName": {"text": "토지옹심이 원주"},
                      "formattedAddress": "강원특별자치도 원주시 감자길 1",
                      "location": {"latitude": 37.9, "longitude": 127.7}
                    }
                  ]
                }
                """);
        });

        assertThat(client().searchText("토지옹심이 원주"))
            .hasSize(1)
            .first()
            .satisfies(result -> {
                assertThat(result.placeId()).isEqualTo("google-place-id");
                assertThat(result.name()).isEqualTo("토지옹심이 원주");
            });
        assertThat(lastApiKey).isEqualTo("test-google-key");
        assertThat(lastFieldMask).contains("places.id").doesNotContain("*");
        assertThat(lastTextSearchBody)
            .contains("\"textQuery\"")
            .contains("\"토지옹심이 원주\"")
            .contains("\"languageCode\"")
            .contains("\"ko\"")
            .contains("\"regionCode\"")
            .contains("\"KR\"");
    }

    @Test
    void readsPlaceDetailsOpeningHoursAndPhotoUri() {
        server.createContext("/places/google-place-id", exchange -> {
            lastFieldMask = exchange.getRequestHeaders().getFirst("X-Goog-FieldMask");
            writeJson(exchange, """
                {
                  "id": "google-place-id",
                  "nationalPhoneNumber": "033-000-0000",
                  "websiteUri": "https://example.com",
                  "rating": 4.3,
                  "currentOpeningHours": {
                    "openNow": true,
                    "weekdayDescriptions": [
                      "월요일: 오전 10:00~오후 8:00",
                      "화요일: 오전 10:00~오후 8:00",
                      "수요일: 오전 10:00~오후 8:00",
                      "목요일: 오전 10:00~오후 8:00",
                      "금요일: 오전 10:00~오후 8:00",
                      "토요일: 오전 10:00~오후 8:00",
                      "일요일: 오전 10:00~오후 6:00"
                    ]
                  },
                  "photos": [
                    {"name": "places/google-place-id/photos/photo-1"}
                  ]
                }
                """);
        });
        server.createContext("/places/google-place-id/photos/photo-1/media", exchange -> {
            writeJson(exchange, """
                {
                  "photoUri": "https://lh3.googleusercontent.com/photo.jpg"
                }
                """);
        });

        Optional<ExternalPlaceDetails> details = client().findDetails("google-place-id");

        assertThat(details).isPresent();
        assertThat(details.get().phone()).isEqualTo("033-000-0000");
        assertThat(details.get().website()).isEqualTo("https://example.com");
        assertThat(details.get().rating()).isEqualTo(4.3);
        assertThat(details.get().openingHours().openNow()).isTrue();
        assertThat(details.get().openingHours().weekdayDescriptions()).hasSize(7);
        assertThat(details.get().imageUrls()).containsExactly("https://lh3.googleusercontent.com/photo.jpg");
        assertThat(lastFieldMask)
            .contains("regularOpeningHours")
            .contains("currentOpeningHours")
            .contains("photos")
            .doesNotContain("*");
    }

    private GooglePlacesClient client() {
        return new GooglePlacesClient(
            RestClient.builder(),
            "http://localhost:%d".formatted(server.getAddress().getPort()),
            "test-google-key",
            "ko",
            "KR",
            3
        );
    }

    private void writeJson(HttpExchange exchange, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        writeJson(exchange, bytes);
    }

    private void writeJson(HttpExchange exchange, byte[] body) throws IOException {
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, body.length);
        exchange.getResponseBody().write(body);
        exchange.close();
    }
}
