package com.gamjamubwatna.spot.infrastructure;

public class RelatedTourismApiException extends RuntimeException {

    public RelatedTourismApiException(String message) {
        super(message);
    }

    public RelatedTourismApiException(String message, Throwable cause) {
        super(message, cause);
    }
}
