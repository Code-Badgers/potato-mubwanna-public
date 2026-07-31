package com.gamjamubwatna.push.domain;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

public interface UserPushTokenRepository extends JpaRepository<UserPushToken, Long> {

    Optional<UserPushToken> findByToken(String token);

    @EntityGraph(attributePaths = "user")
    List<UserPushToken> findAllByUserId(Long userId);

    @Transactional
    long deleteByUserIdAndToken(Long userId, String token);

    @Transactional
    long deleteByUpdatedAtBefore(Instant cutoff);

    @Transactional
    long deleteByTokenIn(Collection<String> tokens);
}
