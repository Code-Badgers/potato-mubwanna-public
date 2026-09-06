package com.gamjamubwatna.audio.infrastructure.external;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

class OdiiApiClientTest {

    private HttpServer server;

    @Test
    void stopsWaitingWhenOdiiDoesNotRespond() throws Exception {
        CountDownLatch release = new CountDownLatch(1);
        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/storySearchList", exchange -> {
            try {
                release.await(10, TimeUnit.SECONDS);
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
            } finally {
                exchange.close();
            }
        });
        server.start();
        try {
            org.junit.jupiter.api.Assertions.assertTimeoutPreemptively(Duration.ofSeconds(6), () ->
                assertThatThrownBy(() -> client("test-key").searchStories("영금정"))
                    .isInstanceOf(OdiiApiException.class)
                    .hasMessage("오디 API 호출에 실패했습니다."));
        } finally {
            release.countDown();
        }
    }

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void searchesKoreanStoriesAndKeepsEncodedServiceKey() throws Exception {
        AtomicReference<String> rawQuery = new AtomicReference<>();
        startServer("""
            {
              "response": {
                "header": {"resultCode": "00", "resultMsg": "NORMAL SERVICE."},
                "body": {
                  "items": {
                    "item": [
                      {
                        "tid": "10",
                        "tlid": "11",
                        "stid": "20",
                        "stlid": "21",
                        "title": "정선 5일장",
                        "audioTitle": "정선 5일장 이야기",
                        "script": "정선 5일장은...",
                        "audioUrl": "https://example.com/audio.mp3",
                        "langCode": "ko"
                      }
                    ]
                  }
                }
              }
            }
            """, rawQuery);

        OdiiApiClient client = client("encoded%2Fservice%2Bkey");

        var stories = client.searchStories("정선 5일장");

        assertThat(stories).singleElement().satisfies(story -> {
            assertThat(story.stid()).isEqualTo("20");
            assertThat(story.audioTitle()).isEqualTo("정선 5일장 이야기");
            assertThat(story.audioUrl()).isEqualTo("https://example.com/audio.mp3");
        });
        assertThat(rawQuery.get())
            .contains("serviceKey=encoded%2Fservice%2Bkey")
            .contains("keyword=%EC%A0%95%EC%84%A0%205%EC%9D%BC%EC%9E%A5")
            .contains("langCode=ko")
            .doesNotContain("%252F");
    }

    @Test
    void encodesDecodedServiceKeyReservedCharacters() throws Exception {
        AtomicReference<String> rawQuery = new AtomicReference<>();
        startServer("""
            {
              "response": {
                "header": {"resultCode": "00", "resultMsg": "NORMAL SERVICE."},
                "body": {"items": {"item": []}}
              }
            }
            """, rawQuery);

        client("decoded/service+key==").searchStories("남이섬");

        assertThat(rawQuery.get())
            .contains("serviceKey=decoded%2Fservice%2Bkey%3D%3D")
            .doesNotContain("serviceKey=decoded/service+key==");
    }

    @Test
    void returnsEmptyListWhenApiUsesEmptyStringForItems() throws Exception {
        startServer("""
            {
              "response": {
                "header": {"resultCode": "0000", "resultMsg": "OK"},
                "body": {"items": "", "numOfRows": 0, "pageNo": 1, "totalCount": 0}
              }
            }
            """, new AtomicReference<>());

        assertThat(client("service-key").searchStories("감자밭")).isEmpty();
    }

    @Test
    void rejectsApiErrorResponse() throws Exception {
        startServer("""
            {
              "response": {
                "header": {"resultCode": "30", "resultMsg": "SERVICE KEY IS NOT REGISTERED ERROR"},
                "body": {"items": {"item": []}}
              }
            }
            """, new AtomicReference<>());

        assertThatThrownBy(() -> client("service-key").searchStories("정선"))
            .isInstanceOf(OdiiApiException.class)
            .hasMessageContaining("SERVICE KEY IS NOT REGISTERED ERROR");
    }

    @Test
    void rejectsMissingServiceKeyBeforeCallingApi() {
        OdiiApiClient client = new OdiiApiClient(
            RestClient.builder(),
            "https://apis.data.go.kr/B551011/Odii",
            "/storySearchList",
            "",
            "ETC",
            "potato-mubwanna",
            "ko"
        );

        assertThatThrownBy(() -> client.searchStories("정선"))
            .isInstanceOf(OdiiApiException.class)
            .hasMessageContaining("ODII_API_SERVICE_KEY");
    }

    private OdiiApiClient client(String serviceKey) {
        return new OdiiApiClient(
            RestClient.builder(),
            "http://localhost:%d".formatted(server.getAddress().getPort()),
            "/storySearchList",
            serviceKey,
            "ETC",
            "potato-mubwanna",
            "ko"
        );
    }

    private void startServer(String body, AtomicReference<String> rawQuery) throws IOException {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/storySearchList", exchange -> {
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
