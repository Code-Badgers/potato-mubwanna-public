package com.gamjamubwatna.spot.api;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamjamubwatna.spot.domain.SpotMenuItem;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class SpotMenuItemResponseTest {
    @Test
    void preservesSourceAndVerificationDateWithoutInventingPrice() {
        var date = LocalDate.of(2026, 9, 10);
        var item = new SpotMenuItem(1L, "감자옹심이", null, null, 0,
            "https://example.com/menu", date);
        var response = SpotMenuItemResponse.from(item);
        assertThat(response.sourceUrl()).isEqualTo("https://example.com/menu");
        assertThat(response.verifiedOn()).isEqualTo(date);
        assertThat(response.priceWon()).isNull();
        assertThat(response.priceNote()).isNull();
    }
}
