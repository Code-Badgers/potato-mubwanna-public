package com.gamjamubwatna.visit.application;

import java.math.BigDecimal;
import java.math.RoundingMode;
import org.springframework.stereotype.Component;

@Component
public class VisitDistancePolicy {

    private static final double EARTH_RADIUS_METERS = 6_371_000.0;

    public BigDecimal distanceMeters(
        BigDecimal spotLatitude,
        BigDecimal spotLongitude,
        BigDecimal userLatitude,
        BigDecimal userLongitude
    ) {
        double spotLat = Math.toRadians(spotLatitude.doubleValue());
        double userLat = Math.toRadians(userLatitude.doubleValue());
        double deltaLat = Math.toRadians(userLatitude.subtract(spotLatitude).doubleValue());
        double deltaLng = Math.toRadians(userLongitude.subtract(spotLongitude).doubleValue());

        double a = Math.sin(deltaLat / 2.0) * Math.sin(deltaLat / 2.0)
            + Math.cos(spotLat) * Math.cos(userLat)
            * Math.sin(deltaLng / 2.0) * Math.sin(deltaLng / 2.0);
        double c = 2.0 * Math.atan2(Math.sqrt(a), Math.sqrt(1.0 - a));
        return BigDecimal.valueOf(EARTH_RADIUS_METERS * c)
            .setScale(2, RoundingMode.HALF_UP);
    }

    public boolean isWithinRadius(BigDecimal distanceMeters, Integer verificationRadiusMeter) {
        if (distanceMeters == null || verificationRadiusMeter == null) {
            return false;
        }
        return distanceMeters.compareTo(BigDecimal.valueOf(verificationRadiusMeter)) <= 0;
    }
}
