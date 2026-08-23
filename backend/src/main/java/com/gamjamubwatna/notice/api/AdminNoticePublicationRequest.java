package com.gamjamubwatna.notice.api;

import jakarta.validation.constraints.NotNull;

public record AdminNoticePublicationRequest(
    @NotNull Boolean published
) {
}
