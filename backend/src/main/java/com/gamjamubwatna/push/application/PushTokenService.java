package com.gamjamubwatna.push.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.push.domain.PushPlatform;
import com.gamjamubwatna.push.domain.UserPushToken;
import com.gamjamubwatna.push.domain.UserPushTokenRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PushTokenService {

    private static final int MAX_TOKEN_LENGTH = 512;

    private final UserRepository userRepository;
    private final UserPushTokenRepository pushTokenRepository;
    private final Duration staleTokenAge;
    private final Clock clock;

    @Autowired
    public PushTokenService(
        UserRepository userRepository,
        UserPushTokenRepository pushTokenRepository,
        @Value("${push.token.stale-days}") long staleDays
    ) {
        this(
            userRepository,
            pushTokenRepository,
            staleDays,
            Clock.systemUTC()
        );
    }

    PushTokenService(
        UserRepository userRepository,
        UserPushTokenRepository pushTokenRepository,
        long staleDays,
        Clock clock
    ) {
        if (staleDays < 1) {
            throw new IllegalArgumentException("Push token stale days must be positive");
        }
        this.userRepository = userRepository;
        this.pushTokenRepository = pushTokenRepository;
        this.staleTokenAge = Duration.ofDays(staleDays);
        this.clock = clock;
    }

    @Transactional
    public PushTokenRegistration register(
        Long userId,
        String token,
        PushPlatform platform,
        String previousToken
    ) {
        validateToken(token);
        if (platform == null) {
            throw new PushTokenValidationException("푸시 플랫폼을 확인해주세요.");
        }
        if (previousToken != null) {
            validateToken(previousToken);
        }

        User user = user(userId);
        Instant now = Instant.now(clock);
        pushTokenRepository.deleteByUpdatedAtBefore(now.minus(staleTokenAge));
        if (previousToken != null && !previousToken.equals(token)) {
            pushTokenRepository.deleteByUserIdAndToken(userId, previousToken);
        }

        UserPushToken registeredToken = pushTokenRepository.findByToken(token)
            .map(existing -> {
                existing.register(user, platform, now);
                return existing;
            })
            .orElseGet(() -> new UserPushToken(user, token, platform, now));
        UserPushToken savedToken = pushTokenRepository.save(registeredToken);
        return new PushTokenRegistration(savedToken.getPlatform(), savedToken.getUpdatedAt());
    }

    @Transactional
    public void delete(Long userId, String token) {
        validateToken(token);
        user(userId);
        pushTokenRepository.deleteByUserIdAndToken(userId, token);
    }

    private User user(Long userId) {
        return userRepository.findById(userId)
            .orElseThrow(() -> new PushTokenAuthenticationException("사용자를 찾을 수 없습니다."));
    }

    private void validateToken(String token) {
        if (token == null || token.isBlank() || token.length() > MAX_TOKEN_LENGTH) {
            throw new PushTokenValidationException("푸시 토큰을 확인해주세요.");
        }
        if (!token.equals(token.trim()) || token.chars().anyMatch(Character::isWhitespace)) {
            throw new PushTokenValidationException("푸시 토큰을 확인해주세요.");
        }
    }
}
