package com.gamjamubwatna.mission.application;

public record StoredMissionPhoto(
    String uploadKey,
    String fileName,
    String contentType,
    long size
) {
}
