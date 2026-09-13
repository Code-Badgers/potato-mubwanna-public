package com.gamjamubwatna.spot.application;

public class SpotRouteEstimateExternalException extends RuntimeException {

    public SpotRouteEstimateExternalException(String message) {
        super(message);
    }

    public SpotRouteEstimateExternalException(String message, Throwable cause) {
        super(message, cause);
    }
}
