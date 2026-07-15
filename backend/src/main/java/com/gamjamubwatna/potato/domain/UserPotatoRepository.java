package com.gamjamubwatna.potato.domain;

import java.util.List;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserPotatoRepository extends JpaRepository<UserPotato, Long> {

    @EntityGraph(attributePaths = "potato")
    List<UserPotato> findByUserId(Long userId);
}
