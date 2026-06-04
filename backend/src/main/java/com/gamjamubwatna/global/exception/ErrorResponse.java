package com.gamjamubwatna.global.exception;

public record ErrorResponse(
        boolean success,
        String message,
        String code
) {
    public static ErrorResponse of(String message, String code) {
        return new ErrorResponse(false, message, code);
    }
}

