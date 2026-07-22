package com.gamjamubwatna.visit.application;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class VisitDistancePolicyTest {

    private final VisitDistancePolicy visitDistancePolicy = new VisitDistancePolicy();

    @Test
    void calculatesZeroDistanceForSameCoordinates() {
        BigDecimal distanceMeters = visitDistancePolicy.distanceMeters(
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000")
        );

        assertThat(distanceMeters).isEqualByComparingTo("0.00");
    }

    @Test
    void checksVerificationRadiusInclusively() {
        assertThat(visitDistancePolicy.isWithinRadius(new BigDecimal("100.00"), 100)).isTrue();
        assertThat(visitDistancePolicy.isWithinRadius(new BigDecimal("100.01"), 100)).isFalse();
    }
}
