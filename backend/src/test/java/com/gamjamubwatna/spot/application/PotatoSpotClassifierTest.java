package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamjamubwatna.spot.domain.SpotCategory;
import org.junit.jupiter.api.Test;

class PotatoSpotClassifierTest {

    private final PotatoSpotClassifier classifier = new PotatoSpotClassifier();

    @Test
    void classifiesPotatoRestaurantFromFoodContentType() {
        PotatoSpotClassification classification = classifier
            .classify(39, "강릉 감자옹심이", "강원특별자치도 강릉시")
            .orElseThrow();

        assertThat(classification.category()).isEqualTo(SpotCategory.POTATO_RESTAURANT);
        assertThat(classification.tags()).isEqualTo("감자,옹심이");
    }

    @Test
    void classifiesPotatoShopFromShoppingContentType() {
        PotatoSpotClassification classification = classifier
            .classify(38, "감자빵 기념품숍", "강원특별자치도 춘천시")
            .orElseThrow();

        assertThat(classification.category()).isEqualTo(SpotCategory.POTATO_SHOP);
        assertThat(classification.tags()).isEqualTo("감자,감자빵");
    }

    @Test
    void ignoresUnrelatedTourApiItem() {
        assertThat(classifier.classify(12, "바다 전망대", "강원특별자치도 고성군"))
            .isEmpty();
    }

    @Test
    void trustsTourApiKeywordSearchResultForInitialImport() {
        PotatoSpotClassification classification = classifier
            .classifyKeywordSearchResult(12, "대관령 여행지", "강원특별자치도 평창군")
            .orElseThrow();

        assertThat(classification.category()).isEqualTo(SpotCategory.POTATO_TOUR);
        assertThat(classification.tags()).isEqualTo("감자");
    }
}
