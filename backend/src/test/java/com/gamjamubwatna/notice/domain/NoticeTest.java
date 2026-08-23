package com.gamjamubwatna.notice.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Instant;
import org.junit.jupiter.api.Test;

class NoticeTest {

    @Test
    void publishingDraftUpdatesPublicationAndModificationTimestampsOnce() {
        Instant createdAt = Instant.parse("2026-08-20T00:00:00Z");
        Instant publishedAt = Instant.parse("2026-08-21T00:00:00Z");
        Instant repeatedAt = Instant.parse("2026-08-22T00:00:00Z");
        Notice notice = new Notice("제목", "내용", false, createdAt, createdAt);

        notice.changePublication(true, publishedAt);
        notice.changePublication(true, repeatedAt);

        assertThat(notice.isPublished()).isTrue();
        assertThat(notice.getPublishedAt()).isEqualTo(publishedAt);
        assertThat(notice.getUpdatedAt()).isEqualTo(publishedAt);
    }

    @Test
    void rejectsInvalidTitleAndContent() {
        Instant now = Instant.parse("2026-08-20T00:00:00Z");

        assertThatThrownBy(() -> new Notice(" ", "내용", false, now, now))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new Notice("제목", " ", false, now, now))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
