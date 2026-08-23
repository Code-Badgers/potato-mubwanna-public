package com.gamjamubwatna.spot.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

class TourApiClientTest {

    private HttpServer server;
    private String lastQuery;

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
    void findsRepresentativeImageFromDetailImage2() {
        server.createContext("/detailImage2", exchange -> {
            lastQuery = exchange.getRequestURI().getRawQuery();
            byte[] body = """
                {
                  "response": {
                    "body": {
                      "items": {
                        "item": [
                          {
                            "originimgurl": "https://tour.example.com/origin.jpg",
                            "smallimageurl": "https://tour.example.com/thumb.jpg"
                          }
                        ]
                      }
                    }
                  }
                }
                """.getBytes(StandardCharsets.UTF_8);
            writeJson(exchange, body);
        });

        assertThat(client("encoded%2Bkey").findRepresentativeImage("12345"))
            .contains("https://tour.example.com/origin.jpg");
        assertThat(lastQuery)
            .contains("serviceKey=encoded%2Bkey")
            .contains("contentId=12345")
            .contains("imageYN=Y")
            .contains("subImageYN=Y");
    }

    @Test
    void fallsBackToSmallImageWhenOriginalImageIsMissing() {
        server.createContext("/detailImage2", exchange -> {
            byte[] body = """
                {
                  "response": {
                    "body": {
                      "items": {
                        "item": {
                          "originimgurl": "",
                          "smallimageurl": "https://tour.example.com/thumb.jpg"
                        }
                      }
                    }
                  }
                }
                """.getBytes(StandardCharsets.UTF_8);
            writeJson(exchange, body);
        });

        assertThat(client("decoded/key").findRepresentativeImage("12345"))
            .contains("https://tour.example.com/thumb.jpg");
    }

    @Test
    void returnsEmptyWhenDetailImage2HasNoImage() {
        server.createContext("/detailImage2", exchange -> {
            byte[] body = """
                {
                  "response": {
                    "body": {
                      "items": ""
                    }
                  }
                }
                """.getBytes(StandardCharsets.UTF_8);
            writeJson(exchange, body);
        });

        assertThat(client("encoded%2Bkey").findRepresentativeImage("12345"))
            .isEmpty();
    }

    private TourApiClient client(String serviceKey) {
        return new TourApiClient(
            RestClient.builder(),
            "http://localhost:%d".formatted(server.getAddress().getPort()),
            "/searchKeyword2",
            "/detailImage2",
            serviceKey,
            "ETC",
            "potato-mubwanna",
            "51",
            "감자"
        );
    }

    private void writeJson(com.sun.net.httpserver.HttpExchange exchange, byte[] body) throws IOException {
        exchange.getResponseHeaders().add("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, body.length);
        exchange.getResponseBody().write(body);
        exchange.close();
    }
}
