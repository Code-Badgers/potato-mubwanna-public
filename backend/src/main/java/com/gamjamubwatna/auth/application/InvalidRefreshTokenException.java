package com.gamjamubwatna.auth.application;

public class InvalidRefreshTokenException extends RuntimeException {

    public InvalidRefreshTokenException() {
        super("로그인 세션이 만료되었습니다. 다시 로그인해주세요.");
    }
}
