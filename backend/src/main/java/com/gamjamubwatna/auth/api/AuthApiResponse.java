package com.gamjamubwatna.auth.api;

public record AuthApiResponse<T>(
    boolean success,
    String message,
    T data
) {

    public static <T> AuthApiResponse<T> success(T data) {
        return new AuthApiResponse<>(true, "요청이 성공했습니다.", data);
    }

    public static <T> AuthApiResponse<T> failure(String message) {
        return new AuthApiResponse<>(false, message, null);
    }
}
