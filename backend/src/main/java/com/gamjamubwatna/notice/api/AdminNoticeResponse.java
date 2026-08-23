package com.gamjamubwatna.notice.api;

import com.gamjamubwatna.notice.domain.Notice;
import java.time.Instant;

public record AdminNoticeResponse(
    Long id,
    String title,
    String content,
    boolean published,
    Instant publishedAt,
    Instant createdAt,
    Instant updatedAt
) {

    public static AdminNoticeResponse from(Notice notice) {
        return new AdminNoticeResponse(
            notice.getId(),
            notice.getTitle(),
            notice.getContent(),
            notice.isPublished(),
            notice.getPublishedAt(),
            notice.getCreatedAt(),
            notice.getUpdatedAt()
        );
    }
}
