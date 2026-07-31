package com.gamjamubwatna.push.domain;

import com.gamjamubwatna.auth.domain.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;

@Entity
@Table(
    name = "user_push_tokens",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_user_push_tokens_token",
            columnNames = "token"
        )
    },
    indexes = {
        @Index(name = "idx_user_push_tokens_user_id", columnList = "user_id"),
        @Index(name = "idx_user_push_tokens_updated_at", columnList = "updated_at")
    }
)
public class UserPushToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_push_token_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "token", nullable = false, length = 512)
    private String token;

    @Enumerated(EnumType.STRING)
    @Column(name = "platform", nullable = false, length = 20)
    private PushPlatform platform;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected UserPushToken() {
    }

    public UserPushToken(
        User user,
        String token,
        PushPlatform platform,
        Instant now
    ) {
        this.user = user;
        this.token = token;
        this.platform = platform;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void register(User user, PushPlatform platform, Instant now) {
        this.user = user;
        this.platform = platform;
        this.updatedAt = now;
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public String getToken() {
        return token;
    }

    public PushPlatform getPlatform() {
        return platform;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
