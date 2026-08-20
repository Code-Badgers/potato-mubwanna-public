package com.gamjamubwatna.notice.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "notices")
public class Notice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "notice_id")
    private Long id;

    @Column(name = "title", nullable = false, length = 160)
    private String title;

    @Column(name = "content", nullable = false, length = 2000)
    private String content;

    @Column(name = "published", nullable = false)
    private Boolean published;

    @Column(name = "published_at", nullable = false)
    private Instant publishedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Notice() {
    }

    public Notice(
        String title,
        String content,
        boolean published,
        Instant publishedAt,
        Instant now
    ) {
        this.title = title;
        this.content = content;
        this.published = published;
        this.publishedAt = publishedAt;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public Long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getContent() {
        return content;
    }

    public boolean isPublished() {
        return published;
    }

    public Instant getPublishedAt() {
        return publishedAt;
    }
}
