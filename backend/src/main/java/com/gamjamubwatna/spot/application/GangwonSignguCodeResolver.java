package com.gamjamubwatna.spot.application;

import java.util.Map;
import java.util.Optional;
import org.springframework.stereotype.Component;

@Component
public class GangwonSignguCodeResolver {

    private static final Map<String, String> SIGNGU_CODES = Map.ofEntries(
        Map.entry("춘천시", "51110"),
        Map.entry("원주시", "51130"),
        Map.entry("강릉시", "51150"),
        Map.entry("동해시", "51170"),
        Map.entry("태백시", "51190"),
        Map.entry("속초시", "51210"),
        Map.entry("삼척시", "51230"),
        Map.entry("홍천군", "51720"),
        Map.entry("횡성군", "51730"),
        Map.entry("영월군", "51750"),
        Map.entry("평창군", "51760"),
        Map.entry("정선군", "51770"),
        Map.entry("철원군", "51780"),
        Map.entry("화천군", "51790"),
        Map.entry("양구군", "51800"),
        Map.entry("인제군", "51810"),
        Map.entry("고성군", "51820"),
        Map.entry("양양군", "51830")
    );

    public Optional<String> resolve(String cityName) {
        if (cityName == null || cityName.isBlank()) {
            return Optional.empty();
        }
        return Optional.ofNullable(SIGNGU_CODES.get(cityName.trim()));
    }
}
