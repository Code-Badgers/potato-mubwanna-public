package com.gamjamubwatna.spot.infrastructure;

public class TourismCongestionApiException extends RuntimeException {

    public TourismCongestionApiException(String message) {
        super(message);
    }

    public TourismCongestionApiException(String message, Throwable cause) {
        super(message, cause);
    }
}
