package com.gamjamubwatna.mission.application;

public class MissionAlreadyCompletedException extends RuntimeException {

    public MissionAlreadyCompletedException(String message) {
        super(message);
    }
}
