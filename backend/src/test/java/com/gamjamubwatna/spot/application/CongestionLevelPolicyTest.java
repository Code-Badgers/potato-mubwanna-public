package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamjamubwatna.spot.domain.CongestionLevel;
import org.junit.jupiter.api.Test;

class CongestionLevelPolicyTest {

    private final CongestionLevelPolicy policy = new CongestionLevelPolicy();

    @Test
    void resolvesLowWhenPredictedVisitorsAreBelowBaseline() {
        assertThat(policy.resolve(790, 1000)).isEqualTo(CongestionLevel.LOW);
    }

    @Test
    void resolvesNormalWhenPredictedVisitorsAreNearBaseline() {
        assertThat(policy.resolve(1000, 1000)).isEqualTo(CongestionLevel.NORMAL);
        assertThat(policy.resolve(1200, 1000)).isEqualTo(CongestionLevel.NORMAL);
    }

    @Test
    void resolvesHighWhenPredictedVisitorsAreAboveBaseline() {
        assertThat(policy.resolve(1201, 1000)).isEqualTo(CongestionLevel.HIGH);
    }

    @Test
    void fallsBackToNormalForInvalidVisitorValues() {
        assertThat(policy.resolve(null, 1000)).isEqualTo(CongestionLevel.NORMAL);
        assertThat(policy.resolve(-1, 1000)).isEqualTo(CongestionLevel.NORMAL);
        assertThat(policy.resolve(1000, 0)).isEqualTo(CongestionLevel.NORMAL);
    }
}
