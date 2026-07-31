package com.gamjamubwatna.potato.domain;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserPotatoRepository extends JpaRepository<UserPotato, Long> {

    @EntityGraph(attributePaths = "potato")
    List<UserPotato> findByUserId(Long userId);

    Optional<UserPotato> findByUserIdAndPotatoId(Long userId, Long potatoId);

    long countByUserId(Long userId);
}
