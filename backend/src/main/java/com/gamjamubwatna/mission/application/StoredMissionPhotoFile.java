package com.gamjamubwatna.mission.application;

public record StoredMissionPhotoFile(
    String uploadKey,
    byte[] bytes
) {
}
