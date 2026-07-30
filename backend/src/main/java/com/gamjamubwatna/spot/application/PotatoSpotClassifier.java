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
        if (isLowRelevancePotatoSoup(text)) {
            return Optional.empty();
        }
        if (!trustKeywordSearch && !containsPotatoKeyword(text)) {
            return Optional.empty();
        }
        if (trustKeywordSearch && isGenericTourContent(contentTypeId) && !containsPotatoKeyword(text)) {
            return Optional.empty();
        }

        SpotCategory category = classifyCategory(contentTypeId, text);

        return Optional.of(new PotatoSpotClassification(category, extractTags(text)));
    }

    private boolean isLowRelevancePotatoSoup(String text) {
        return containsAny(text, "감자탕")
            && !containsAny(
                text,
                "옹심이",
                "감자전",
                "감자떡",
                "감자빵",
                "알감자",
                "회오리감자",
                "고랭지",
                "로컬푸드",
                "감자꽃",
                "감자밭",
                "감자 맥주",
                "감자맥주"
            );
    }

    private boolean isGenericTourContent(Integer contentTypeId) {
        return contentTypeId != null
            && (contentTypeId == 12 || contentTypeId == 14 || contentTypeId == 15 || contentTypeId == 25);
    }

    private SpotCategory classifyCategory(Integer contentTypeId, String text) {
        if (containsAny(text, "맥주", "브루어리", "양조", "펍", "술", "바", "페어링")) {
            return SpotCategory.POTATO_BREWERY;
        }
        if (containsAny(text, "체험", "만들기", "클래스", "공방", "농장", "팜")) {
            return SpotCategory.POTATO_EXPERIENCE;
        }
        if (containsAny(text, "시장", "전통시장", "직판장", "로컬푸드", "농협", "마트", "상회")) {
            return SpotCategory.POTATO_MARKET;
        }
        if (containsAny(text, "카페", "커피", "디저트", "젤라또", "베이커리", "제과", "빵집")) {
            return SpotCategory.POTATO_CAFE;
        }
        if (containsAny(text, "빵", "간식", "떡", "과자", "알감자", "회오리감자", "휴게소")) {
            return SpotCategory.POTATO_SNACK;
        }
        if (containsAny(text, "기념품", "굿즈", "특산품", "판매장")) {
            return SpotCategory.POTATO_SHOP;
        }
        if (containsAny(text, "축제", "박물관", "연구소", "감자밭", "감자꽃", "고랭지")) {
            return SpotCategory.POTATO_TOUR;
        }

        return switch (contentTypeId) {
            case 38 -> SpotCategory.POTATO_SHOP;
            case 39 -> SpotCategory.POTATO_RESTAURANT;
            case 12, 14, 15, 25 -> SpotCategory.POTATO_TOUR;
            default -> SpotCategory.POTATO_EXPERIENCE;
        };
    }

    private boolean containsPotatoKeyword(String text) {
        return containsAny(
            text,
            "감자",
            "옹심이",
            "감자전",
            "감자떡",
            "감자빵",
            "알감자",
            "회오리감자",
            "고랭지",
            "로컬푸드",
            "감자꽃",
            "감자밭"
        );
    }

    private String extractTags(String text) {
        if (containsAny(text, "페어링", "바")) {
            return "감자,바&페어링";
        }
        if (containsAny(text, "맥주", "브루어리", "양조", "펍")) {
            return "감자,감자맥주";
        }
        if (containsAny(text, "체험", "만들기", "클래스", "공방", "농장", "팜")) {
            return "감자,체험";
        }
        if (containsAny(text, "시장", "직판장", "로컬푸드", "농협", "마트")) {
            return "감자,직판장";
        }
        if (containsAny(text, "축제", "박물관", "연구소", "감자밭", "감자꽃", "고랭지")) {
            return "감자,관광";
        }
        if (containsAny(text, "카페", "디저트", "젤라또")) {
            return "감자,디저트";
        }
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
        if (containsAny(text, "기념품", "굿즈", "특산품", "판매장")) {
            return "감자,기념품";
        }
        if (containsAny(text, "알감자", "회오리감자", "휴게소")) {
            return "감자,간식";
        }
        return "감자";
    }

    private boolean containsAny(String text, String... keywords) {
        String normalizedText = removeWhitespace(text);
        for (String keyword : keywords) {
            if (text.contains(keyword) || normalizedText.contains(removeWhitespace(keyword))) {
                return true;
            }
        }
        return false;
    }

    private String removeWhitespace(String value) {
        return value.replaceAll("\\s+", "");
    }

    private String nullToBlank(String value) {
        return value == null ? "" : value;
    }
}
