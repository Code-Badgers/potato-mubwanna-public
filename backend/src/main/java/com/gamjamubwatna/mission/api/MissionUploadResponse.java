package com.gamjamubwatna.mission.api;

import java.time.Instant;

public record MissionUploadResponse(
    String uploadKey,
    String fileName,
    String contentType,
    long size,
    Instant expiresAt
) {
}
