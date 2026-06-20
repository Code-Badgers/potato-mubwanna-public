package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.SpotCategory;
import java.util.Optional;
import org.springframework.stereotype.Component;

@Component
public class PotatoSpotClassifier {

    public Optional<PotatoSpotClassification> classify(
        Integer contentTypeId,
        String title,
        String address
    ) {
        return classify(contentTypeId, title, address, false);
    }

    public Optional<PotatoSpotClassification> classifyKeywordSearchResult(
        Integer contentTypeId,
        String title,
        String address
    ) {
        return classify(contentTypeId, title, address, true);
    }

    private Optional<PotatoSpotClassification> classify(
        Integer contentTypeId,
        String title,
        String address,
        boolean trustKeywordSearch
    ) {
        String text = "%s %s".formatted(nullToBlank(title), nullToBlank(address));
        if (!trustKeywordSearch && !containsPotatoKeyword(text)) {
            return Optional.empty();
        }

        SpotCategory category = switch (contentTypeId) {
            case 38 -> SpotCategory.POTATO_SHOP;
            case 39 -> classifyRestaurantLike(text);
            case 12 -> SpotCategory.POTATO_TOUR;
            default -> SpotCategory.POTATO_EXPERIENCE;
        };

        return Optional.of(new PotatoSpotClassification(category, extractTags(text)));
    }

    private SpotCategory classifyRestaurantLike(String text) {
        if (containsAny(text, "카페", "커피", "디저트")) {
            return SpotCategory.POTATO_CAFE;
        }
        if (containsAny(text, "빵", "간식", "떡", "과자")) {
            return SpotCategory.POTATO_SNACK;
        }
        return SpotCategory.POTATO_RESTAURANT;
    }

    private boolean containsPotatoKeyword(String text) {
        return containsAny(text, "감자", "옹심이", "감자전", "감자떡", "감자빵", "고랭지");
    }

    private String extractTags(String text) {
        if (containsAny(text, "옹심이")) {
            return "감자,옹심이";
        }
        if (containsAny(text, "감자전")) {
            return "감자,감자전";
        }
        if (containsAny(text, "감자빵", "빵")) {
            return "감자,감자빵";
        }
        if (containsAny(text, "감자떡", "떡")) {
            return "감자,감자떡";
        }
        return "감자";
    }

    private boolean containsAny(String text, String... keywords) {
        for (String keyword : keywords) {
            if (text.contains(keyword)) {
                return true;
            }
        }
        return false;
    }

    private String nullToBlank(String value) {
        return value == null ? "" : value;
    }
}
