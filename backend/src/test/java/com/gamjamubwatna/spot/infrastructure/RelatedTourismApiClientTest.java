package com.gamjamubwatna.spot.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

class RelatedTourismApiClientTest {

    private HttpServer server;

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void searchesRelatedTourismSpotsWithOfficialParameters() throws Exception {
        AtomicReference<String> rawQuery = new AtomicReference<>();
        startServer("""
            {
              "response": {
                "header": {"resultCode": "0000", "resultMsg": "OK"},
                "body": {
                  "items": {
                    "item": [
                      {
                        "baseYm": "202504",
                        "tAtsCd": "source-code",
                        "tAtsNm": "뮤지엄산",
                        "areaCd": "51",
                        "areaNm": "강원특별자치도",
                        "signguCd": "51130",
                        "signguNm": "원주시",
                        "rlteTatsCd": "related-code",
                        "rlteTatsNm": "원주소금산출렁다리",
                        "rlteRegnCd": "51",
                        "rlteRegnNm": "강원특별자치도",
                        "rlteSignguCd": "51130",
                        "rlteSignguNm": "원주시",
                        "rlteCtgryLclsNm": "관광지",
                        "rlteCtgryMclsNm": "기타관광",
                        "rlteCtgrySclsNm": "기타관광",
                        "rlteRank": "2"
                      }
                    ]
                  }
                }
              }
            }
            """, rawQuery);

        var spots = client("encoded%2Fservice%2Bkey").searchRelatedSpots("뮤지엄산", "51130");

        assertThat(spots).singleElement().satisfies(spot -> {
            assertThat(spot.tAtsNm()).isEqualTo("뮤지엄산");
            assertThat(spot.rlteTatsNm()).isEqualTo("원주소금산출렁다리");
            assertThat(spot.rlteRank()).isEqualTo("2");
        });
        assertThat(rawQuery.get())
            .contains("serviceKey=encoded%2Fservice%2Bkey")
            .contains("pageNo=1")
            .contains("numOfRows=50")
            .contains("baseYm=202504")
            .contains("areaCd=51")
            .contains("signguCd=51130")
            .contains("keyword=%EB%AE%A4%EC%A7%80%EC%97%84%EC%82%B0")
            .contains("_type=json")
            .doesNotContain("%252F");
    }

    @Test
    void acceptsSingleItemObjectFromGateway() throws Exception {
        startServer("""
            {
              "response": {
                "header": {"resultCode": "0000", "resultMsg": "OK"},
                "body": {
                  "items": {
                    "item": {
                      "tAtsNm": "뮤지엄산",
                      "signguCd": "51130",
                      "rlteTatsNm": "원주소금산출렁다리",
                      "rlteRank": "1"
                    }
                  }
                }
              }
            }
            """, new AtomicReference<>());

        assertThat(client("service-key").searchRelatedSpots("뮤지엄산", "51130"))
            .hasSize(1);
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

        client("decoded+service/key==").searchRelatedSpots("뮤지엄산", "51130");

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

        assertThatThrownBy(() -> client("service-key").searchRelatedSpots("뮤지엄산", "51130"))
            .isInstanceOf(RelatedTourismApiException.class)
            .hasMessageContaining("SERVICE_KEY_IS_NOT_REGISTERED_ERROR");
    }

    @Test
    void rejectsMissingServiceKeyBeforeCallingApi() {
        RelatedTourismApiClient client = new RelatedTourismApiClient(
            RestClient.builder(),
            "https://apis.data.go.kr/B551011/TarRlteTarService1",
            "/searchKeyword1",
            "",
            "ETC",
            "potato-mubwanna",
            "202504",
            "51"
        );

        assertThatThrownBy(() -> client.searchRelatedSpots("뮤지엄산", "51130"))
            .isInstanceOf(RelatedTourismApiException.class)
            .hasMessageContaining("RELATED_TOURISM_API_SERVICE_KEY");
    }

    private RelatedTourismApiClient client(String serviceKey) {
        return new RelatedTourismApiClient(
            RestClient.builder(),
            "http://localhost:%d".formatted(server.getAddress().getPort()),
            "/searchKeyword1",
            serviceKey,
            "ETC",
            "potato-mubwanna",
            "202504",
            "51"
        );
    }

    private void startServer(String body, AtomicReference<String> rawQuery) throws IOException {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/searchKeyword1", exchange -> {
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
