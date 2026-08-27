package com.gamjamubwatna.spot.infrastructure;

public class GooglePlacesApiException extends RuntimeException {

    private final int statusCode;
    private final String reason;

    public GooglePlacesApiException(String operation, int statusCode, String reason, Throwable cause) {
        super("Google Places %s failed".formatted(operation), cause);
        this.statusCode = statusCode;
        this.reason = reason;
    }

    public int getStatusCode() {
        return statusCode;
    }

    public String getReason() {
        return reason;
    }
}
