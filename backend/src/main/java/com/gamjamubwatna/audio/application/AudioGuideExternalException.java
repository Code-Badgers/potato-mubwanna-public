package com.gamjamubwatna.audio.application;

public class AudioGuideExternalException extends RuntimeException {

    public AudioGuideExternalException(String message) {
        super(message);
    }

    public AudioGuideExternalException(String message, Throwable cause) {
        super(message, cause);
    }
}
