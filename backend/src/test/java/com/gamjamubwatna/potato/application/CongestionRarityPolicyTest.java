package com.gamjamubwatna.potato.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamjamubwatna.spot.domain.CongestionLevel;
import org.junit.jupiter.api.Test;

class CongestionRarityPolicyTest {

    private final CongestionRarityPolicy policy = new CongestionRarityPolicy();

    @Test
    void increasesRarePotatoChanceForLowCongestion() {
        assertThat(policy.rarePotatoMultiplier(CongestionLevel.LOW)).isEqualTo(1.5);
    }

    @Test
    void keepsBaseChanceForNormalCongestion() {
        assertThat(policy.rarePotatoMultiplier(CongestionLevel.NORMAL)).isEqualTo(1.0);
    }

    @Test
    void decreasesRarePotatoChanceForHighCongestion() {
        assertThat(policy.rarePotatoMultiplier(CongestionLevel.HIGH)).isEqualTo(0.7);
    }
}
