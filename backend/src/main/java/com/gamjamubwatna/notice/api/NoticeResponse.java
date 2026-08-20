package com.gamjamubwatna.notice.api;

import com.gamjamubwatna.notice.domain.Notice;
import java.time.Instant;

public record NoticeResponse(
    Long id,
    String title,
    String content,
    Instant publishedAt
) {

    public static NoticeResponse from(Notice notice) {
        return new NoticeResponse(
            notice.getId(),
            notice.getTitle(),
            notice.getContent(),
            notice.getPublishedAt()
        );
    }
}
