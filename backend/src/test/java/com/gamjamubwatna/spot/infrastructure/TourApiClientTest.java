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
        emptyDetailCommon();
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
    void findsRepresentativeImagesFromCommonAndDetailImage2() {
        server.createContext("/detailCommon2", exchange -> {
            byte[] body = """
                {
                  "response": {
                    "body": {
                      "items": {
                        "item": {
                          "firstimage": "https://tour.example.com/first.jpg",
                          "firstimage2": "https://tour.example.com/first-thumb.jpg"
                        }
                      }
                    }
                  }
                }
                """.getBytes(StandardCharsets.UTF_8);
            writeJson(exchange, body);
        });
        server.createContext("/detailImage2", exchange -> {
            byte[] body = """
                {
                  "response": {
                    "body": {
                      "items": {
                        "item": [
                          {
                            "originimgurl": "https://tour.example.com/detail-1.jpg",
                            "smallimageurl": "https://tour.example.com/detail-thumb.jpg"
                          },
                          {
                            "originimgurl": "https://tour.example.com/detail-2.jpg"
                          }
                        ]
                      }
                    }
                  }
                }
                """.getBytes(StandardCharsets.UTF_8);
            writeJson(exchange, body);
        });

        assertThat(client("encoded%2Bkey").findRepresentativeImages("12345", 3))
            .containsExactly(
                "https://tour.example.com/first.jpg",
                "https://tour.example.com/first-thumb.jpg",
                "https://tour.example.com/detail-1.jpg"
            );
    }

    @Test
    void prefersRepresentativeImageFromDetailCommon2() {
        server.createContext("/detailCommon2", exchange -> {
            lastQuery = exchange.getRequestURI().getRawQuery();
            byte[] body = """
                {
                  "response": {
                    "body": {
                      "items": {
                        "item": {
                          "firstimage": "https://tour.example.com/first.jpg",
                          "firstimage2": "https://tour.example.com/first-thumb.jpg"
                        }
                      }
                    }
                  }
                }
                """.getBytes(StandardCharsets.UTF_8);
            writeJson(exchange, body);
        });

        assertThat(client("encoded%2Bkey").findRepresentativeImage("12345"))
            .contains("https://tour.example.com/first.jpg");
        assertThat(lastQuery)
            .contains("contentId=12345")
            .contains("firstImageYN=Y")
            .contains("overviewYN=Y");
    }

    @Test
    void fallsBackToSmallImageWhenOriginalImageIsMissing() {
        emptyDetailCommon();
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
        emptyDetailCommon();
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

    @Test
    void findsSpotTourInfoFromDetailCommonAndIntro() {
        server.createContext("/detailCommon2", exchange -> {
            byte[] body = """
                {
                  "response": {
                    "body": {
                      "items": {
                        "item": {
                          "overview": "<b>평창의 예술 공간</b><br>산책하듯 둘러보기 좋은 곳입니다."
                        }
                      }
                    }
                  }
                }
                """.getBytes(StandardCharsets.UTF_8);
            writeJson(exchange, body);
        });
        server.createContext("/detailIntro2", exchange -> {
            lastQuery = exchange.getRequestURI().getRawQuery();
            byte[] body = """
                {
                  "response": {
                    "body": {
                      "items": {
                        "item": {
                          "usetimeculture": "10:00 - 18:00",
                          "restdateculture": "월요일",
                          "usefee": "성인 5,000원",
                          "parkingculture": "가능",
                          "infocenterculture": "033-000-0000"
                        }
                      }
                    }
                  }
                }
                """.getBytes(StandardCharsets.UTF_8);
            writeJson(exchange, body);
        });

        assertThat(client("encoded%2Bkey").findSpotTourInfo("12345", 14))
            .hasValueSatisfying(info -> {
                assertThat(info.description()).isEqualTo("평창의 예술 공간 산책하듯 둘러보기 좋은 곳입니다.");
                assertThat(info.openingHours()).isEqualTo("10:00 - 18:00");
                assertThat(info.closedDays()).isEqualTo("월요일");
                assertThat(info.admissionFee()).isEqualTo("성인 5,000원");
                assertThat(info.parking()).isEqualTo("가능");
                assertThat(info.contactPhone()).isEqualTo("033-000-0000");
            });
        assertThat(lastQuery)
            .contains("contentId=12345")
            .contains("contentTypeId=14");
    }

    @Test
    void readsRestaurantOpeningHoursFromFoodIntro() {
        server.createContext("/detailCommon2", exchange -> {
            byte[] body = """
                {
                  "response": {
                    "body": {
                      "items": {
                        "item": {
                          "overview": "감자 음식을 맛볼 수 있는 식당입니다."
                        }
                      }
                    }
                  }
                }
                """.getBytes(StandardCharsets.UTF_8);
            writeJson(exchange, body);
        });
        server.createContext("/detailIntro2", exchange -> {
            byte[] body = """
                {
                  "response": {
                    "body": {
                      "items": {
                        "item": {
                          "opentimefood": "11:00 - 20:00",
                          "restdatefood": "화요일",
                          "parkingfood": "가능",
                          "infocenterfood": "033-111-2222"
                        }
                      }
                    }
                  }
                }
                """.getBytes(StandardCharsets.UTF_8);
            writeJson(exchange, body);
        });

        assertThat(client("encoded%2Bkey").findSpotTourInfo("12345", 39))
            .hasValueSatisfying(info -> {
                assertThat(info.openingHours()).isEqualTo("11:00 - 20:00");
                assertThat(info.closedDays()).isEqualTo("화요일");
                assertThat(info.parking()).isEqualTo("가능");
                assertThat(info.contactPhone()).isEqualTo("033-111-2222");
            });
    }

    private TourApiClient client(String serviceKey) {
        return new TourApiClient(
            RestClient.builder(),
            "http://localhost:%d".formatted(server.getAddress().getPort()),
            "/searchKeyword2",
            "/detailImage2",
            "/detailCommon2",
            "/detailIntro2",
            serviceKey,
            "ETC",
            "potato-mubwanna",
            "51",
            "감자"
        );
    }

    private void emptyDetailCommon() {
        server.createContext("/detailCommon2", exchange -> {
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
    }

    private void writeJson(com.sun.net.httpserver.HttpExchange exchange, byte[] body) throws IOException {
        exchange.getResponseHeaders().add("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, body.length);
        exchange.getResponseBody().write(body);
        exchange.close();
    }
}
