package com.gamjamubwatna.auth.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

class KakaoApiAuthorizationCodeClientTest {

    private HttpServer server;

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void exchangesAuthorizationCodeWithFormRequest() throws IOException {
        AtomicReference<String> contentType = new AtomicReference<>();
        AtomicReference<String> requestBody = new AtomicReference<>();
        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/oauth/token", exchange -> {
            contentType.set(exchange.getRequestHeaders().getFirst("Content-Type"));
            requestBody.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            byte[] response = "{\"access_token\":\"kakao-access-token\"}"
                .getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            exchange.getResponseBody().write(response);
            exchange.close();
        });
        server.start();

        String token = new KakaoApiAuthorizationCodeClient(
            RestClient.builder(),
            "http://localhost:%d/oauth/token".formatted(server.getAddress().getPort()),
            "rest-api-key"
        ).exchange("authorization-code", "http://localhost:54631/");

        assertThat(token).isEqualTo("kakao-access-token");
        assertThat(contentType.get()).startsWith("application/x-www-form-urlencoded");
        assertThat(requestBody.get())
            .contains("grant_type=authorization_code")
            .contains("client_id=rest-api-key")
            .contains("redirect_uri=http%3A%2F%2Flocalhost%3A54631%2F")
            .contains("code=authorization-code");
    }
}
