package com.gamjamubwatna.spot.infrastructure;

import java.time.Duration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

final class SpotEnrichmentHttp {

    private SpotEnrichmentHttp() {
    }

    static RestClient build(RestClient.Builder builder) {
        // 선택 정보 제공자의 장애가 장소 상세와 방문 인증 진입까지 막지 않도록 제한한다.
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(1));
        factory.setReadTimeout(Duration.ofSeconds(2));
        return builder.clone().requestFactory(factory).build();
    }
}
