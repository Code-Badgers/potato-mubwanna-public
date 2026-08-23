package com.gamjamubwatna.notice.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminNoticeUpdateRequest(
    @NotBlank @Size(max = 160) String title,
    @NotBlank @Size(max = 2000) String content
) {
}
