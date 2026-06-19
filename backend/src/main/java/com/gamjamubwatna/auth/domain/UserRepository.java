package com.gamjamubwatna.auth.domain;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByProviderAndProviderUserId(
        AuthProvider provider,
        String providerUserId
    );
}
